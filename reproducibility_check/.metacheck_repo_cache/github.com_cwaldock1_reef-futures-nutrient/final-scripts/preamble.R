# read in all extra objects to run results scripts

op_sys <- ifelse(Sys.info()['sysname'] == 'Windows', 'Windows', 'Mac')

# libraries ----

my_packages <-  c('tidyverse', 'plyr', 'raster', 'sp', 'sf','tmap', 'tmaptools', 'scico', 'ggExtra',
                  'factoextra', 'FactoMineR', 'corrplot', 'matrixStats', 'ggrepel', 'GGally', 'ncdf4', 
                  'scales')
not_installed <- my_packages[!(my_packages %in% installed.packages()[ , 'Package'])]   
if(length(not_installed)) install.packages(not_installed)  
lapply(my_packages, function(x) library(x, character.only = T))

# functions ----

# source in functions for plotting
source('scripts/results-final/results-functions/xyz_plot.R')

# diverging colours ----

red2  <- rgb(103,   0,  31, maxColorValue = 255)
red1  <- rgb(244, 165, 130, maxColorValue = 255)
mid   <- rgb(247, 247, 247, maxColorValue = 255)
blue1 <- rgb(146, 197, 222, maxColorValue = 255)
blue2 <- rgb(5,    48, 97, maxColorValue = 255)


# global grid ----

# read in global grid 
global_grid <- raster('processed-data/environmental-data/environmental_grid/global_mask_v2.nc')

# convert values
global_grid[is.na(global_grid)]=0
global_grid[global_grid!=0]=NA

# Get the global grid for joining
global_grid_JOIN <- raster('processed-data/environmental-data/environmental_grid/global_mask_v2.nc')
global_grid_JOIN[global_grid_JOIN!=2]=NA
global_grid_JOIN[global_grid_JOIN==2]=0

# Get the global points for joining
global_points <- data.frame(rasterToPoints(global_grid_JOIN))[,1:2]
global_points$cell   <- as.numeric(cellFromXY(global_grid_JOIN, global_points[,1:2]))

# coastline ----

# define a coastline polygon
if(op_sys == 'Mac'){coastlines <- rgdal::readOGR(dsn = '/Volumes/RF-env-data/reef-futures/env-data/gshhg-shp-2.3.7/GSHHS_shp/l/GSHHS_l_L1.shp')}
if(op_sys == 'Windows'){coastlines <- read_sf(dsn = 'E:/reef-futures/env-data/gshhg-shp-2.3.7/GSHHS_shp/l/GSHHS_l_L1.shp')}


# countries polygon ----

# countries polygon and simplification for extractions
# Read in country information and convert to line strings for extraction of biomass from rasters 
if(op_sys == 'Mac'){countries <- read_sf('/Volumes/RF-env-data/reef-futures/env-data/gadm36_levels_shp/gadm36_0.shp')}
if(op_sys == 'Windows'){countries <- read_sf('E:/reef-futures/env-data/gadm36_levels_shp/gadm36_0.shp')}

# Simplify
countries_simple <- st_simplify(countries, dTolerance = 0.1) 
# Convert to line object
countries_line   <- st_cast(countries_simple, "MULTILINESTRING")
# Remove empty countries
countries_line   <- countries_line[!st_is_empty(countries_line), , drop=FALSE]


# socio-economic summaries per country ----
# Read in compilied socioeconomic information
social <- read_csv('processed-data/socio-economic-data/full-social-data.csv')

# ecoregion shapefiles ----

# read in ecoregion shapefiles
if(op_sys == 'Mac'){ECO <- sf::st_read('/Volumes/RF-env-data/reef-futures/env-data/Marine Ecoregions of the World/data/commondata/data0/meow_ecos_expl_clipped_expl.shp')}
if(op_sys == 'Windows'){ECO <- sf::st_read('E:/reef-futures/env-data/Marine Ecoregions of the World/data/commondata/data0/meow_ecos_expl_clipped_expl.shp')}
sf::sf_use_s2(FALSE)
ECO_simple <- st_simplify(ECO, dTolerance = 0.1) 
realm <- ECO_simple['REALM']
realm <- aggregate(realm, list(realm$REALM), FUN = mode)

# read in nutrient data ----

# read in nutrient data
nuts <- read.csv('processed-data/nutrient-content/Spp_NutrientPred_REEF_FUTURESJune2021.csv')

# select focal nutrients
focal_nuts <- c('Calcium_mu', 
                'Iron_mu', 
                'Vitamin_A_mu', 
                'Zinc_mu')

nuts <- nuts[,c('valid_name_FishBase', focal_nuts)]

# divide all by 100g to get amoung per g (same unit as biomass)
nuts[focal_nuts] <- nuts[focal_nuts]
nuts <- unique(nuts)

# read in lists of fished species
fished_list <- readRDS('processed-data/fisheries-data/fished_species_lists.RDS')

# read in species conservation traits ----
sp_conservation <- readRDS('processed-data/fisheries-data/species_conservation.RDS')

# identify species sensitive to conservation
keep_species <- sp_conservation %>% 
  filter(valid_name_FishBase %in% fished_list[['all_species']],
         !IUCN_category %in% c('CR', 'EN', 'NT', 'VU'), 
         Class_FishBase != 'Elasmobranchii') %>% 
  mutate(valid_name_FishBase = gsub(' ', '_', .$valid_name_FishBase))

# fished species list ----

fished_genus <- gsub(' ', '_', fished_list$fished_genus)
fished_genus <- fished_genus[which(fished_genus %in% keep_species$valid_name_FishBase)]

# estimate potential reef dependent countries ----

# estimate the reef associated nations 
reef_associated_nations <- social %>% 
  mutate(CoastalPopulationProportion = pop_coastal_2000 / pop_tot_2000) %>% 
  filter(CoastalPopulationProportion > 0.5 | is.na(CoastalPopulationProportion), 
         SeafoodPercentageAnimal     > 20  | is.na(SeafoodPercentageAnimal), 
         HDI_2019                    < 0.8 | is.na(HDI_2019),
         abs(latitude_mean) < 30, 
         # remove countries without coastline (lake coastal)
         !ISO_3_name %in% c('Bhutan', 
                            'Burundi', 
                            'Burkina Faso', 
                            'Congo (the Democratic Republic of the)',
                            'Ethiopia', 
                            "Lao People's Democratic Republic (the)", 
                            "Mali",  
                            'Malawi', 
                            'Niger (the)', 
                            'Nepal', 
                            'Paraguay', 
                            'Rwanda', 
                            'South Sudan', 
                            'Chad', 
                            'Uganda',
                            'Western Sahara',
                            'Zambia', 
                            'Taiwan (Province of China)'))


# get the grid cells that intersect the countries of interest
# filter to reef associated countries
# covert from full resolution to slightly simpler (but retaining all countries) and cast to line string
countries_ra <- countries %>% filter(GID_0 %in% reef_associated_nations$GID_0)
countries_ra <- st_simplify(countries_ra, dTolerance = 0.001)
countries_ra <- st_cast(countries_ra, "MULTILINESTRING")
countries_ra <- countries_ra[!st_is_empty(countries_ra), , drop=FALSE]
if(!file.exists('processed-data/socio-economic-data/country_cells.RDS')){
# extract the cells from lines
country_cells <- cellFromLine(global_grid, 
                              as_Spatial(countries_ra))
names(country_cells) <- countries_ra %>% filter(GID_0 %in% reef_associated_nations$GID_0) %>% .$GID_0
saveRDS(country_cells, file = 'processed-data/socio-economic-data/country_cells.RDS')
}else{
  country_cells <- readRDS(file = 'processed-data/socio-economic-data/country_cells.RDS')
}


# get the realm IDs of different reef associated countries ----

# define the realms of different countries
# plot realm information as a sanity check
# tm_shape(realm) + 
#   tm_polygons(col = 'Group.1')

# tropical focal countries
reef_associated_nations_sf <- countries_ra %>% 
  filter(GID_0 %in% reef_associated_nations$GID_0)

# get the realm for each country
reef_associated_nations_realm <- st_intersects(reef_associated_nations_sf, realm)

# compile country list for each realm
countries_realm <- apply(as.matrix(reef_associated_nations_realm), 2, function(x) reef_associated_nations_sf$GID_0[x])

# extract realms of interest
names(countries_realm) <- realm$Group.1
countries_realm <- countries_realm[lapply(countries_realm, length) > 2]
countries_realm <- lapply(countries_realm, function(x) data.frame(GID_0 = x))
countries_realm_df <- bind_rows(countries_realm, .id = 'REALM')

reef_associated_nations_sf <- left_join(reef_associated_nations_sf, countries_realm_df)

# tm_shape(na.omit(reef_associated_nations_sf)) + 
#   tm_lines(col = 'REALM')

# buffer the countries and get the cells that fall in each country ----

# here need to carefully check the link between country names and EEZs

if(op_sys == 'Mac'){eez <- read_sf('/Volumes/RF-env-data/reef-futures/env-data/World_EEZ_v11_20191118/eez_v11.shp')}
if(op_sys == 'Windows'){eez <- sf::st_read('E:/reef-futures/env-data/World_EEZ_v11_20191118/eez_v11.shp')}


# each country in our analysis should have a corresponding EEZ
eez_df <- eez %>%  dplyr::select(ISO_TER1, SOVEREIGN1, TERRITORY1)
ran_df <- reef_associated_nations %>% dplyr::select(ISO_3_name, ISO_3, GID_0)

# Join by territory field
eez_df <- left_join(eez_df, ran_df, by = c('ISO_TER1' = 'ISO_3')) %>% unique()
eez_missing <- eez_df %>% filter(is.na(ISO_3_name))
eez_df$ISO_3_name[is.na(eez_df$ISO_3_name)] <- eez_df$TERRITORY1[is.na(eez_df$ISO_3_name)]
eez_df <- eez_df %>% dplyr::rename(., ISO_3 = ISO_TER1)

if(!file.exists('processed-data/socio-economic-data/country_survey_cells.RDS')){

  eez_filter <- eez_df %>% filter(ISO_3 %in% na.omit(unique(reef_associated_nations$ISO_3)))

eez_0.01 <- st_simplify(eez_filter, dTolerance = 0.01, preserveTopology = T)

eez_0.01_no_holes <- nngeo::st_remove_holes(eez_0.01)
# tm_shape(eez_0.01_no_holes) + tm_polygons(col = 'GID_0')

eez_0.01_buffer <- st_buffer(eez_0.01_no_holes, 1)
# tm_shape(eez_0.01_buffer) + tm_polygons(col = 'GID_0')

country_survey_cells <- cellFromPolygon(global_grid, 
                                        as_Spatial(eez_0.01_buffer))

names(country_survey_cells) <- eez_0.01_buffer$GID_0

country_survey_cells <- tapply(country_survey_cells,names(country_survey_cells),FUN=function(x) unname(unlist(x)))

  saveRDS(country_survey_cells, file = 'processed-data/socio-economic-data/country_survey_cells.RDS')

  }else{
  
    country_survey_cells <- readRDS(file = 'processed-data/socio-economic-data/country_survey_cells.RDS')

  }

# get prevelence of indequate intake from focal countries ----

PII_countries <- social %>% 
  filter(GID_0 %in% reef_associated_nations$GID_0) %>% 
  summarise_at(., 
               .vars = c('Ca_prev', 'Iron_prev', 'VA_prev', 'Zinc_prev'), 
               mean, 
               na.rm = T)

PII_missing <- social %>% 
  filter(GID_0 %in% reef_associated_nations$GID_0) %>% 
  summarise_at(., 
               .vars = c('Ca_prev', 'Iron_prev', 'VA_prev', 'Zinc_prev'), 
               function(x) sum(!is.na(x)))


# save final image ----

save.image(file = 'scripts/results-final/01-main-analysis/preamble.RData')
