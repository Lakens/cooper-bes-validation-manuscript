#### R script associated with manuscript: ####
# "Fine-scale spatial distribution of biodiversity citizen science in a natural area depends on area accessibility and differs from other recreational area use"
# Submitted for publication April 2022

## Packages ####

  library(rgdal)
  library(sf)
  library(tmap)
  library(tidyverse)
  library(raster)
  library(plyr)
  library(lme4)
  library(pscl)
  library(countreg)
  library(DTK)
  library(lme4)
  library(MASS)
  library(pscl)
  library(patchwork)
  library(ggnewscale)
  library(reshape2)
  library(performance)
  library(spdep)
  library(elevatr)
  library(stars)
  library(rJava)
  library(glmulti)
  library(metafor)

## Set-up: data input ####

  ## ~~ Environmental data ~~ ##
  
    # Read in Bymarka outline
    bymarka<- st_read("bymarkaboundary.gpkg", )
    
    # Available environmental layers
    ogrListLayers("data_deliverable_caitlin.gpkg")
    
    # Read in the landscape features that we want, and the land cover data
    fotrute<- st_read("data_deliverable_caitlin.gpkg", "fotrute")
    lekeplasser<- st_read("data_deliverable_caitlin.gpkg", "lekeplasser")
    ski<- st_read("data_deliverable_caitlin.gpkg", "skiloype")
    anlegg<- st_read("data_deliverable_caitlin.gpkg", "naermiljoanlegg.geom")
    badeplass<- st_read("data_deliverable_caitlin.gpkg", "badeplass")
    ar5<- st_read("data_deliverable_caitlin.gpkg", "arealressurs_flate.geometri_spa")
    
    # Crop all layers to the Bymarka outline
    fotrute<- st_intersection(bymarka, fotrute)
    lekeplasser<- st_intersection(bymarka, lekeplasser)
    ski<- st_intersection(bymarka, ski)
    anlegg<- st_intersection(bymarka, anlegg)
    badeplass<- st_intersection(bymarka, badeplass)
    ar5<- st_intersection(bymarka, ar5)
  
  
  
  ## ~~ All biodiversity data ~~ ##
  
    ## Read in all GBIF, obtained 3 August 2021 ##
    
    gbif<- as.data.frame(read_delim("occurrence.csv"))
    
    gbif<- gbif[is.na(gbif$decimalLatitude) == FALSE,]
    
    gbif <- st_as_sf(gbif, coords = c("decimalLongitude", "decimalLatitude"), crs = '+proj=longlat +ellps  =WGS84   +d  atum=WGS84   +no_defs'  )

    # Transform to UTM 32N from WGS84
    gbif<- st_transform(gbif, st_crs(bymarka))
    
    # Trim to Bymarka boundary
    gbif<- st_intersection(bymarka, gbif)
    

  
  ## ~~ Strava data ~~ ##  
  
    # Read in activity data by segment
    strava<- read.csv("strava_edges_rollup_month_total_trondheim.csv")
    length(unique(strava$edge_id)) # 43244
    table(strava$activity_type)
    
    table(strava$date) # date indicates month (noted as last day of each month)
    
    # Summarize total count per segment
    strava2<- ddply(strava, "edge_id", summarize,
                        TotalActivity = sum(tathcnt, na.rm = TRUE))

    # Read in OSM segments
    shp<- st_read("trondheim_osm_clip.shp")
    colnames(strava2)[1]<- "id"
    
    # Join summarized Strava data to OSM segments
    shp<- left_join(shp, strava2, by = "id")
    
    table(is.na(shp$TotalActivity)) # as expected - same number of paired segments as there are strava segments
    
    # Transform to UTM 32N from WGS84
    shp<- st_transform(shp, st_crs(bymarka))
    
    # Trim to Bymarka boundary
    shp<- st_intersection(bymarka, shp)
    
    # Looks as expected
    ggplot() +
      geom_sf(data = bymarka) +
      geom_sf(data = shp[shp$TotalActivity > 0,], aes(color = TotalActivity), lwd = 1.5)
    
    # 6027 OSM segments in the study area have strava data (84%)
    table(is.na(shp$TotalActivity))
    
    # Create TRAILS object (simple outline of trail network, not split into segments)
    TRAILS<- st_combine(shp)




## Data cleaning: citizen science data ####

  ## ~~ Filter citizen science data ~~ ##
  
    table(gbif$datasetName) # ** IMPORTANT: en-dash in eBird does not format correctly - must copy/paste it EVERY TIME ** #
    
    CITSCI.OBS<- gbif[gbif$datasetName == "Norwegian Species Observation Service" |
                    gbif$datasetName == "iNaturalist Research-grade Observations" |
                    gbif$datasetName == "EOD - eBird Observation Dataset" |
                    gbif$datasetName == "Observation.org, Nature data from around the World" |
                    gbif$datasetName == "Pl@ntNet automatically identified occurrences" |
                    gbif$datasetName == "Pl@ntNet observations" |
                    gbif$datasetName == "Skandobs" |
                    gbif$datasetName == "naturgucker",]
    
    CITSCI.OBS$datasetName<- mapvalues(CITSCI.OBS$datasetName,
                                   from = c("Norwegian Species Observation Service",
                                            "iNaturalist Research-grade Observations",
                                            "EOD - eBird Observation Dataset",
                                            "Observation.org, Nature data from around the World",
                                            "Pl@ntNet automatically identified occurrences",
                                            "Pl@ntNet observations",
                                            "Skandobs",
                                            "naturgucker"),
                                   to = c("Artsobs","iNat","eBird",
                                          "Obs.org","Pl@ntNet","Pl@ntNet","Skandobs","naturgucker"))

  ## ~~ Add 'EVENT' identifiers ~~ ##
  
    CITSCI.OBS$identifier<- paste(CITSCI.OBS$eventDate,
                                  CITSCI.OBS$recordedBy,
                                  CITSCI.OBS$geom)
    

  ## ~ Filter by coordinate uncertainty ~ ##
  
    CITSCI.OBS<- CITSCI.OBS[CITSCI.OBS$coordinateUncertaintyInMeters < 151 |
                      is.na(CITSCI.OBS$coordinateUncertaintyInMeters) == TRUE,]
    
    table(CITSCI.OBS$occurrenceStatus) # All occurrences are presences, no absences
  

  ## ~ Filter by year ~ ##
  
    CITSCI.OBS<- CITSCI.OBS[CITSCI.OBS$year > 1999,]
  
  
  
  ## ~ Filter by taxonomic group ~ ##
  
    CITSCI.OBS$taxonomic<- rep("blank", times = 44245)
    
    CITSCI.OBS$kingdom<- as.factor(CITSCI.OBS$kingdom)
    CITSCI.OBS$phylum<- as.factor(CITSCI.OBS$phylum)
    CITSCI.OBS$order<- as.factor(CITSCI.OBS$order)
    
    CITSCI.OBS$taxonomic<- ifelse(CITSCI.OBS$kingdom == "Chromista" | CITSCI.OBS$kingdom == "Protozoa", "Bacteria",
                              ifelse(CITSCI.OBS$kingdom == "Fungi", "Fungi",
                                     ifelse(CITSCI.OBS$kingdom == "Plantae", "Plant",
                                            ifelse(CITSCI.OBS$phylum == "Annelida" |
                                                     CITSCI.OBS$phylum == "Arthropoda" |
                                                     CITSCI.OBS$phylum == "Mollusca", "Invertebrates",
                                                   ifelse(CITSCI.OBS$order == "Accipitriformes" |
                                                            CITSCI.OBS$order == "Anseriformes" |
                                                            CITSCI.OBS$order == "Apodiformes" |
                                                            CITSCI.OBS$order == "Charadriiformes" |
                                                            CITSCI.OBS$order == "Columbiformes" |
                                                            CITSCI.OBS$order == "Coraciiformes" |
                                                            CITSCI.OBS$order == "Cuculiformes" |
                                                            CITSCI.OBS$order == "Falconiformes" |
                                                            CITSCI.OBS$order == "Galliformes" |
                                                            CITSCI.OBS$order == "Gaviiformes" |
                                                            CITSCI.OBS$order == "Gruiformes" |
                                                            CITSCI.OBS$order == "Passeriformes" |
                                                            CITSCI.OBS$order == "Pelecaniformes" |
                                                            CITSCI.OBS$order == "Piciformes" |
                                                            CITSCI.OBS$order == "Podicipediformes" |
                                                            CITSCI.OBS$order == "Strigiformes" |
                                                            CITSCI.OBS$order == "Suliformes", "Birds",
                                                          ifelse(CITSCI.OBS$order == "Anura" |
                                                                   CITSCI.OBS$order == "Caudata" |
                                                                   CITSCI.OBS$order == "Squamata", "Herps",
                                                                 ifelse(CITSCI.OBS$order == "Artiodactyla" |
                                                                          CITSCI.OBS$order == "Carnivora" |
                                                                          CITSCI.OBS$order == "Chiroptera" |
                                                                          CITSCI.OBS$order == "Lagomorpha" |
                                                                          CITSCI.OBS$order == "Rodentia" |
                                                                          CITSCI.OBS$order == "Soricomorpha",
                                                                        "Mammals",
                                                                        ifelse(CITSCI.OBS$order == "Cypriniformes"   |
                                                                                 CITSCI.OBS$order ==     "Gasterosteiformes"|
                                                                                 CITSCI.OBS$order ==   "Salmoniformes",
                                                                               "Fish", "NA"))))))))
    
    table(CITSCI.OBS$taxonomic)
    table(is.na(CITSCI.OBS$taxonomic)) # no NAs
    
    CITSCI.OBS$taxonomic<- as.factor(CITSCI.OBS$taxonomic)
    
    # Remove fish & bacteria #
    
    CITSCI.OBS<- CITSCI.OBS[CITSCI.OBS$taxonomic != "Fish" & CITSCI.OBS$taxonomic != "Bacteria",]
    
    CITSCI.OBS.view<- CITSCI.OBS[CITSCI.OBS$taxonomic == "Invertebrates",]
    chk<- data.frame(table(CITSCI.OBS.view$order)) # Manually examine for aquatic obligate groups
    
    CITSCI.OBS<- CITSCI.OBS[CITSCI.OBS$order !=  "Rhynchobdellida",]
    
    
  ## ~ Distance to trail ~ ##
  
    dist<- as.vector(st_distance(CITSCI.OBS, TRAILS))
    CITSCI.OBS$distToTrail<- dist 


  ## ~ Land cover type ~ ##
  
  # Setup
  
    colnames(ar5)
    ar5_2<- ar5[,c(8,33)]
    
    ar5_2$artype<- as.factor(ar5_2$artype)
    levels(ar5_2$artype)<- c("developed", "transportation", "cultivated",
                             "surface_cultivated", "grazing", "forest", "open",
                             "mire", "freshwater", "sea")
    ar5_2$artype<- mapvalues(ar5_2$artype, from = "surface_cultivated", to = "cultivated")
    
    table(ar5_2$artype)
  
    # Add to CITSCI.OBS
    CITSCI.OBS<- st_join(CITSCI.OBS, ar5_2, st_intersects)
    CITSCI.OBS$artype<- mapvalues(CITSCI.OBS$artype, from = c("transportation","grazing"), to = c("developed","cultivated"))
    table(CITSCI.OBS$artype)
    
    
    
  # ~~ Clean up ~~ #
  
    ## Make trimmed down version of OBSERV, just to make it a bit easier to use
    
    # Formatting
    
    CITSCI.OBS$source<- CITSCI.OBS$datasetName
    
    CITSCI.OBS$source<- as.factor(CITSCI.OBS$source)
    CITSCI.OBS$identifier<- as.factor(CITSCI.OBS$identifier)
    CITSCI.OBS$kingdom<- as.factor(CITSCI.OBS$kingdom)
    CITSCI.OBS$phylum<- as.factor(CITSCI.OBS$phylum)
    CITSCI.OBS$class<- as.factor(CITSCI.OBS$class)
    CITSCI.OBS$family<- as.factor(CITSCI.OBS$family)
    CITSCI.OBS$genus<- as.factor(CITSCI.OBS$genus)
    CITSCI.OBS$species<- as.factor(CITSCI.OBS$species)
    CITSCI.OBS$month<- as.factor(CITSCI.OBS$month)
    CITSCI.OBS$order<- as.factor(CITSCI.OBS$order)
    

  
  ## ~~ Make EVENTS object ~~ ##
  
    ## Make combined table of ALL EVENTS
    
    CITSCI.OBS$recordedBy<- as.character(CITSCI.OBS$recordedBy)
    
    CITSCI.EVENTS<- unique(CITSCI.OBS[c("eventDate", "recordedBy", "geom")])
    CITSCI.EVENTS$recordedBy<- as.factor(CITSCI.EVENTS$recordedBy)
    CITSCI.EVENTS$identifier<- paste(CITSCI.EVENTS$eventDate, CITSCI.EVENTS$recordedBy, CITSCI.EVENTS$geom)

    CITSCI.OBS$recordedBy<- as.factor(CITSCI.OBS$recordedBy)
    
    # Add distance to events
    dist<- as.vector(st_distance(CITSCI.EVENTS, TRAILS))
    CITSCI.EVENTS$distToTrail<- dist
    
    ## Add number of observations per event
    numObsEvent<- data.frame(table(CITSCI.OBS$identifier))
    colnames(numObsEvent)<- c("identifier", "numObsEvent")
    CITSCI.EVENTS<- left_join(CITSCI.EVENTS, numObsEvent, by = "identifier")
    rm(numObsEvent)
    
    ## Land cover type
    CITSCI.EVENTS<- st_join(CITSCI.EVENTS, ar5_2, st_intersects)
    CITSCI.EVENTS$artype<- mapvalues(CITSCI.EVENTS$artype,
                                     from = c("transportation","grazing"), to = c("developed","cultivated"))
    table(CITSCI.EVENTS$artype)
    
  
  
  ## ~~ Check for potential double reporting? ~~ ##
  
    #CITSCI.OBS$species<- as.character(CITSCI.OBS$species)
    #d<- unique(CITSCI.OBS[c("species", "eventDate", "geom")])
    #table(d)
    #
    #CITSCI.OBS$specieslocation<- paste(CITSCI.OBS$species, CITSCI.OBS$eventDate, CITSCI.OBS$geom)
    #
    #tst<- ddply(CITSCI.OBS, c("specieslocation"), summarize,
    #            sources = length(unique(source)))
    #
    #table(tst$sources) # no instances of the same species/location/date being reported on two apps
  
  
  ## ~~ How many species? ~~ ##
  
    length(unique(CITSCI.OBS$species)) # 1524 species
    
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Mammals",]$species)) # 22 mammal spp
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Plant",]$species)) # 421 plant spp
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Birds",]$species)) # 174 bird spp
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Fungi",]$species)) # 541 fungi spp
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Herps",]$species)) # 7 herp spp
    length(unique(CITSCI.OBS[CITSCI.OBS$taxonomic == "Invertebrates",]$species)) # 364 mammal spp



## Data cleaning: professional biodiversity data ####

  ## ~~ Filter out citizen science data ~~ ##
  
    # ** again, IMPORTANT NOTE: copy in eBird name EVERY TIME ** #
    
    PROF.OBS<- gbif[gbif$datasetName != "Norwegian Species Observation Service" &
                  gbif$datasetName != "iNaturalist Research-grade Observations" &
                  gbif$datasetName != "EOD - eBird Observation Dataset" &
                  gbif$datasetName != "Observation.org, Nature data from around the World" &
                  gbif$datasetName != "Pl@ntNet automatically identified occurrences" &
                  gbif$datasetName != "Pl@ntNet observations" &
                  gbif$datasetName != "Skandobs" &
                  gbif$datasetName != "naturgucker" &
                  gbif$datasetName != "Norwegian Biodiversity Information Centre - Other datasets",]
    
    table(PROF.OBS$datasetName)
  
  
  ## ~ Filter by coordinate uncertainty ~ ##
  
    PROF.OBS<- PROF.OBS[PROF.OBS$coordinateUncertaintyInMeters < 151 |
                          is.na(PROF.OBS$coordinateUncertaintyInMeters) == TRUE,]
    
    table(PROF.OBS$occurrenceStatus) # All occurrences are presences, no absences
  
  
  ## ~ Filter by year ~ ##
  
    PROF.OBS<- PROF.OBS[PROF.OBS$year > 1999,]
  
  
  ## ~ Filter by taxonomic group ~ ##
  
    PROF.OBS$taxonomic<- rep("blank", times = 16484)
    
    PROF.OBS$kingdom<- as.factor(PROF.OBS$kingdom)
    PROF.OBS$phylum<- as.factor(PROF.OBS$phylum)
    PROF.OBS$class<- as.factor(PROF.OBS$class)
    PROF.OBS$family<- as.factor(PROF.OBS$family)
    PROF.OBS$genus<- as.factor(PROF.OBS$genus)
    PROF.OBS$species<- as.factor(PROF.OBS$species)
    PROF.OBS$month<- as.factor(PROF.OBS$month)
    PROF.OBS$order<- as.factor(PROF.OBS$order)
    
    PROF.OBS$taxonomic<- ifelse(PROF.OBS$kingdom == "Chromista" | PROF.OBS$kingdom == "Protozoa", "Bacteria",
                            ifelse(PROF.OBS$kingdom == "Fungi", "Fungi",
                                   ifelse(PROF.OBS$kingdom == "Plantae", "Plant",
                                          ifelse(PROF.OBS$phylum == "Annelida" |
                                                   PROF.OBS$phylum == "Arthropoda" |
                                                   PROF.OBS$phylum == "Mollusca" |
                                                   PROF.OBS$order == "Ploima" |
                                                   PROF.OBS$order == "Flosculariaceae", "Invertebrates",
                                                 ifelse(PROF.OBS$order == "Accipitriformes" |
                                                          PROF.OBS$order == "Anseriformes" |
                                                          PROF.OBS$order == "Apodiformes" |
                                                          PROF.OBS$order == "Charadriiformes" |
                                                          PROF.OBS$order == "Columbiformes" |
                                                          PROF.OBS$order == "Coraciiformes" |
                                                          PROF.OBS$order == "Cuculiformes" |
                                                          PROF.OBS$order == "Falconiformes" |
                                                          PROF.OBS$order == "Galliformes" |
                                                          PROF.OBS$order == "Gaviiformes" |
                                                          PROF.OBS$order == "Gruiformes" |
                                                          PROF.OBS$order == "Passeriformes" |
                                                          PROF.OBS$order == "Pelecaniformes" |
                                                          PROF.OBS$order == "Piciformes" |
                                                          PROF.OBS$order == "Podicipediformes" |
                                                          PROF.OBS$order == "Strigiformes" |
                                                          PROF.OBS$order == "Suliformes", "Birds",
                                                        ifelse(PROF.OBS$order == "Anura" |
                                                                 PROF.OBS$order == "Caudata" |
                                                                 PROF.OBS$order == "Squamata", "Herps",
                                                               ifelse(PROF.OBS$order == "Artiodactyla" |
                                                                        PROF.OBS$order == "Carnivora" |
                                                                        PROF.OBS$order == "Chiroptera" |
                                                                        PROF.OBS$order == "Lagomorpha" |
                                                                        PROF.OBS$order == "Rodentia" |
                                                                        PROF.OBS$order == "Soricomorpha",
                                                                      "Mammals",
                                                                      ifelse(PROF.OBS$order == "Cypriniformes" |
                                                                               PROF.OBS$order ==   "Gasterosteiformes"|
                                                                               PROF.OBS$order == "Salmoniformes" |
                                                                               PROF.OBS$order == "Esociformes",
                                                                             "Fish", NA))))))))
    
    table((PROF.OBS$taxonomic))
    table(is.na(PROF.OBS$taxonomic))
    
    check<- PROF.OBS[is.na(PROF.OBS$taxonomic) == TRUE,]
    
    
    # remove fish & bacteria
    PROF.OBS<- PROF.OBS[PROF.OBS$taxonomic != "Fish" & PROF.OBS$taxonomic != "Bacteria",]
    
    # remove the observations (appears to be primarily aquatic inverts & nematodes) that are only IDed to high level
    PROF.OBS<- PROF.OBS[is.na(PROF.OBS$kingdom) == FALSE,]
    PROF.OBS<- PROF.OBS[is.na(PROF.OBS$phylum) == FALSE,]
    PROF.OBS<- PROF.OBS[is.na(PROF.OBS$class) == FALSE,]
    PROF.OBS<- PROF.OBS[is.na(PROF.OBS$order) == FALSE,]
    
    PROF.OBS$taxonomic<- as.factor(PROF.OBS$taxonomic)
    
    # remove some other freshwater obligate taxonomic groups
    
    table(PROF.OBS$datasetName)
    
    PROF.OBS<- PROF.OBS[PROF.OBS$datasetName !=
                          "Limnic freshwater benthic invertebrates biogeographical mapping/inventory NTNU University Museum" &
                          PROF.OBS$datasetName !=
                    "Limnic freshwater pelagic invertebrates biogeographical mapping/inventory NTNU University Museum" &
                      PROF.OBS$datasetName !=
                    "NINA Vanndata øvrige arter",]
    
    PROF.OBS.view<- PROF.OBS[PROF.OBS$taxonomic == "Invertebrates",]
    chk<- data.frame(table(PROF.OBS.view$order))
    
    PROF.OBS<- PROF.OBS[PROF.OBS$order != "Sphaeriida" &
                          PROF.OBS$order != "Phyllodocida" &
                          PROF.OBS$order != "Rhynchobdellida" &
                          PROF.OBS$order != "Flosculariaceae" &
                          PROF.OBS$order != "Diplostraca" &
                          PROF.OBS$order != "Cyclopoida" &
                          PROF.OBS$order != "Calanoida" &
                          PROF.OBS$order != "Arhynchobdellida" &
                          PROF.OBS$order != "Arguloida" &
                          PROF.OBS$order != "Amphipoda",]
    
    table(PROF.OBS$taxonomic)

   
    
  ## ~~ Distance to trail ~~ ##
  
    dist<- as.vector(st_distance(PROF.OBS, TRAILS))
    PROF.OBS$distToTrail<- dist 

  
  ## ~~ Land cover type ~~ ##
  
    PROF.OBS<- st_join(PROF.OBS, ar5_2, st_intersects)
    PROF.OBS$artype<- mapvalues(PROF.OBS$artype, from = c("transportation","grazing"), to = c("developed","cultivated"))
    table(PROF.OBS$artype)
  
  
  ## ~~ Clean up ~~ ##
  
    PROF.OBS$source<- PROF.OBS$datasetName

    PROF.OBS$source<- as.factor(PROF.OBS$source)
    PROF.OBS$identifier<- as.factor(PROF.OBS$identifier)
    PROF.OBS$kingdom<- as.factor(PROF.OBS$kingdom)
    PROF.OBS$phylum<- as.factor(PROF.OBS$phylum)
    PROF.OBS$class<- as.factor(PROF.OBS$class)
    PROF.OBS$family<- as.factor(PROF.OBS$family)
    PROF.OBS$genus<- as.factor(PROF.OBS$genus)
    PROF.OBS$species<- as.factor(PROF.OBS$species)
    PROF.OBS$month<- as.factor(PROF.OBS$month)
    PROF.OBS$order<- as.factor(PROF.OBS$order)
    
  
    # Establish unique identifiers
    PROF.OBS$identifier<- paste(PROF.OBS$eventDate,
                                PROF.OBS$source,
                                PROF.OBS$geom)
  

  ## ~~ Make EVENTS object ~~ ##
  
    ## Make combined table of all events
    
    PROF.OBS$source<- as.character(PROF.OBS$source)
    PROF.EVENTS<- unique(PROF.OBS[c("eventDate", "source", "geom")])
    PROF.EVENTS$source<- as.factor(PROF.EVENTS$source)
    PROF.EVENTS$identifier<- paste(PROF.EVENTS$eventDate, PROF.EVENTS$source, PROF.EVENTS$geom)
    length(unique(PROF.EVENTS$identifier))

    # Add distance to events
    dist<- as.vector(st_distance(PROF.EVENTS, TRAILS))
    PROF.EVENTS$distToTrail<- dist
    
    ## Add number of observations per event
    numObsEvent<- data.frame(table(PROF.OBS$identifier))
    colnames(numObsEvent)<- c("identifier", "numObsEvent")
    PROF.EVENTS<- left_join(PROF.EVENTS, numObsEvent, by = "identifier")
    rm(numObsEvent)
    
    
    ## ~ Land cover type 
    PROF.EVENTS<- st_join(PROF.EVENTS, ar5_2, st_intersects)
    PROF.EVENTS$artype<- mapvalues(PROF.EVENTS$artype, from = c("transportation","grazing"), to = c("developed","cultivated"))
    table(PROF.EVENTS$artype)
    
  
  ## ~~ How many species? ~~ ##
  
    length(unique(PROF.OBS$species)) # 991 species
    
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Mammals",]$species)) # 0 mammal spp
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Plant",]$species)) # 338 plant spp
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Birds",]$species)) # 7  bird spp
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Fungi",]$species)) # 530 fungi spp
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Herps",]$species)) # 2 herp spp
    length(unique(PROF.OBS[PROF.OBS$taxonomic == "Invertebrates",]$species)) # 116 invert spp
  

    # Total species between the two datasets? #
    
    totalspecies<- c(unique(PROF.OBS$species), unique(CITSCI.OBS$species))
    length(unique(totalspecies))
    rm(totalspecies)

    
## Data description: summary information ####

  ### ~~~ Citizen science data trends ~~~ ###
  
    ## ~ Data sources & observers (citizen science)
  
      table(CITSCI.OBS$source)
      length(unique(CITSCI.OBS$recordedBy)) # 560 participants
  
  
    ## ~ Observations per participant (citizen science)
        
      chk<- data.frame(table(CITSCI.OBS$recordedBy))
      colnames(chk)<- c("recordedBy", "numObs")
      
      # Mean observations per participant
      mean(chk$numObs)
      median(chk$numObs)
      
      # Top 5% of participants (28)
      chk.top5pct<- chk[chk$numObs>230,]
      sum(chk.top5pct$numObs)
      34735/44206 # 79% of total data
      
  
    ## ~ Seasonality 
  
      # Citizen science
      CITSCI.EVENTS$month<- format(CITSCI.EVENTS$eventDate, "%m")
      table(CITSCI.EVENTS$month)
      
      # Professional
      PROF.EVENTS$month<- format(PROF.EVENTS$eventDate, "%m")
      table(PROF.EVENTS$month)
  
  
    ## ~ Land cover representation
  
      ar5_2$area<- as.numeric(st_area(ar5_2)) # m2
      land.available<- data.frame(tapply(ar5_2$area, ar5_2$artype, sum)) # proportions available
      land.available$artype<- rownames(land.available)
      colnames(land.available)[1]<- "area"
      land.available$proportion<- land.available$area/sum(land.available$area)
      
      land.cs<- data.frame(table(CITSCI.EVENTS$artype)) # proportions citizen science events
      colnames(land.cs)<- c("artype","area")
      land.cs$proportion<- land.cs$area/sum(land.cs$area)
      
      land.prof<- data.frame(table(PROF.EVENTS$artype)) # proportions professional events
      colnames(land.prof)<- c("artype", "area")
      land.prof$proportion<- land.prof$area/sum(land.prof$area)
  
    ## Clean-up
  
      rm(chk, chk.top25, chk.top5pct, chk2, dist)
      rm(strava, gbif)
      dev.off()

      
      
      
      
      
#### Results 3.1 Env covariates of CS - prep response variables in grid cells ####

  ## ~ Set up grid ~ ##
  
    g<- st_make_grid(bymarka, cellsize = 150)
    g<- st_as_sf(g)
  
    g$grid.id<- as.vector(c(1:5829))
  
  
  ## ~ Add citizen science observations and events to grid ~ ##
  
  # Add citizen science observations and events to grid dataframe
  
    match<- st_nearest_feature(CITSCI.EVENTS, g)
    CITSCI.EVENTS$grid.id<- match
    
    CITSCI.EVENTS$tally<- rep(1, times = 8614)
    gridEvents<- data.frame(tapply(CITSCI.EVENTS$tally, CITSCI.EVENTS$grid.id, sum))
    gridEvents$grid.id<- rownames(gridEvents)
    colnames(gridEvents)[1]<- "numberCSEvents"
    
    gridObserv<- data.frame(tapply(CITSCI.EVENTS$numObsEvent, CITSCI.EVENTS$grid.id, sum))
    gridObserv$grid.id<- rownames(gridObserv)
    colnames(gridObserv)[1]<- "numberCSObs"
    
    # Organize it into 'grid' dataframe
    
    gridEvents$grid.id<- as.factor(gridEvents$grid.id)
    gridObserv$grid.id<- as.factor(gridObserv$grid.id)
    g$grid.id<- as.factor(g$grid.id)
    grid<- g
    
    grid<- left_join(grid, gridEvents, by = "grid.id")
    grid<- left_join(grid, gridObserv, by = "grid.id")
  

  ## ~~ Add professional observations and events to grid ~ ##
  
    # Pair professional events with grid
    
    match<- st_nearest_feature(PROF.EVENTS, g)
    PROF.EVENTS$grid.id<- match
    
    # Sum up how many professional events are at each Strava segment
    
    PROF.EVENTS$tally<- as.vector(rep(1, times = 907))
    gridProfEvents<- data.frame(tapply(PROF.EVENTS$tally, PROF.EVENTS$grid.id, sum))
    gridProfEvents$grid.id<- rownames(gridProfEvents)
    colnames(gridProfEvents)[1]<- "numberProfEvents"
    
    # Sum up how many professional obervations are at each Strava segment
    
    gridProfObserv<- data.frame(tapply(PROF.EVENTS$numObsEvent, PROF.EVENTS$grid.id, sum))
    gridProfObserv$grid.id<- rownames(gridProfObserv)
    colnames(gridProfObserv)[1]<- "numberProfObs"
    
    # Collect segment information in one dataframe
    
    grid<- left_join(grid, gridProfEvents, by = "grid.id")
    grid<- left_join(grid, gridProfObserv, by = "grid.id")
  
  
  ## ~ Format grid dataframe ~ ##
  
    grid$numberCSEvents<- mapvalues(grid$numberCSEvents, from = NA, to = 0)
    grid$numberCSObs<- mapvalues(grid$numberCSObs, from = NA, to = 0)
    grid$numberProfEvents<- mapvalues(grid$numberProfEvents, from = NA, to = 0)
    grid$numberProfObs<- mapvalues(grid$numberProfObs, from = NA, to = 0)
    grid$grid.id<- as.factor(grid$grid.id)
    
    
    rm(gridEvents, gridObserv, gridProfEvents, gridProfObserv)
    
    
    
  ## ~~ Check outliers ~~ ##
    
    
    table(grid$numberProfObs)
    table(grid$numberCSObs)

    ch2<- st_transform(grid[grid$numberCSObs > 2000,], 4326)
    st_coordinates(st_centroid(ch2))
    
    # 1 10.24651 63.34105 # Gaulosen bird tower
    # 2 10.25550 63.34097 # Gaulosen bird tower
    # 3 10.24657 63.34239 # Gaulosen bird tower
    # 4 10.30422 63.35803 # Workout area?
    # 5 10.33419 63.35776 # School, ski center
    # 6 10.28977 63.37028
    # 7 10.30293 63.39575



#### Results 3.1 Env covariates of CS - prep covariates in grid cells ####

  ## ~~~ FACILITIES ~~~ ###
  
  ## ~ Format covariate
  
    colnames(anlegg)
    anlegg2<- anlegg[,c(7,38)]
    colnames(anlegg2)[1]<- "name"
    
    colnames(badeplass)
    badeplass2<- badeplass[,c(7,19)]
    colnames(badeplass2)[1]<- "name"
    
    facilities<- rbind(anlegg2, badeplass2)
    
    # Add additional facilities points not included
    
    facilities.new<- as.data.frame(cbind(latitude = c(63.37835684950467, 63.402586592906715,
                                                      63.4176822927028, 63.41923137252817,
                                                      63.4427927070446, 63.42318934337359),
                                         longitude = c(10.260741557608286, 10.241688393881024,
                                                       10.26220519672332, 10.210118461074808,
                                                       10.288624663204455, 10.304072169021417),
                                         name = c("Rønningen", "Grønlia",
                                                  "Skistua", "Elgsethytta",
                                                  "Damhaugen", "Lavollen")))
    
    facilities.new$latitude<- as.numeric(facilities.new$latitude)
    facilities.new$longitude<- as.numeric(facilities.new$longitude)
    
    facilities.new<- st_as_sf(facilities.new, coords = c("longitude", "latitude"),
                              crs = '+proj=longlat +ellps=WGS84 +datum=WGS84   +no_defs')
    
    facilities.new<- st_transform(facilities.new, st_crs(bymarka))   
    
    colnames(facilities)
    colnames(facilities.new)[2]<- "geom"
    st_geometry(facilities.new) <- "geom"
    
    facilities<- rbind(facilities, facilities.new)
    
    
    # ~ ADD TO GRID
    
    match<- st_intersection(facilities, g)
    match$tally<- rep(1, times = 62)
    
    check<- ddply(match, c("grid.id"), summarize,
                  numberFacilities = as.vector(sum(tally)))
    
    check$grid.id<- as.factor(check$grid.id)
    
    grid<- left_join(grid, check, by = "grid.id")
    grid$binaryFacilities<- ifelse(grid$numberFacilities > 0, 1, 0)
    grid$binaryFacilities<- mapvalues(grid$binaryFacilities, from = NA, to = 0)
    grid$numberFacilities<- NULL
    
    table(grid$binaryFacilities)

  
  ## ~~~ ACCESS ~~~ ##
  
    ## ~ Format covariate
    
    fot.access<- st_intersection(fotrute, st_cast(bymarka, "MULTILINESTRING", group_or_split = FALSE))
    ski.access<- st_intersection(ski, st_cast(bymarka, "MULTILINESTRING", group_or_split = FALSE))
    
    fot.access2<- st_as_sf(fot.access$geom)
    ski.access2<- st_as_sf(fot.access$geom)
    
    access<- st_as_sf(rbind(fot.access2,ski.access2))
    
    
    # Add additional access points not included
    
    access.new<- as.data.frame(cbind(latitude = c(63.43378457284139, 63.42771145276212,
                                                  63.42310219267511, 63.42496709708156,
                                                  63.41760975999009, 63.41648466410479,
                                                  63.41518186626552, 63.417688712421366,
                                                  63.367174417150075, 63.402887609850026,
                                                  63.41672854036551, 63.41527041853962,
                                                  63.41620187458355, 63.416739239295936,
                                                  63.414741982923644),
                                     longitude = c(10.275034735229399, 10.283929044025285,
                                                   10.303552290154567, 10.342012280009808,
                                                   10.341744637229011, 10.327806154885874,
                                                   10.269317458840549, 10.26124548955829,
                                                   10.304279272724374, 10.314213419185018,
                                                   10.313861543282277, 10.302274621684997,
                                                   10.293468684695005, 10.288185122474722,
                                                   10.274996230536296),
                                     name = c("Tømmerdalen parking","Gamle Bynesvei parking",
                                              "Lavollen parking", "Gramskaret parking",
                                              "Ferista parking", "Baklidammen parking",
                                              "Henriksåsen parking", "Gråkallen parking",
                                              "Smistad parking", "Lian tram",
                                              "Fjellseter buss 1", "Fjellseter buss 2",
                                              "Storsvingen parking", "Fjellseter buss 3",
                                              "Fjellseter buss 4")))
    
    access.new$latitude<- as.numeric(access.new$latitude)
    access.new$longitude<- as.numeric(access.new$longitude)
    
    access.new<- st_as_sf(access.new, coords = c("longitude", "latitude"),
                          crs = '+proj=longlat +ellps=WGS84 +datum=WGS84   +no_defs')
    
    access.new<- st_transform(access.new, st_crs(bymarka))   
    
    colnames(access.new)[2]<- "geom"
    st_geometry(access.new) <- "geom"
    
    # Merge access datasets
    
    access$name<- c(1:58)
    access$name<- as.character(access$name)
    colnames(access)[1]<- "geom"
    st_geometry(access) <- "geom"
    
    access<- rbind(access, access.new)
    
    
    # ~ ADD TO GRID
    
    dist<- st_nearest_feature(g, access)
    dist2<- st_distance(g, access[dist,], by_element=TRUE)
    grid$access.dist<- as.vector(dist2)
    

    
  ## ~~~ LAND COVER ~~~ ##
  
    # Each grid cell is here labeled (*in a separate row*) with all artypes that it contains
    grid.ar5<- st_intersection(g, ar5_2)
    grid.ar5$area<- as.vector(st_area(grid.ar5)) # units: m^2 - area of each artype portion within each grid cell
    
    # Segments are here summarized by the total area of each artype present in the segment
    gridartypes<- ddply(grid.ar5, c("grid.id", "artype"), summarize,
                  area = as.vector(sum(area)))

    ## Create area-based measures for land cover types ##
    
    table(gridartypes$artype)
    
    # Cultivated
    cultiv<- gridartypes[gridartypes$artype == "cultivated" | gridartypes$artype == "grazing",]
    
    check<- ddply(cultiv, c("grid.id"), summarize,
                  cultivated.area = as.vector(sum(area)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$cultivated.area<- mapvalues(grid$cultivated.area, from = NA, to = 0)
    
    # Developed
    devel<- gridartypes[gridartypes$artype == "developed" | gridartypes$artype == "transportation",]
    
    check<- ddply(devel, c("grid.id"), summarize,
                  developed.area = as.vector(sum(area)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$developed.area<- mapvalues(grid$developed.area, from = NA, to = 0)
    
    # Forest
    forest<- gridartypes[gridartypes$artype == "forest",]
    
    check<- ddply(forest, c("grid.id"), summarize,
                  forest.area = as.vector(sum(area)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$forest.area<- mapvalues(grid$forest.area, from = NA, to = 0)

    # Open
    open<- gridartypes[gridartypes$artype == "open",]
    
    check<- ddply(open, c("grid.id"), summarize,
                  open.area = as.vector(sum(area)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$open.area<- mapvalues(grid$open.area, from = NA, to = 0)
    
    # Mire
    mire<- gridartypes[gridartypes$artype == "mire",]
    
    check<- ddply(mire, c("grid.id"), summarize,
                  mire.area = as.vector(sum(area)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$mire.area<- mapvalues(grid$mire.area, from = NA, to = 0)
    
    
  ## ** Use land cover to remove grid cells not in study area boundary ** ##
    
    check<- gridartypes %>%
      group_by(grid.id) %>% slice_max(order_by = area)
    
    check<- as.data.frame(check)
    check<- check[,c(1:2)]
    
    grid<- left_join(grid, check, by = "grid.id")

 
    grid<- grid[is.na(grid$artype) == FALSE,] # now any NA values in any column can be accurately interpreted as 0s
    
    grid$artype<- NA
    
  
  ## ~~~ WATER ~~~ ##
  
    # Does grid contain freshwater?
    
    watergrids<- gridartypes[gridartypes$artype == "freshwater",]
    watergrids$binaryWater<- rep(1, times = 827)
    watergrids<- watergrids[,c(1,4)]
    
    grid<- left_join(grid, watergrids, by = "grid.id")
    grid$binaryWater<- mapvalues(grid$binaryWater, from = NA, to = 0)
    table(grid$binaryWater)
    
  
  ## ~~~ PATHS ~~~ ##
  
    grid.paths<- st_intersection(g, TRAILS)
    grid.paths$length<- as.vector(st_length(grid.paths)) # units: m - total length of each section of trail in each grid cell
    grid.paths<- grid.paths[,c(1,3)]
    
    # Total trail length per grid cell
    
    check<- ddply(grid.paths, c("grid.id"), summarize,
                  totalTrails = as.vector(sum(length)))
    
    grid<- left_join(grid, check, by = "grid.id")
    
    grid$totalTrails<- mapvalues(grid$totalTrails, from = NA, to = 0)
      
  
  
  ## ~~~ ELEVATION ~~~ ##

    elevation<- elevatr::get_elev_raster(bymarka, z = 9)   
    elevation<- st_as_stars(elevation)
    
    elevation.pol<- st_as_sf(elevation, as_points = FALSE, merge = TRUE)
    colnames(elevation.pol)[1]<- "elevation"
    elevation.pol<- st_intersection(bymarka, elevation.pol) # indicates error in intersect, data are ok though (see plot)
    
    grid.elev<- st_intersection(grid, elevation.pol)
    grid.elev$area<- as.vector(st_area(grid.elev))
    table(is.na(grid.elev$area))
    
    check<- ddply(grid.elev, c("grid.id"), summarize,
                  elevation.max = max(elevation))
    
    grid<- left_join(grid, check, by = "grid.id")
    hist(grid$elevation.max)
  
  
  ## ~~~ CARDINAL DIRECTIONS ~~~ ##
  
    c<- st_centroid(grid)
    coords<- st_coordinates(c)
    coords<- data.frame(coords)
    
    grid$eastness<- coords$X
    grid$northness<- coords$Y
  
  
  
  ## ~~ Clean up format of covariates ~~ ##
  
    str(grid)
    
    grid$grid.id<- as.factor(grid$grid.id)
    grid$binaryFacilities<- as.factor(grid$binaryFacilities)
    grid$binaryWater<- as.factor(grid$binaryWater)
    grid$artype<- NULL

  
    ## check of correlations
    
    ch<- (grid[,c("access.dist", "totalTrails", "eastness",
                     "elevation.max",
                     "developed.area", "cultivated.area",
                     "open.area", "forest.area", "mire.area")])
    
    ch$x<- NULL
    
    str(ch)
    cor(ch)
    



#### Results 3.1 Env covariates of CS - CS model selection ####

    memory.limit(size = 25000)

    ## ~~ Correlation tests ~~ ##
    
    cor.test(grid$numberCSObs, grid$numberProfObs, method = "pearson")
   
    
    ## ~~ GRID MODEL: CITIZEN SCIENCE ~~ ##
    
    #table(grid$numberCSObs)
    #grid2<- grid[grid$numberCSObs < 2000,]
    #
    #citsci <- glmulti(numberCSObs ~
    #                 access.dist + totalTrails + eastness +
    #                 binaryFacilities + elevation.max +
    #                 developed.area + cultivated.area + binaryWater +
    #                 open.area + forest.area + mire.area,
    #               data = grid2,
    #               level = 1,
    #               fitfunction = glm.nb,
    #               crit="aicc",
    #               confsetsize=2048)
    #
    #print(citsci) 
    #
    #top <- weightable(citsci)
    #top <- top[top$aicc <= min(top$aicc) + 5,]
    #top    
    #
    #check_zeroinflation(citsci@objects[[1]])
    #
    #plot(citsci, type="s")
    #
    #eval(metafor:::.glmulti)
    #coef(citsci)
    #
    #mmi <- as.data.frame(coef(citsci))
    #mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond), Importance=mmi$Importance, row.names=row.names(mmi))
    #mmi$z <- mmi$Estimate / mmi$SE
    #mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
    #names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
    #mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
    #mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
    #mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
    #
    #mmi[,c(1,2,7)]
    
    # Check autocorrelation
    #
    #moran.test(residuals.glm(citsci@objects[[1]]),
    #           nb2listw(poly2nb(grid2, queen = TRUE), style = "W", zero.policy = TRUE))
    
    
    ## ~~ GRID MODEL: CITIZEN SCIENCE (with autocovariate) ~~ ##
    
    table(grid$numberCSObs)
    grid2<- grid[grid$numberCSObs < 2000,]
    
    c<- st_centroid(grid2)
    coords<- st_coordinates(c)
    
    ac<- autocov_dist(grid2$numberCSObs, coords, nbs = 300)
    
    grid2$ac<- ac
    
    citsci.ac<- glmulti(numberCSObs ~
                          access.dist + totalTrails + eastness +
                          binaryFacilities + elevation.max +
                          developed.area + cultivated.area + binaryWater +
                          forest.area + mire.area + ac,
                        data = grid2,
                        level = 1,
                        fitfunction = glm.nb,
                        crit="aicc",
                        confsetsize=2048)
    
    
    moran.test(residuals.glm(citsci.ac@objects[[1]]),
               nb2listw(poly2nb(grid2, queen = TRUE), style = "W", zero.policy = TRUE))
    
    
    ## Review outputs:
    
    print(citsci.ac) 
    
    top <- weightable(citsci.ac)
    top <- top[top$aicc <= min(top$aicc) + 2,]
    top    
    
    check_zeroinflation(citsci.ac@objects[[1]])
    
    plot(citsci.ac, type = "p")
    plot(citsci.ac, type = "s")
    
    eval(metafor:::.glmulti)
    coef(citsci.ac)
    
    mmi <- as.data.frame(coef(citsci.ac))
    mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond), Importance=mmi$Importance, row.names=row.names(mmi))
    mmi$z <- mmi$Estimate / mmi$SE
    mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
    names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
    mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
    mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
    mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
    
    mmi[,c(1,2,7)]
    
    
    
    ## ~~ VISUALIZATIONS: CITIZEN SCIENCE GRID MODELS ~~ ##
    
    paletteer_c("grDevices::Viridis", 30)
    
    
    ## totalTrails ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "totalTrails", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "totalTrails", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "totalTrails", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "totalTrails", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "totalTrails", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "totalTrails", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    
    ggplot(cdata, aes(totalTrails, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Longitude (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 1.0000") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## binaryWater ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "binaryWater", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "binaryWater", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "binaryWater", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "binaryWater", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "binaryWater", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "binaryWater", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    cdata$binaryWater<- mapvalues(cdata$binaryWater, from = c("1","0"), to = c("Present", "Not present"))
    
    ggplot(cdata, aes(binaryWater, numberCSObs, group = model)) +
      geom_point(aes(x = binaryWater, y = numberCSObs, col = model),
                 position = position_dodge(width = 0.3), pch = 18, cex = 4) +
      geom_linerange(aes(col = model, ymin = ymin, ymax = ymax),
                     position = position_dodge(width = 0.3), lwd = 1.2) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Presence of recreational facilities") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 1.0000") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## access.dist ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "access.dist", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "access.dist", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "access.dist", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "access.dist", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "access.dist", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "access.dist", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    
    ggplot(cdata, aes(access.dist, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Distance from access point (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9988") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## developed.area ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "developed.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "developed.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "developed.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "developed.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "developed.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "developed.area", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    
    ggplot(cdata, aes(developed.area, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Developed~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9976") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## cultivated.area ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "cultivated.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "cultivated.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "cultivated.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "cultivated.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "cultivated.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "cultivated.area", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    
    ggplot(cdata, aes(cultivated.area, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Cultivated~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9959") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## eastness ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "eastness", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "eastness", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "eastness", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "eastness", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "eastness", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "eastness", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6"))
    
    ggplot(cdata, aes(eastness, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Longitude (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9126") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## forest.area ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "forest.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "forest.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "forest.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "forest.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "forest.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "forest.area", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data1,data2,data3,data4,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 6"))
    
    ggplot(cdata, aes(forest.area, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#009F94")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Forest~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.7900") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## mire.area ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "mire.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "mire.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "mire.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "mire.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "mire.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "mire.area", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data3,data4,data5)
    cdata$model<- factor(cdata$model, levels = c("Model 3", "Model 4",
                                                 "Model 5"))
    
    ggplot(cdata, aes(mire.area, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#00558A","#007395","#008F97")) +
      scale_fill_manual(values = c("#00558A","#007395","#008F97")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Mire~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.5379") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## elevation.max ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "elevation.max", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "elevation.max", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "elevation.max", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "elevation.max", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "elevation.max", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "elevation.max", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data2,data4)
    cdata$model<- factor(cdata$model, levels = c("Model 2", "Model 4"))
    
    ggplot(cdata, aes(elevation.max, numberCSObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.085) +
      scale_color_manual(values = c("#3D3576","#007395")) +
      scale_fill_manual(values = c("#3D3576","#007395")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Elevation (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.4681") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## binaryFacilities ##
    
    data1 <- make_predictions(citsci.ac@objects[[1]], pred = "binaryFacilities", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(citsci.ac@objects[[2]], pred = "binaryFacilities", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(citsci.ac@objects[[3]], pred = "binaryFacilities", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(citsci.ac@objects[[4]], pred = "binaryFacilities", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(citsci.ac@objects[[5]], pred = "binaryFacilities", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(citsci.ac@objects[[6]], pred = "binaryFacilities", interval = TRUE)
    data6$model <- "Model 6"
    
    cdata <- bind_rows(data6)
    cdata$model<- factor(cdata$model, levels = c("Model 6"))
    cdata$binaryFacilities<- mapvalues(cdata$binaryFacilities, from = c("1","0"), to = c("Present", "Not present"))
    
    
    ggplot(cdata, aes(binaryFacilities, numberCSObs, group = model)) +
      geom_point(aes(x = binaryFacilities, y = numberCSObs, col = model),
                 position = position_dodge(width = 0.3), pch = 18, cex = 4) +
      geom_linerange(aes(col = model, ymin = ymin, ymax = ymax),
                     position = position_dodge(width = 0.3), lwd = 1.2) +
      scale_color_manual(values = c("#009F94")) +
      scale_fill_manual(values = c("#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Presence of recreational facilities") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.2726") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
#### Results 3.1 Env covariates of CS - PROF model selection ####
  
    ## ~~ BASIC MODEL: PROFESSIONAL ~~ ##
    
    table(grid$numberProfObs)
    grid3<- grid[grid$numberProfObs < 170,]
    
    # Basic model 
    
    #profmod <- glmulti(numberProfObs ~
    #                 access.dist + totalTrails + eastness +
    #                 binaryFacilities + elevation.max +
    #                 developed.area + cultivated.area + binaryWater +
    #                 forest.area + mire.area,
    #               data = grid3,
    #               level = 1,
    #               fitfunction = glm.nb,
    #               crit="aicc",
    #               confsetsize=2048)
    #
    #print(profmod) 
    #
    #top <- weightable(profmod)
    #top <- top[top$aicc <= min(top$aicc) + 5,]
    #top    
    #
    #summary(profmod@objects[[1]])
    #check_zeroinflation(profmod@objects[[1]])
    #check_autocorrelation(profmod@objects[[1]])
    #
    #plot(profmod, type="s")
    #
    #eval(metafor:::.glmulti)
    #coef(profmod)
    #
    #mmi <- as.data.frame(coef(profmod))
    #mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond), Importance=mmi$Importance, row.names=row.names(mmi))
    #mmi$z <- mmi$Estimate / mmi$SE
    #mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
    #names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
    #mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
    #mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
    #mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
    #
    #mmi[,c(1,2,7)]
    #
    #
    ## Check autocorrelation
    #
    #moran.test(residuals.glm(profmod@objects[[1]]),
    #           nb2listw(poly2nb(grid2, queen = TRUE), style = "W", zero.policy = TRUE))
    
    
    
    ## ~~ BASIC MODEL: PROFESSIONAL (with) ~~ ##
    
    c<- st_centroid(grid3)
    coords<- st_coordinates(c)
    
    ac<- autocov_dist(grid3$numberProfObs, coords, nbs = 300)
    grid3$ac<- ac
    
    profmod.ac<- glmulti(numberProfObs ~
                           access.dist + totalTrails + eastness +
                           binaryFacilities + elevation.max +
                           developed.area + cultivated.area + binaryWater +
                           forest.area + mire.area + ac,
                         data = grid3,
                         level = 1,
                         fitfunction = glm.nb,
                         crit="aicc",
                         confsetsize=2048)
    
    
    moran.test(residuals.glm(profmod.ac@objects[[1]]),
               nb2listw(poly2nb(grid3, queen = TRUE), style = "W", zero.policy = TRUE))
    
    
    ## Review outputs:
    
    print(profmod.ac) 
    
    top <- weightable(profmod.ac)
    top <- top[top$aicc <= min(top$aicc) + 2,]
    top    
    
    check_zeroinflation(profmod.ac@objects[[1]])
    
    plot(profmod.ac, type="p")
    plot(profmod.ac, type="s")
    
    eval(metafor:::.glmulti)
    coef(profmod.ac)
    
    mmi <- as.data.frame(coef(profmod.ac))
    mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond),
                      Importance=mmi$Importance, row.names=row.names(mmi))
    mmi$z <- mmi$Estimate / mmi$SE
    mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
    names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
    mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
    mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
    mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
    
    mmi[,c(1,2,7)]
    
    
    
    ## ~~ VISUALIZATIONS: PROFESSIONAL GRID MODELS ~~ ##
    
    paletteer_c("grDevices::Viridis", 30)
    
    
    ## binaryWater ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "binaryWater", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "binaryWater", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "binaryWater", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "binaryWater", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "binaryWater", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "binaryWater", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "binaryWater", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "binaryWater", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    cdata$binaryWater<- mapvalues(cdata$binaryWater, from = c("1","0"), to = c("Present", "Not present"))
    
    
    ggplot(cdata, aes(binaryWater, numberProfObs, group = model)) +
      geom_point(aes(x = binaryWater, y = numberProfObs, col = model),
                 position = position_dodge(width = 0.3), pch = 18, cex = 4) +
      geom_linerange(aes(col = model, ymin = ymin, ymax = ymax),
                     position = position_dodge(width = 0.3), lwd = 1.2) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Presence of water") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9997") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## access.dist ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "access.dist", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "access.dist", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "access.dist", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "access.dist", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "access.dist", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "access.dist", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "access.dist", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "access.dist", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    
    ggplot(cdata, aes(access.dist, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Distance from access (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9996") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## cultivated.area ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "cultivated.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "cultivated.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "cultivated.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "cultivated.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "cultivated.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "cultivated.area", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "cultivated.area", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "cultivated.area", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    
    ggplot(cdata, aes(cultivated.area, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Cultivated~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9857") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## mire.area ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "mire.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "mire.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "mire.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "mire.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "mire.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "mire.area", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "mire.area", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "mire.area", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    
    ggplot(cdata, aes(mire.area, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Wetland~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9655") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## eastness ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "eastness", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "eastness", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "eastness", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "eastness", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "eastness", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "eastness", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "eastness", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "eastness", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    
    ggplot(cdata, aes(eastness, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Longitude (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.9103") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## totalTrails ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "totalTrails", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "totalTrails", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "totalTrails", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "totalTrails", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "totalTrails", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "totalTrails", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "totalTrails", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "totalTrails", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                                 "Model 5", "Model 6", "Model 7", "Model 8"))
    
    ggplot(cdata, aes(totalTrails, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395","#008F97","#009F94","#00A790","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Trail length (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.8837") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## binaryFacilities ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "binaryFacilities", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "binaryFacilities", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "binaryFacilities", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "binaryFacilities", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "binaryFacilities", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "binaryFacilities", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "binaryFacilities", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "binaryFacilities", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data1,data4,data5,data8)
    cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 4",
                                                 "Model 5", "Model 8"))
    
    ggplot(cdata, aes(binaryFacilities, numberProfObs, group = model)) +
      geom_point(aes(x = binaryFacilities, y = numberProfObs, col = model),
                 position = position_dodge(width = 0.15), pch = 18, cex = 4) +
      geom_linerange(aes(col = model, ymin = ymin, ymax = ymax),
                     position = position_dodge(width = 0.15), lwd = 1.2) +
      scale_color_manual(values = c("#4A0A5D","#007395","#008F97","#00B686")) +
      scale_fill_manual(values = c("#4A0A5D","#007395","#008F97","#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Presence of recreational facilities") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.4802") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## developed.area ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "developed.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "developed.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "developed.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "developed.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "developed.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "developed.area", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "developed.area", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "developed.area", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data3,data4)
    cdata$model<- factor(cdata$model, levels = c("Model 3", "Model 4"))
    
    ggplot(cdata, aes(developed.area, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#00558A","#007395")) +
      scale_fill_manual(values = c("#00558A","#007395")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Developed~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.4212") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    
    ## elevation.max ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "elevation.max", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "elevation.max", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "elevation.max", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "elevation.max", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "elevation.max", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "elevation.max", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "elevation.max", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "elevation.max", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data5,data6)
    cdata$model<- factor(cdata$model, levels = c("Model 5", "Model 6"))
    
    ggplot(cdata, aes(elevation.max, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
      scale_color_manual(values = c("#008F97","#009F94")) +
      scale_fill_manual(values = c("#008F97","#009F94")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab("Elevation (m)") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.3205") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
    
    
    ## forest.area ##
    
    data1 <- make_predictions(profmod.ac@objects[[1]], pred = "forest.area", interval = TRUE)
    data1$model <- "Model 1"
    data2 <- make_predictions(profmod.ac@objects[[2]], pred = "forest.area", interval = TRUE)
    data2$model <- "Model 2"
    data3 <- make_predictions(profmod.ac@objects[[3]], pred = "forest.area", interval = TRUE)
    data3$model <- "Model 3"
    data4 <- make_predictions(profmod.ac@objects[[4]], pred = "forest.area", interval = TRUE)
    data4$model <- "Model 4"
    data5 <- make_predictions(profmod.ac@objects[[5]], pred = "forest.area", interval = TRUE)
    data5$model <- "Model 5"
    data6 <- make_predictions(profmod.ac@objects[[6]], pred = "forest.area", interval = TRUE)
    data6$model <- "Model 6"
    data7 <- make_predictions(profmod.ac@objects[[7]], pred = "forest.area", interval = TRUE)
    data7$model <- "Model 7"
    data8 <- make_predictions(profmod.ac@objects[[8]], pred = "forest.area", interval = TRUE)
    data8$model <- "Model 8"
    
    data8 <- make_predictions(mod8, pred = "forest.area", interval = TRUE)
    data8$model <- "Model 8"
    
    cdata <- bind_rows(data8)
    cdata$model<- factor(cdata$model, levels = c("Model 8"))
    
    ggplot(cdata, aes(forest.area, numberProfObs, group = model)) +
      stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
      geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.07) +
      scale_color_manual(values = c("#00B686")) +
      scale_fill_manual(values = c("#00B686")) +
      theme_bw() +
      theme(axis.text = element_text(size = 16)) +
      theme(axis.title = element_text(size = 18)) +
      xlab(expression(Forest~area~(m^2))) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none") +
      ggtitle("Variable Importance = 0.3139") +
      theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
#### Results 3.1 Figure: Grid map of citizen science and professional data ####
    
    # Citizen science
    
    ggplot() +
      geom_sf(data = bymarka) +
      geom_sf(data = grid[grid$numberCSObs == 0,], fill = "grey90", color = "grey60") +
      geom_sf(data = grid[grid$numberCSObs > 0,], aes(fill = log(numberCSObs)), color = "grey60") +
      scale_fill_gradient(low = "#A3D5B0", high = "#080E5B") +
      theme_minimal()
    
    
    # Professional    
    
    ggplot() +
      geom_sf(data = bymarka) +
      geom_sf(data = grid[grid$numberProfObs == 0,], fill = "grey90", color = "grey60") +
      geom_sf(data = grid[grid$numberProfObs > 0,], aes(fill = log(numberProfObs)), color = "grey60") +
      scale_fill_gradient(low = "#A3D5B0", high = "#080E5B") +
      theme_minimal()
    

    
#### Results 3.2 - Trail distances: citizen science and professional biodiversity data ####

  ## ~~ Distance to trail for each data type by unique locations ~~ ##
  
    # Set-up citsci and prof data
    CITSCI.EVENTS.loc<- unique(CITSCI.EVENTS["geom"])
    CITSCI.EVENTS.loc.dists<- as.vector(st_distance(CITSCI.EVENTS.loc, TRAILS))
    CITSCI.EVENTS.loc$dists<- CITSCI.EVENTS.loc.dists
    
    PROF.EVENTS.loc<- unique(PROF.EVENTS["geom"])
    PROF.EVENTS.loc.dists<- as.vector(st_distance(PROF.EVENTS.loc, TRAILS))
    PROF.EVENTS.loc$dists<- PROF.EVENTS.loc.dists
    
    # Random sampling
    set.seed(1234)
    t<- st_sample(bymarka, size = 3000, type = "random")
    randomdists<- as.vector(st_distance(t, TRAILS))

    # Significance test set-up
    dists2<- data.frame(cbind(c(c(CITSCI.EVENTS.loc.dists, rep(NA, times = 42)),
                                c(PROF.EVENTS.loc.dists, rep(NA, times = 2210)),
                                randomdists),
                              c(rep("cs", times = 3000),
                                rep("prof", times = 3000),
                                rep("random", times = 3000))))
    colnames(dists2)<- c("distance","type")
    dists2$distance<- as.numeric(dists2$distance)
    dists2$type<-as.factor(dists2$type)
    dists2$type<- factor(dists2$type, levels = c("random", "prof", "cs"))
    
    # lm
    mod<- lm(dists2$distance ~ dists2$type)
    summary(mod)
    
    tapply(dists2$distance, dists2$type, mean, na.rm = T)
    tapply(dists2$distance, dists2$type, sd, na.rm = T)
    

  ## ~~ Distance to trail by taxonomic group ~~ ##
  
    ## ~ Citizen science ~ ##
    
      mod<- lm(CITSCI.OBS$distToTrail ~ CITSCI.OBS$taxonomic)
      summary(mod)
      
      hsd<- HSD.test(mod, "CITSCI.OBS$taxonomic", unbalanced = TRUE)
      hsd
      
      tapply(CITSCI.OBS$distToTrail, CITSCI.OBS$taxonomic, mean)
      
      ggplot(data = CITSCI.OBS, aes(x = taxonomic, y = distToTrail)) +
        geom_boxplot() +
        stat_summary(fun = mean, geom = "point", shape = 18, size = 2) +
        theme_minimal()
    
    ## ~ Professional ~ ##
  
      mod<- lm(PROF.OBS$distToTrail ~ PROF.OBS$taxonomic)
      summary(mod)
      
      hsd<- HSD.test(mod, "PROF.OBS$taxonomic", unbalanced = TRUE)
      hsd
      
      tapply(PROF.OBS$distToTrail, PROF.OBS$taxonomic, sd)
      
      
      ggplot(data = PROF.OBS, aes(x = taxonomic, y = distToTrail)) +
        geom_boxplot() +
        stat_summary(fun = mean, geom = "point", shape = 18, size = 2) +
        theme_minimal()
  
  
    ## ~ Figure  ~ ##
  
    PROF.OBS$datatype<- as.vector(rep("PROF", times = 2059))
    CITSCI.OBS$datatype<- as.vector(rep("CITSCI", times = 44206))
    
    PROF.OBS$tally<- rep(1, times = 2059)
    CITSCI.OBS$tally<- rep(1, times = 44206)
    
    colnames(PROF.OBS)
    
    combined<- rbind(PROF.OBS[,c(255,256,259,260)], CITSCI.OBS[,c(255,256,259,260)])
    
    levels(combined$taxonomic)
    
    combined$taxonomic<- factor(combined$taxonomic,
                                levels = c("Fungi","Herps",
                                           "Plant","Invertebrates",
                                           "Mammals","Birds"))
    
    combined<- combined[is.na(combined$taxonomic) == FALSE,]  
    
    ch<- ddply(combined, c("taxonomic", "datatype"), summarize,
               meanDist = mean(distToTrail),
               sdDist = sd(distToTrail))
    
    install.packages("ggridges")
    library(ggridges)
    
    ggplot(data = combined, aes(x = distToTrail, y = taxonomic, fill = datatype)) +
      geom_density_ridges(alpha = 0.5) +
      scale_fill_manual(values = c("#2D3A7C", "#86ADA7"))
    
    
    
    

    
    
#### Results 3.3 - Citizen science and Strava activity along trail segments: set-up ####

  ## ~~ Prepare trail segments for analysis ~~ ##
  
  ## ~~ Add citizen science data ~~ ##
    
    # Filter observation points by distance 
    
    CITSCI.EVENTS.snap<- CITSCI.EVENTS[CITSCI.EVENTS$distToTrail < 151,]

    # Set up segments template
    
    shp$strava.id<- c(1:7153)
    colnames(shp)
    shp<- shp[,c(25:27)]
    
    # Determine which Strava segment ID is associated with each CS event
    
    match<- st_nearest_feature(CITSCI.EVENTS.snap, shp)
    CITSCI.EVENTS.snap$strava.id<- match
   
    # Sum up how many CS events are at each Strava segment
    
    CITSCI.EVENTS.snap$tally<- as.vector(rep(1, times = 8512))
    segmentCitsciEvents<- data.frame(tapply(CITSCI.EVENTS.snap$tally, CITSCI.EVENTS.snap$strava.id, sum))
    segmentCitsciEvents$strava.id<- rownames(segmentCitsciEvents)
    colnames(segmentCitsciEvents)[1]<- "numberCSEvents"
    
    # Sum up how many CS obervations are at each Strava segment
    
    segmentCitsciObserv<- data.frame(tapply(CITSCI.EVENTS.snap$numObsEvent, CITSCI.EVENTS.snap$strava.id, sum))
    segmentCitsciObserv$strava.id<- rownames(segmentCitsciObserv)
    colnames(segmentCitsciObserv)[1]<- "numberCSObs"
    
    # Collect segment information in one dataframe
    
    shp$strava.id<- as.factor(shp$strava.id)
    segmentCitsciEvents$strava.id<- as.factor(segmentCitsciEvents$strava.id)
    
    segments<- left_join(shp, segmentCitsciEvents, by = "strava.id")
    segments<- left_join(segments, segmentCitsciObserv, by = "strava.id")    
    
    
    ## ~~ Add professional data ~~ ##
    
    # Filter observation points by distance 
    
    PROF.EVENTS.snap<- PROF.EVENTS[PROF.EVENTS$distToTrail < 151,]
    
    # Determine which Strava segment ID is associated with each professional event
    
    match<- st_nearest_feature(PROF.EVENTS.snap, shp)
    PROF.EVENTS.snap$strava.id<- match
    
    # Sum up how many CS events are at each Strava segment
    
    PROF.EVENTS.snap$tally<- as.vector(rep(1, times = 840))
    segmentProfEvents<- data.frame(tapply(PROF.EVENTS.snap$tally, PROF.EVENTS.snap$strava.id, sum))
    segmentProfEvents$strava.id<- rownames(segmentProfEvents)
    colnames(segmentProfEvents)[1]<- "numberProfEvents"
    
    # Sum up how many CS obervations are at each Strava segment
    
    segmentProfObserv<- data.frame(tapply(PROF.EVENTS.snap$numObsEvent, PROF.EVENTS.snap$strava.id, sum))
    segmentProfObserv$strava.id<- rownames(segmentProfObserv)
    colnames(segmentProfObserv)[1]<- "numberProfObs"
    
    # Collect segment information in one dataframe
    
    segmentProfEvents$strava.id<- as.factor(segmentProfEvents$strava.id)
    
    segments<- left_join(segments, segmentProfEvents, by = "strava.id")
    segments<- left_join(segments, segmentProfObserv, by = "strava.id")    
    
    # Cleaning
    
    segments$numberCSEvents<- mapvalues(segments$numberCSEvents, from = NA, to = 0)
    segments$numberCSObs<- mapvalues(segments$numberCSObs, from = NA, to = 0)
    segments$numberProfEvents<- mapvalues(segments$numberProfEvents, from = NA, to = 0)
    segments$numberProfObs<- mapvalues(segments$numberProfObs, from = NA, to = 0)
    
    segments$TotalActivity<- as.numeric(segments$TotalActivity)
    segments$strava.id<- as.factor(segments$strava.id)
    
    segments$length<- st_length(segments)
    segments$length<- as.vector(segments$length)
    
    
    ## Correlations
    
    cor.test(segments$st_numberCSObs, segments$TotalActivity, method = "pearson")
    cor.test(segments$numberCSObs, segments$numberProfObs, method = "pearson")
    

    
#### Results 3.3 - Trail segments: prep model covariates ####

  ## ~~~ FACILITIES ~~~ ###
  
  dist<- st_nearest_feature(segments, facilities)
  dist2<- st_distance(segments, facilities[dist,], by_element=TRUE)
  segments$facilities.dist<- as.vector(dist2)
  hist(segments$facilities.dist)
  
  
  ## ~~~ ACCESS ~~~ ##
  
  dist<- st_nearest_feature(segments, access)
  dist2<- st_distance(g, access[dist,], by_element=TRUE)
  segments$access.dist<- as.vector(dist2)
  hist(segments$access.dist)
  
  
  ## ~~~ LAND COVER (length; not used directly in model, is just to set up following sections) ~~~ ##
  
  # Each segment is here labeled (*in a separate row*) with each artype that it crosses
  segments.ar5<- st_intersection(segments, ar5_2)
  segments.ar5$length<- as.vector(st_length(segments.ar5)) # units: m^2
  
  # Segments are here summarized by the total length of each artype present in the segment
  check<- ddply(segments.ar5, c("strava.id", "artype"), summarize,
                length = as.vector(sum(length)))
  
  # Length-based measures for land cover types of interest
  
  cultiv<- check[check$artype == "cultivated" | check$artype == "grazing",]
  devel<- check[check$artype == "developed",]
  transport<- check[check$artype == "transportation",]
  mire<- check[check$artype == "mire",]
  forest<- check[check$artype == "forest",]
  

  check<- ddply(cultiv, c("strava.id"), summarize,
                cultivated.length = as.vector(sum(length)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  
  check<- ddply(devel, c("strava.id"), summarize,
                developed.length = as.vector(sum(length)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  check<- ddply(mire, c("strava.id"), summarize,
                mire.length = as.vector(sum(length)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  check<- ddply(forest, c("strava.id"), summarize,
                forest.length = as.vector(sum(length)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$cultivated.length<- mapvalues(segments$cultivated.length, from = NA, to = 0)
  segments$developed.length<- mapvalues(segments$developed.length, from = NA, to = 0)
  segments$mire.length<- mapvalues(segments$mire.length, from = NA, to = 0)
  segments$forest.length<- mapvalues(segments$forest.length, from = NA, to = 0)
  
  
  ## ~~~ MAIN PATH ~~~ ##
  
  check<- ddply(transport, c("strava.id"), summarize,
                transport.length = as.vector(sum(length)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$transport.ratio<- segments$transport.length/segments$length
  
  
  ## ~~~ WATER ~~~ ##
  
  water<- ar5[ar5_2$artype== "freshwater",]
  
  # Calculate distances
  
  dist<- st_nearest_feature(segments, water)
  dist2<- st_distance(segments, water[dist,], by_element=TRUE)
  segments$water.dist<- as.vector(dist2)
  hist(segments$water.dist)
  
  
  ## ~~~ ELEVATION ~~~ ##
  
  segments.elev<- st_intersection(segments, elevation.pol)
  segments.elev$length<- as.vector(st_length(segments.elev))
  
  check<- ddply(segments.elev, c("strava.id"), summarize,
                elevation.max = max(elevation))
  
  segments<- left_join(segments, check, by = "strava.id")
  hist(segments$elevation.max)
  
  
  ## ~~~ CARDINAL DIRECTIONS ~~~ ##
  
  c<- st_centroid(segments)
  coords<- st_coordinates(c)
  coords<- data.frame(coords)
  
  segments$eastness<- coords$X
  
  
  ## ~~~ LAND COVER ~~~ ##
  
  
  seg_buffer<- st_buffer(segments, dist = 150)
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = seg_buffer)
  
  seg_buffer.ar5<- st_intersection(seg_buffer, ar5_2)
  seg_buffer.ar5$area<- as.vector(st_area(seg_buffer.ar5))
  
  seg_buffer.artypes<- ddply(seg_buffer.ar5, c("strava.id", "artype"), summarize,
                             area = as.vector(sum(area)))
  
  
  # Cultivated
  cultiv<- seg_buffer.artypes[seg_buffer.artypes$artype == "cultivated" |
                                seg_buffer.artypes$artype == "grazing",]
  
  check<- ddply(cultiv, c("strava.id"), summarize,
                buff.cultivated.area = as.vector(sum(area)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$buff.cultivated.area<- mapvalues(segments$buff.cultivated.area, from = NA, to = 0)
  
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = segments[segments$buff.cultivated.area == 0,], color = "lightgrey") +
    geom_sf(data = segments[segments$buff.cultivated.area > 0,], aes(color = buff.cultivated.area), lwd = 1.5)
  
  
  
  # Developed
  devel<- seg_buffer.artypes[seg_buffer.artypes$artype == "developed" |
                               seg_buffer.artypes$artype == "transportation",]
  
  check<- ddply(devel, c("strava.id"), summarize,
                buff.developed.area = as.vector(sum(area)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$buff.developed.area<- mapvalues(segments$buff.developed.area, from = NA, to = 0)
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = segments[segments$buff.developed.area == 0,], color = "lightgrey") +
    geom_sf(data = segments[segments$buff.developed.area > 0,], aes(color = buff.developed.area), lwd = 1.5)
  
  
  # Forest
  forest<- seg_buffer.artypes[seg_buffer.artypes$artype == "forest",]
  
  check<- ddply(forest, c("strava.id"), summarize,
                buff.forest.area = as.vector(sum(area)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$buff.forest.area<- mapvalues(segments$buff.forest.area, from = NA, to = 0)
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = segments[segments$buff.forest.area == 0,], color = "lightgrey") +
    geom_sf(data = segments[segments$buff.forest.area > 0,], aes(color = buff.forest.area), lwd = 1.5)
  
  
  # Mire
  mire<- seg_buffer.artypes[seg_buffer.artypes$artype == "mire",]
  
  check<- ddply(mire, c("strava.id"), summarize,
                buff.mire.area = as.vector(sum(area)))
  
  segments<- left_join(segments, check, by = "strava.id")
  
  segments$buff.mire.area<- mapvalues(segments$buff.mire.area, from = NA, to = 0)
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = segments[segments$buff.mire.area == 0,], color = "lightgrey") +
    geom_sf(data = segments[segments$buff.mire.area > 0,], aes(color = buff.mire.area), lwd = 1.5)
  
  
  # areas for standardization
  
  seg_buffer$area<- st_area(seg_buffer)
  hist(seg_buffer$area)
  
  colnames(seg_buffer)
  
  areas<- seg_buffer[,c(2,28)]
  
  areas$geom<- NULL
  areas$area<- as.vector(areas$area)
  
  segments<- left_join(segments, areas, by = "strava.id")
  
  ggplot() +
    geom_sf(data = bymarka) +
    geom_sf(data = seg_buffer, aes(fill = area))
  
  
  ## Standardize
  segments$st.cultivated.area<- segments$buff.cultivated.area/segments$area
  segments$st.developed.area<- segments$buff.developed.area/segments$area
  segments$st.forest.area<- segments$buff.forest.area/segments$area
  segments$st.mire.area<- segments$buff.mire.area/segments$area
  
  range(segments$st.cultivated.area)
  range(segments$st.developed.area)
  range(segments$st.mire.area)
  range(segments$st.forest.area)
  
  
  
  
  ## ~~ Standardize response and covariates to segment length ~~ ##
  
  # Responses
  segments$st_numberCSEvents<- as.integer(ceiling((segments$numberCSEvents/segments$length)*mean(segments$length)))
  segments$st_numberCSObs<- as.integer(ceiling((segments$numberCSObs/segments$length)*mean(segments$length)))
  segments$st_numberProfEvents<- as.integer(ceiling((segments$numberProfEvents/segments$length)*mean(segments$length)))
  segments$st_numberProfObs<- as.integer(ceiling((segments$numberProfObs/segments$length)*mean(segments$length)))
  segments$TotalActivity
  

  ## Make sure no NAs
  segments$st_numberCSEvents<- mapvalues(segments$st_numberCSEvents, from = NA, to = 0)
  segments$st_numberCSObs<- mapvalues(segments$st_numberCSObs, from = NA, to = 0)
  segments$st_numberProfEvents<- mapvalues(segments$st_numberProfEvents, from = NA, to = 0)
  segments$st_numberProfObs<- mapvalues(segments$st_numberProfObs, from = NA, to = 0)
  segments$TotalActivity<- mapvalues(segments$TotalActivity, from = NA, to = 0)
  
  
  segments$access.dist<- mapvalues(segments$access.dist, from = NA, to = 0)
  segments$facilities.dist<- mapvalues(segments$facilities.dist, from = NA, to = 0)
  segments$elevation.max<- mapvalues(segments$elevation.max, from = NA, to = 0)
  segments$eastness<- mapvalues(segments$eastness, from = NA, to = 0)
  segments$transport.ratio<- mapvalues(segments$transport.ratio, from = NA, to = 0)
  segments$transport.ratio<- mapvalues(segments$transport.ratio, from = NA, to = 0)

  

#### Results 3.3 - Citizen science and Strava activity along trail segments: models ####

  
  ## ~~ MODELS ~~ ##
  
  memory.limit(size = 25000)
  

  ## ~~ CITIZEN SCIENCE ~~ ##
  
  table(segments$st_numberCSObs)
  segments2<- segments[segments$st_numberCSObs < 2000,]
  
  c<- st_centroid(segments2)
  coords<- st_coordinates(c)
  
  ac<- autocov_dist(segments2$st_numberCSObs, coords, nbs = 750)
  segments2$ac<- ac
  
  citsci.ac<- glmulti(st_numberCSObs ~
                      access.dist + transport.ratio + eastness +
                      facilities.dist + elevation.max + st.mire.area + st.forest.area +
                        st.developed.area + st.cultivated.area + water.dist + ac,
                    data = segments2,
                    level = 1,
                    fitfunction = glm.nb,
                    crit="aicc",
                    confsetsize=2048)
  
  
  moran.test(residuals.glm(citsci.ac@objects[[1]]),
             nb2listw(tri2nb(coords)))
  
  print(citsci.ac)
 
  top <- weightable(citsci.ac)
  top <- top[top$aicc <= min(top$aicc) + 2,]
  top     
  
  plot(citsci.ac, type = "p")
  plot(citsci.ac, type = "s")
  
  eval(metafor:::.glmulti)
  coef(citsci.ac)
  
  mmi <- as.data.frame(coef(citsci.ac))
  mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond), Importance=mmi$Importance, row.names=row.names(mmi))
  mmi$z <- mmi$Estimate / mmi$SE
  mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
  names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
  mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
  mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
  mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
  
  mmi[,c(1,2,7)]
  
  hist(segments2$st_forest.length)
  
  r2(citsci.ac@objects[[1]])
  

  ## Check - no major correlations
  
    ch<- (segments[,c("access.dist", "transport.ratio", "eastness",
                      "facilities.dist", "elevation.max", "st.mire.area", "st.forest.area",
                      "st.developed.area", "st.cultivated.area", "water.dist")])
  
    ch$geom<- NULL
  
    cor(ch)
    
  
  
  
  ## ~~ VISUALIZATIONS: CITIZEN SCIENCE MODELS ~~ ##
  
  paletteer_c("grDevices::Viridis", 30)
    

  ## st.forest.area ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "st.forest.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "st.forest.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "st.forest.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "st.forest.area", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(st.forest.area, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Forest") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.9999") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.mire.area ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "st.mire.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "st.mire.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "st.mire.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "st.mire.area", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(st.mire.area, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Wetland") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.9840") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## transport.ratio ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "transport.ratio", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "transport.ratio", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "transport.ratio", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "transport.ratio", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(transport.ratio, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Main route") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.9267") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.developed.area
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "st.developed.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "st.developed.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "st.developed.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "st.developed.area", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(st.developed.area, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Developed") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.8364") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
 
  ## elevation.max ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "elevation.max", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "elevation.max", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "elevation.max", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "elevation.max", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(elevation.max, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Elevation") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.7575") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  
  ## facilities.dist ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "facilities.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "facilities.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "facilities.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "facilities.dist", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data2,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(facilities.dist, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Facilities") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.7045") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.cultivated.area ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "st.cultivated.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "st.cultivated.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "st.cultivated.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "st.cultivated.area", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data1,data3,data4)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 3", "Model 4"))
  
  ggplot(cdata, aes(st.cultivated.area, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#00558A","#007395")) +
    scale_fill_manual(values = c("#4A0A5D","#00558A","#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Cultivated") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.5258") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## water.dist ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "water.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "water.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "water.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "water.dist", interval = TRUE)
  data4$model <- "Model 4"
  
  
  cdata <- bind_rows(data3)
  cdata$model<- factor(cdata$model, levels = c("Model 3"))
  
  ggplot(cdata, aes(water.dist, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.07) +
    scale_color_manual(values = c("#00558A")) +
    scale_fill_manual(values = c("#00558A")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Water") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.3156") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
    
  
  
  ## eastness ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "eastness", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "eastness", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "eastness", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "eastness", interval = TRUE)
  data4$model <- "Model 4"
  
  
  ## access.dist ##
  
  data1 <- make_predictions(citsci.ac@objects[[1]], pred = "access.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(citsci.ac@objects[[2]], pred = "access.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(citsci.ac@objects[[3]], pred = "access.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(citsci.ac@objects[[4]], pred = "access.dist", interval = TRUE)
  data4$model <- "Model 4"
  
  cdata <- bind_rows(data4)
  cdata$model<- factor(cdata$model, levels = c("Model 4"))
  
  ggplot(cdata, aes(access.dist, st_numberCSObs, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.07) +
    scale_color_manual(values = c("#007395")) +
    scale_fill_manual(values = c("#007395")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Access") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.2725") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  
  ## ~~ STRAVA ~~ ##
  
  
  c<- st_centroid(segments)
  coords<- st_coordinates(c)
  
  ac<- autocov_dist(segments$TotalActivity, coords, nbs = 750)
  segments3<- segments
  segments3$ac<- ac
  
  strava.ac<- glmulti(TotalActivity ~
                        access.dist + transport.ratio + eastness +
                        facilities.dist + elevation.max + st.mire.area + st.forest.area +
                        st.developed.area + st.cultivated.area + water.dist + ac,
                      data = segments3,
                      level = 1,
                      fitfunction = glm.nb,
                      crit="aicc",
                      confsetsize=2048)
  
  moran.test(residuals.glm(strava.ac@objects[[1]]),
             nb2listw(tri2nb(coords)))
  
  print(strava.ac)

  top <- weightable(strava.ac)
  top <- top[top$aicc <= min(top$aicc) + 2,]
  top     
  
  plot(strava.ac, type = "p")
  plot(strava.ac, type = "s")
  
  eval(metafor:::.glmulti)
  coef(strava.ac)
  
  mmi <- as.data.frame(coef(strava.ac))
  mmi <- data.frame(Estimate=mmi$Est, SE=sqrt(mmi$Uncond), Importance=mmi$Importance, row.names=row.names(mmi))
  mmi$z <- mmi$Estimate / mmi$SE
  mmi$p <- 2*pnorm(abs(mmi$z), lower.tail=FALSE)
  names(mmi) <- c("Estimate", "Std. Error", "Importance", "z value", "Pr(>|z|)")
  mmi$ci.lb <- mmi[[1]] - qnorm(.975) * mmi[[2]]
  mmi$ci.ub <- mmi[[1]] + qnorm(.975) * mmi[[2]]
  mmi <- mmi[order(mmi$Importance, decreasing=TRUE), c(1,2,4:7,3)]
  
  mmi[,c(1,2,7)]
  
  
  ## ~~ VISUALIZE STRAVA ~~ ##
  
  ## st.mire.area ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "st.mire.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "st.mire.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "st.mire.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "st.mire.area", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "st.mire.area", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "st.mire.area", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "st.mire.area", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "st.mire.area", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "st.mire.area", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "st.mire.area", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "st.mire.area", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "st.mire.area", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data11,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 9", "Model 10", "Model 11", "Model 12"))
  
  ggplot(cdata, aes(st.mire.area, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Wetland") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 1.0000") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## transport.ratio ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "transport.ratio", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "transport.ratio", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "transport.ratio", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "transport.ratio", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "transport.ratio", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "transport.ratio", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "transport.ratio", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "transport.ratio", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "transport.ratio", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "transport.ratio", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "transport.ratio", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "transport.ratio", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data11,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 9", "Model 10", "Model 11", "Model 12"))
  
  ggplot(cdata, aes(transport.ratio, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Main route") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 1.0000") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  
  ## elevation.max ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "elevation.max", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "elevation.max", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "elevation.max", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "elevation.max", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "elevation.max", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "elevation.max", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "elevation.max", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "elevation.max", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "elevation.max", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "elevation.max", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "elevation.max", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "elevation.max", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data11,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 9", "Model 10", "Model 11", "Model 12"))
  
  ggplot(cdata, aes(elevation.max, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Elevation") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 1.0000") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.developed.area ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "st.developed.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "st.developed.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "st.developed.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "st.developed.area", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "st.developed.area", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "st.developed.area", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "st.developed.area", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "st.developed.area", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "st.developed.area", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "st.developed.area", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "st.developed.area", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "st.developed.area", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data11,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 9", "Model 10", "Model 11", "Model 12"))
  
  ggplot(cdata, aes(st.developed.area, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#00C377","#5CCE64","#92D74D","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Developed area") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.9999") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  

  ## facilities.dist ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "facilities.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "facilities.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "facilities.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "facilities.dist", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "facilities.dist", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "facilities.dist", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "facilities.dist", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "facilities.dist", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "facilities.dist", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "facilities.dist", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "facilities.dist", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "facilities.dist", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data5,data6,data7,data8,data10,data11)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 10", "Model 11"))
  
  ggplot(cdata, aes(facilities.dist, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#5CCE64","#92D74D")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#5CCE64","#92D74D")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Facilities") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.6626") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.forest.area ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "st.forest.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "st.forest.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "st.forest.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "st.forest.area", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "st.forest.area", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "st.forest.area", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "st.forest.area", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "st.forest.area", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "st.forest.area", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "st.forest.area", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "st.forest.area", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "st.forest.area", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 7", "Model 8",
                                               "Model 9", "Model 10", "Model 12"))
  
  ggplot(cdata, aes(st.forest.area, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#009F94","#00A790","#00B686",
                                  "#00C377","#5CCE64","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#009F94","#00A790","#00B686",
                                 "#00C377","#5CCE64","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Forest area") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.6590") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))


  ## access.dist ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "access.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "access.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "access.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "access.dist", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "access.dist", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "access.dist", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "access.dist", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "access.dist", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "access.dist", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "access.dist", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "access.dist", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "access.dist", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data4,data5,data6,data8,data9,data11,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 4",
                                               "Model 5", "Model 6", "Model 8",
                                               "Model 9", "Model 11", "Model 12"))
  
  ggplot(cdata, aes(access.dist, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#007395",
                                  "#008F97","#009F94","#00B686",
                                  "#00C377","#92D74D","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#007395",
                                 "#008F97","#009F94","#00B686",
                                 "#00C377","#92D74D","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Access") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.6008") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))

  
  
  ## water.dist ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "water.dist", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "water.dist", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "water.dist", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "water.dist", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "water.dist", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "water.dist", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "water.dist", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "water.dist", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "water.dist", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "water.dist", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "water.dist", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "water.dist", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data3,data4,data5,data6,data9,data10,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 3", "Model 4",
                                               "Model 5", "Model 6", "Model 9",
                                               "Model 10", "Model 12"))
  
  ggplot(cdata, aes(water.dist, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#00558A","#007395",
                                  "#008F97","#009F94","#00B686",
                                  "#5CCE64","#C0DE35")) +
    scale_fill_manual(values = c("#4A0A5D","#00558A","#007395",
                                 "#008F97","#009F94","#00B686",
                                 "#5CCE64","#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Water") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.5969") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## st.cultivated.area ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "st.cultivated.area", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "st.cultivated.area", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "st.cultivated.area", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "st.cultivated.area", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "st.cultivated.area", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "st.cultivated.area", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "st.cultivated.area", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "st.cultivated.area", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "st.cultivated.area", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "st.cultivated.area", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "st.cultivated.area", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "st.cultivated.area", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data1,data2,data3,data4,data5,data7,data9)
  cdata$model<- factor(cdata$model, levels = c("Model 1", "Model 2", "Model 3", "Model 4",
                                               "Model 5", "Model 7",
                                               "Model 9"))
  
  ggplot(cdata, aes(st.cultivated.area, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                  "#008F97","#00A790",
                                  "#00C377")) +
    scale_fill_manual(values = c("#4A0A5D","#3D3576","#00558A","#007395",
                                 "#008F97","#00A790",
                                 "#00C377")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Cultivated area") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.5346") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  ## eastness ##
  
  data1 <- make_predictions(strava.ac@objects[[1]], pred = "eastness", interval = TRUE)
  data1$model <- "Model 1"
  data2 <- make_predictions(strava.ac@objects[[2]], pred = "eastness", interval = TRUE)
  data2$model <- "Model 2"
  data3 <- make_predictions(strava.ac@objects[[3]], pred = "eastness", interval = TRUE)
  data3$model <- "Model 3"
  data4 <- make_predictions(strava.ac@objects[[4]], pred = "eastness", interval = TRUE)
  data4$model <- "Model 4"
  data5 <- make_predictions(strava.ac@objects[[5]], pred = "eastness", interval = TRUE)
  data5$model <- "Model 5"
  data6 <- make_predictions(strava.ac@objects[[6]], pred = "eastness", interval = TRUE)
  data6$model <- "Model 6"
  data7 <- make_predictions(strava.ac@objects[[7]], pred = "eastness", interval = TRUE)
  data7$model <- "Model 7"
  data8 <- make_predictions(strava.ac@objects[[8]], pred = "eastness", interval = TRUE)
  data8$model <- "Model 8"
  data9 <- make_predictions(strava.ac@objects[[9]], pred = "eastness", interval = TRUE)
  data9$model <- "Model 9"
  data10 <- make_predictions(strava.ac@objects[[10]], pred = "eastness", interval = TRUE)
  data10$model <- "Model 10"
  data11 <- make_predictions(strava.ac@objects[[11]], pred = "eastness", interval = TRUE)
  data11$model <- "Model 11"
  data12 <- make_predictions(strava.ac@objects[[12]], pred = "eastness", interval = TRUE)
  data12$model <- "Model 12"
  
  cdata <- bind_rows(data4,data5,data12)
  cdata$model<- factor(cdata$model, levels = c("Model 4",
                                               "Model 5",
                                               "Model 12"))
  
  ggplot(cdata, aes(eastness, TotalActivity, group = model)) +
    stat_smooth(aes(col = model), lwd = 1.3, alpha = 0.8) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax, fill = model), alpha = 0.05) +
    scale_color_manual(values = c("#007395",
                                  "#008F97",
                                  "#C0DE35")) +
    scale_fill_manual(values = c("#007395",
                                 "#008F97",
                                 "#C0DE35")) +
    theme_bw() +
    theme(axis.text = element_text(size = 16)) +
    theme(axis.title = element_text(size = 18)) +
    xlab("Longitude") +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "none") +
    ggtitle("Variable Importance = 0.4080") +
    theme(plot.title = element_text(hjust = 0.5, size = 20))
  
  
  
#### Results 3.3 Figure: Segment map of citizen science and Strava data ####
  
  # Citizen science
  
  table(segments$numberCSObs)
  
  paletteer_dynamic("cartography::turquoise.pal", 12)

  ggplot() +
    geom_sf(data = bymarka, fill = "grey99") +
    geom_sf(data = segments[segments$numberCSObs == 0,], color = "grey60", lwd = 1) +
    geom_sf(data = segments[segments$numberCSObs > 0,], aes(color = log(numberCSObs)), lwd = 1.6) +
    scale_color_gradient(low = "#92BEAB", high = "#080E5B") +
    theme_minimal()
  

  # Strava    
  
  ggplot() +
    geom_sf(data = bymarka, fill = "grey99") +
    geom_sf(data = segments[segments$TotalActivity == 0,], color = "grey60", lwd = 1) +
    geom_sf(data = segments[segments$TotalActivity > 0,], aes(color = log(TotalActivity)), lwd = 1.6) +
    scale_color_gradient(low = "#92BEAB", high = "#080E5B") +
    theme_minimal()
  

  
  
  
  
#### Methods figures - Figure 2: summary information about data ####
  

  ## ~~ Fig 2a: Observations by taxonomic groups by data source ~~ ##
  
  
    CITSCI.OBS$tally<- c(1:44206)
  
    cs.taxa<- ddply(CITSCI.OBS, c("taxonomic"), summarize,
                    count = sum(tally))
    
    PROF.OBS$tally<- c(1:2059)
    prof.taxa<- ddply(PROF.OBS, c("taxonomic"), summarize,
                      count = sum(tally))
    
    cs.taxa$ratio<- cs.taxa$count/sum(cs.taxa$count)
    prof.taxa$ratio<- prof.taxa$count/sum(prof.taxa$count)
    
    cs.taxa$source<- rep("cs", times = 7)
    prof.taxa$source<- rep("prof", times = 5)
    cs.taxa<- cs.taxa[1:6,]
    
    taxa.fig<- rbind(cs.taxa, prof.taxa)
    
    taxa.fig<- rbind(taxa.fig, c("Mammals",1,0,"prof"))
    
    taxa.fig$count<- as.numeric(taxa.fig$count)
    taxa.fig$ratio<- as.numeric(taxa.fig$ratio)
    
    ggplot() +
      geom_col(data = taxa.fig, aes(x = taxonomic, y = log(count), fill = source), position = "dodge", width = 0.8) +
      theme(text = element_text(size = 15)) +
      theme(legend.position = "none") +
      scale_fill_manual(values = c("#008F97", "#234B84")) +
      theme_bw()
    
    
  ## ~~ Fig 2b: Species by taxonomic group by data source ~~ ##
  
  prof.species<- ddply(PROF.OBS, c("taxonomic"), summarize,
                       speciescount = length(unique(species)))
  
  prof.species$ratio<- prof.species$speciescount/sum(prof.species$speciescount)
  
  cs.species<- ddply(CITSCI.OBS, c("taxonomic"), summarize,
                     speciescount = length(unique(species)))
  cs.species<- cs.species[1:6,]
  
  cs.species$ratio<- cs.species$speciescount/sum(cs.species$speciescount)
  
  cs.species$source<- rep("cs", times = 6)
  prof.species$source<- rep("prof", times = 5)
  
  species.fig<- rbind(cs.species, prof.species)
  species.fig<- rbind(species.fig, c("Mammals",0,0,"prof"))
  
  species.fig$speciescount<- as.numeric(species.fig$speciescount)
  
  ggplot() +
    geom_col(data = species.fig, aes(x = taxonomic, y = speciescount, fill = source), position = "dodge", width = 0.8) +
    theme(text = element_text(size = 15)) +
    theme(legend.position = "none") +
    scale_fill_manual(values = c("#008F97", "#234B84")) +
    theme_bw()
  
  
  ## ~~ Month of observation by data source ~~ ##
  
    cs.season<- ddply(CITSCI.OBS, c("month"), summarize,
                      count = sum(tally))
    
    prof.season<- ddply(PROF.OBS, c("month"), summarize,
                        count = sum(tally))
    
    cs.season$source<- rep("cs", times = 13)
    prof.season$source<- rep("prof", times = 13)
    
    cs.season<- cs.season[1:12,]
    prof.season<- prof.season[1:12,]
    
    cs.season$ratio<- cs.season$count/sum(cs.season$count)
    prof.season$ratio<- prof.season$count/sum(prof.season$count)
    
    seasons.fig<- rbind(cs.season, prof.season)
    
    ggplot() +
      geom_col(data = seasons.fig, aes(x = month, y = ratio, fill = source), position = "dodge", width = 0.8) +
      theme(text = element_text(size = 15)) +
      theme(legend.position = "none") +
      scale_fill_manual(values = c("#008F97", "#234B84")) +
      theme_bw()
  
  
  ## ~~ Land cover of observations by data source ~~ ##
  
    cs.land<- ddply(CITSCI.OBS, c("artype"), summarize,
                    count = sum(tally))
    
    prof.land<- ddply(PROF.OBS, c("artype"), summarize,
                      count = sum(tally))
    
    cs.land$source<- rep("cs", times = 8)
    prof.land$source<- rep("prof", times = 7)
    
    cs.land<- cs.land[1:7,]
    
    cs.land$ratio<- cs.land$count/sum(cs.land$count)
    prof.land$ratio<- prof.land$count/sum(prof.land$count)
    
    ar5_3<- ar5_2
    ar5_3$artype<- mapvalues(ar5_3$artype, from = c("grazing","transportation"), to = c("cultivated","developed"))
    
    avail.land<- ddply(ar5_3, c("artype"), summarize,
                       count = sum(area))
    
    avail.land$ratio<- avail.land$count/sum(avail.land$count)
    
    avail.land$source<- rep("total", times = 7)
    
    land.fig<- rbind(cs.land, prof.land, avail.land)
    
   
    ggplot() +
      geom_col(data = land.fig, aes(x = artype, y = ratio, fill = source), position = "dodge", width = 0.8) +
      theme(text = element_text(size = 15)) +
      #theme(legend.position = "none") +
      scale_fill_manual(values = c("#008F97", "#234B84", "grey60")) +
      theme_bw()
  
 
    
  
  
  
  
  
