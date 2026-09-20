# Script to compare species interactions with measures of bird biodiversity.
# Author: Ilan Havinga.
# Date: February 2023.
# Note, please contact Dario Massimino at BTO for the bird density data. This script also requires the OS
# National Grids to be downloaded (https://github.com/OrdnanceSurvey/OS-British-National-Grids), 
# as well as population statistics from the respective statistical agencies.

# libraries

library(foreign)
library(classInt)
library(jsonlite)
library(fasterize)
library(raster)
library(mgcv)
library(stars)
library(scales)
library(viridis)
library(ggrepel)
library(cowplot)
library(lubridate)
library(sf)
library(tidyverse)
library(mapview)

source("./scripts/functions.R")

# options

gc()

gb_proj <- "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.06,0.15,0.247,0.842,-20.489 +units=m +no_defs"

############################################################################################################
# Load files.
############################################################################################################
# Admin boundaries

gb <- read_rds("./data/admin/boundaries/gb/gadm36_GBR_1_sf.rds") %>% 
  filter(NAME_1 %in% c("England", "Scotland", "Wales")) %>%
  st_transform(27700)

# Grids

os_1km_grid <- st_read("./data/grid/OS-British-National-Grids-main/os_bng_grids.gpkg", layer = "1km_grid") %>%
  rename(gridSquare = tile_name)

os_10km_grid <- st_read("./data/grid/OS-British-National-Grids-main/os_bng_grids.gpkg", layer = "10km_grid") %>%
  rename(gridSquare = tile_name)
os_10km_grid <- os_10km_grid[st_intersects(os_10km_grid, gb) %>% lengths > 0,]

# Bird densities.

bird_densities <- read_csv("./data/bio/gb/birds/bto/densities_years_2007-2009_A_to_K.csv") %>%
  left_join(read_csv("./data/bio/gb/birds/bto/densities_years_2007-2009_L_to_Y.csv") %>%
              select(-easting, -northing), by = "site")

letter_codes <- read_csv("./data/bio/gb/birds/bto/Two-letter-codes.csv")
bird_species_names <- letter_codes %>% filter(`BTO 2-letter code` %in% 
                                                colnames(bird_densities)[4:52])
bird_species_genera <- word(bird_species_names[,2] %>% pull(), 1) %>% unique()

# Flickr data.

gb_metadata_preds_beta01 <- read_rds("./data/flickr/gb/metadata/gb_metadata_preds_beta01.rds")

gb_preds_birds <- gb_metadata_preds_beta01 %>%
  filter(pred==1) %>%
  filter(entropy < 2.42) %>%
  filter(genus %in% bird_species_genera | family == "Apodidae" | family == "Hirundinidae") %>%
  filter(name != "Prunella vulgaris") %>% # shares genus name with Dunnock bird genus but is a plant
  filter(name != "Chloris cucullata") # shares name with Greenfinch genus but is a plant

# iNaturalist data.

obs_gb_birds <- read_rds("./data/inat/gb/metadata/obs_gb.rds") %>%
  filter(entropy < 2.42) %>%
  filter(pred_genus %in% bird_species_genera | pred_family == "Apodidae" | pred_family == "Hirundinidae") %>%
  filter(pred_name != "Prunella vulgaris") %>% # shares genus name with Dunnock bird genus but is a plant
  filter(pred_name != "Chloris cucullata") # shares name with Greenfinch genus but is a plant

# Population.

lsoa <- st_read("./data/admin/boundaries/gb/infuse_lsoa_lyr_2011/infuse_lsoa_lyr_2011.shp")
lsoa$area_km2 <- st_area(lsoa) %>% units::set_units(km^2) %>% unclass()

engw_pop <- read_csv("./data/admin/population/gb/SAPE22DT11-mid-2019-lsoa-population-density.csv",
                     skip = 4) %>%
  dplyr::select(lsoa = 1, pop =3)

sco_pop <- read_csv("./data/admin/population/gb/sape-19-all-tabs-and-figs_TabA.csv",
                    skip = 6, col_names = c("DataZone2011Code","Area name","Council area",
                                            "Total population","Population aged 65 and over",
                                            "Percentage of population aged 65 and over")) %>%
  dplyr::select(lsoa = 1, pop = 4)

############################################################################################################
# Standardise the intersection of the two datasets.
############################################################################################################

bird_pop <- colSums(bird_densities %>% select(B.:Y.)) %>% as_tibble(rownames = "species")

bird_species <- bird_species_names %>%
  rename(common_name=1, scientific_name=2, letter_code=3) %>%
  bind_cols(genus = word(bird_species_names[,2] %>% pull(), 1)) %>%
  left_join(bird_pop %>% rename(pop = value), by = c("letter_code"="species")) %>%
  rename(tax = genus) %>%
  mutate(tax = ifelse(tax == "Apus", "Apodidae", tax)) %>%
  mutate(tax = ifelse(tax == "Delichon", "Hirundinidae", tax)) %>%
  mutate(tax = ifelse(tax == "Hirundo", "Hirundinidae", tax)) %>%
  mutate(tax = ifelse(tax == "Phylloscopus", "Sylvia", tax)) %>%
  filter(!common_name %in% c("Linnet")) %>%
  filter(!common_name %in% c("Reed Bunting")) %>%
  filter(!common_name %in% c("Willow Warbler")) %>%
  filter(!common_name %in% c("Cuckoo"))

species_names <- bird_species %>% 
  group_by(tax) %>% 
  summarise(common_name = paste(common_name, collapse=", ")) %>%
  mutate(common_name = ifelse(common_name == "Blackbird, Mistle Thrush, Song Thrush", "Thrushes", common_name)) %>%
  mutate(common_name = ifelse(common_name == "Blackcap, Chiffchaff, Garden Warbler, Whitethroat", "Warblers", common_name)) %>%
  mutate(common_name = ifelse(common_name == "Stock Dove, Woodpigeon", "Pigeons",common_name)) %>%
  mutate(common_name = ifelse(common_name == "Carrion Crow, Jackdaw, Rook", "Crows",common_name))

gb_preds_birds <- gb_preds_birds %>% 
  mutate(tax = genus) %>%
  mutate(tax = ifelse(family == "Apodidae", "Apodidae", tax)) %>%
  mutate(tax = ifelse(family == "Hirundinidae", "Hirundinidae", tax)) %>%
  mutate(tax = ifelse(tax == "Phylloscopus", "Sylvia", tax)) %>%
  filter(!name %in% c("Emberiza cia", "Emberiza cirlus", "Emberiza elegans", "Emberiza melanocephala",
                      "Emberiza rustica")) %>%
  filter(!name %in% c("Falco columbarius", "Falco peregrinus", "Falco rusticolus")) %>%  # Kestrels that look too different
  filter(!name %in% c("Sitta carolinensis", "Falco peregrinus")) %>% # Nunhatchs that look too different (white) 
  filter(!name %in% c("Motacilla cinerea")) # Grey wagtail (yellow breast) too different

obs_gb_birds <- obs_gb_birds %>%
  mutate(tax = pred_genus) %>%
  mutate(tax = ifelse(pred_family == "Apodidae", "Apodidae", tax)) %>%
  mutate(tax = ifelse(pred_family == "Hirundinidae", "Hirundinidae", tax)) %>%
  mutate(tax = ifelse(tax == "Phylloscopus", "Sylvia", tax)) %>%
  filter(!pred_name %in% c("Emberiza cia", "Emberiza cirlus", "Emberiza elegans", "Emberiza melanocephala",
                      "Emberiza rustica")) %>%
  filter(!pred_name %in% c("Falco columbarius", "Falco peregrinus", "Falco rusticolus")) %>%  # Kestrels that look too different
  filter(!pred_name %in% c("Sitta carolinensis", "Falco peregrinus")) %>% # Nunhatchs that look too different (white) 
  filter(!pred_name %in% c("Motacilla cinerea")) # Grey wagtail (yellow breast) too different


############################################################################################################
# Plot total population versus species interactions on Flickr.
############################################################################################################
# Total.

bird_species_total <- bird_species %>%
  group_by(tax) %>%
  summarise(pop_total = sum(pop)) %>%
  left_join(species_names, by = "tax") %>%
  select(tax, common_name, pop_total) %>%
  left_join(gb_preds_birds %>%
              st_drop_geometry() %>% 
              group_by(tax) %>% 
              tally(name="flickr_total")) %>%
  left_join(tibble(
    tax = c("Aegithalos", "Alauda", "Anas", "Anthus", "Apodidae", "Buteo", "Carduelis", "Chloris",
            "Columba", "Corvus", "Cyanistes", "Hirundinidae", "Dendrocopos", "Emberiza","Erithacus",
            "Falco", "Fringilla", "Gallinula", "Garrulus", "Motacilla", "Numenius", "Parus", "Passer",
            "Periparus", "Pica", "Picus", "Prunella", "Pyrrhula", "Regulus", "Sitta",
            "Streptopelia", "Sturnus", "Sylvia", "Troglodytes", "Turdus", "Vanellus"),
    status = c("green", "red", "amber", "amber", "red", "green", "green", "red",
               "amber", "green/amber", "green", "green/red", "green","red", "green",
               "amber", "green", "amber", "green", "green", "red", "green", "red",
               "green", "green", "green", "amber", "amber", "green", "green",
               "green", "red", "green/amber", "amber", "green/amber/red", "red") # according to BTO website.
  ), by = "tax") %>%
  mutate(status = ifelse(status %in% c("green/amber","green/amber/red","green/red"), "amber", status)) %>%
  mutate(status = factor(status, levels = c("green","amber","red")))

# Plot.

pop_comp <- ggplot(bird_species_total %>%
         mutate(pop_total = log10(pop_total)) %>%
         mutate(flickr_total = log10(flickr_total)),
         aes(x=pop_total, y=flickr_total)) +
  stat_summary(fun.data=mean_cl_normal) +
  geom_smooth(method='lm', formula= y~x, colour = "darkgrey", fill="lightgrey") +
  geom_point(aes(colour=status), size =5) +
  geom_text_repel(aes(label = common_name), size=5) +
  scale_colour_manual(values = c("darkgreen", "orange", "red"), 
                      labels = c("Green", "Amber", "Red")) +
  labs(x = "Species population (log10)", y = "Species interactions (log10)", colour = "Status") +
  theme_bw() +
  theme(legend.title = element_text(size=17),
        legend.text = element_text(size = 15),
        axis.text = element_text(size = 14),
        axis.title.x = element_text(size = 17, vjust = -0.5),
        axis.title.y = element_text(size = 17, vjust = 2.5),
        plot.margin = unit(c(0.3,0.3,0.3,0.3), "cm"),
        panel.grid.major = element_line(size = 1))

ggsave(path='./data/figures/',filename='flickr_pop.png',device='png',
       width=12, height=7.75, dpi=300, bg="white")  

# Linear model.

summary(lm(log(bird_species_total$pop_total)~log(bird_species_total$flickr_total)))
summary(lm(log(bird_species_total$pop_total)~log(bird_species_total$flickr_total) + bird_species_total$status))

############################################################################################################
# Calculate species richness using BTO data.
############################################################################################################
# Generate bird density grid with selected species.

os_1km_grid_bto <- os_1km_grid %>%
  inner_join(bird_densities, by = c("gridSquare" = "site")) %>%
  select(gridSquare, bird_species$letter_code) %>%
  st_drop_geometry() %>%
  pivot_longer(cols=B.:Y., names_to = "letter_code") %>% # pivot longer to attach taxonomic grouping
  left_join(bird_species %>% select(letter_code, tax), by = "letter_code") %>%
  group_by(gridSquare, tax) %>%
  summarise(density = sum(value)) %>% # ...and then summarise densities per grouping..
  ungroup() %>%
  pivot_wider(names_from = tax, values_from = density) %>% # ...before returning to original format
  left_join(os_1km_grid, by = "gridSquare") %>% st_sf()

# Sum number of species per 10km grid cell.

os_1km_grid_points <- os_1km_grid_bto %>% st_centroid()

gb_bird_intsct <- st_intersects(os_10km_grid, os_1km_grid_points) %>% 
  lapply(function(x) x %>% paste(collapse = ",") %>% as_tibble()) %>%
  reduce(rbind) 

tax_groups <- unique(bird_species$tax)

grid_list <- list()

for (i in 1:length(tax_groups)) {
  
  os_10km_grid_species <- gb_bird_intsct %>% 
    mutate(!!tax_groups[i] := map_dbl(value, ~sum.density(.x, os_1km_grid_points, tax_groups[i]))) %>% 
    dplyr::select(-value)
  
   grid_list[[length(grid_list) + 1]] <- os_10km_grid_species
}

# Calculate median density per species to adjust richness to high density areas.

species_median <- reduce(grid_list, bind_cols) %>%
  pivot_longer(cols = Turdus:Emberiza) %>% 
  group_by(name) %>% 
  summarise(median = median(value, na.rm=T))

# Filter and count number of species per grid cell.

os_10km_bto_grid <- reduce(grid_list, bind_cols) %>%
  mutate(gridSquare = os_10km_grid$gridSquare) %>%
  mutate(across(Turdus:Emberiza, ~ ifelse(.x > pull(species_median[,"median"][species_median$name == cur_column(),]),
                                .x, 0))) %>% # median cut off point to amplify richness signal
  rowwise() %>%
  mutate(n_species_bto = sum(c_across(Turdus:Emberiza) > 0)) %>%
  ungroup() %>%
  select(gridSquare, everything())

os_10km_grid <- os_10km_grid %>%
  left_join(os_10km_bto_grid %>% select(gridSquare, n_species_bto), by = "gridSquare")

# Plot.

bto_plot <- ggplot() + 
  geom_sf(data=os_10km_grid %>% filter(!is.na(n_species_bto)), aes(fill=n_species_bto), lwd=0) +
  scale_fill_gradient2(low= "#4061b0", mid = "white", high="#e83b3b", midpoint = 18.5,
                       limits = c(0,37)) +
  labs(title = "Modelled", fill = "Species\nrichnness", x = NULL, y =NULL) +
  theme_bw() +
  theme(plot.title = element_text(size = 24, hjust = 0.5, vjust = 0), 
        legend.position = "bottom",
        legend.title = element_text(size = 22), 
        legend.text = element_text(size = 20),
        legend.key.size = unit(1, "cm"),
        legend.key.width = unit(1.25, "cm"),
        legend.key = element_rect(colour="grey", size=1),
        axis.text = element_text(size = 20),
        plot.margin = unit(c(0,0,0,0),"cm"))

############################################################################################################
# Calculate species richness using Flickr data.
############################################################################################################
# Sum number of species interactions per grid cell per taxonomic group

tax_groups <- unique(bird_species$tax)

grid_list <- list()

for (i in 1:length(tax_groups)) {
  
  os_10km_species <- os_10km_grid %>%
    st_drop_geometry() %>%
    select(gridSquare) %>%
    mutate(!!tolower(tax_groups[i]) := lengths(st_intersects(
      os_10km_grid, gb_preds_birds %>% filter(tax == tax_groups[i])))) %>%
    select(-gridSquare)
  
  grid_list[[length(grid_list) + 1]] <- os_10km_species
}

# Count number of species per grid cell.

os_10km_flickr_grid <- reduce(grid_list, bind_cols) %>%
  mutate(gridSquare = os_10km_grid$gridSquare) %>%
  rowwise() %>%
  mutate(n_species_flickr = sum(c_across(turdus:emberiza) > 0)) %>%
  ungroup() %>%
  select(gridSquare, everything())

os_10km_grid <- os_10km_grid %>%
  left_join(os_10km_flickr_grid %>% select(gridSquare, n_species_flickr), by = "gridSquare")

# Plot.

flickr_plot <- ggplot() + 
  geom_sf(data=os_10km_grid %>% filter(!is.na(n_species_bto)), aes(fill=n_species_flickr), lwd=0) +
 # geom_sf(data=gb_border, fill=NA, colour="grey") +
  scale_fill_gradient2(low= "#4061b0", mid = "white", high="#e83b3b", midpoint = 18.5,
                       limits = c(0,37)) +
  labs(title = "Flickr", fill = "Species\nrichnness", x = NULL, y =NULL) +
  theme_bw() +
  theme(plot.title = element_text(size = 24, hjust = 0.5, vjust = 0), 
        legend.position = "bottom",
        legend.title = element_text(size = 22), 
        legend.text = element_text(size = 20),
        legend.key.size = unit(1, "cm"),
        legend.key.width = unit(1.25, "cm"),
        legend.key = element_rect(colour="grey", size=1),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.margin = unit(c(0,0,0,0),"cm"))

############################################################################################################
# Calculate species richness using iNaturalist data.
############################################################################################################
# Sum number of species interactions per grid cell per taxonomic group

tax_groups <- unique(bird_species$tax)

grid_list <- list()

for (i in 1:length(tax_groups)) {
  
  os_10km_species <- os_10km_grid %>%
    st_drop_geometry() %>%
    select(gridSquare) %>%
    mutate(!!tolower(tax_groups[i]) := lengths(st_intersects(
      os_10km_grid, obs_gb_birds %>% st_transform(crs = st_crs(os_10km_grid)) %>% 
        filter(tax == tax_groups[i])))) %>%
    select(-gridSquare)
  
  grid_list[[length(grid_list) + 1]] <- os_10km_species
}

# Count number of species per grid cell.

os_10km_inat_grid <- reduce(grid_list, bind_cols) %>%
  mutate(gridSquare = os_10km_grid$gridSquare) %>%
  rowwise() %>%
  mutate(n_species_inat = sum(c_across(turdus:emberiza) > 0)) %>%
  ungroup() %>%
  select(gridSquare, everything())

os_10km_grid <- os_10km_grid %>%
  left_join(os_10km_inat_grid %>% select(gridSquare, n_species_inat), by = "gridSquare")

# Plot.

inat_plot <- ggplot() + 
  geom_sf(data=os_10km_grid %>% filter(!is.na(n_species_bto)), aes(fill=n_species_inat), lwd=0) +
  scale_fill_gradient2(low= "#4061b0", mid = "white", high="#e83b3b", midpoint = 18.5,
                       limits = c(0,37)) +
  labs(title = "iNaturalist", fill = "Species\nrichnness", x = NULL, y =NULL) +
  theme_bw() +
  theme(plot.title = element_text(size = 24, hjust = 0.5, vjust = 0), 
        legend.position = "bottom",
        legend.title = element_text(size = 22), 
        legend.text = element_text(size = 20),
        legend.key.size = unit(1, "cm"),
        legend.key.width = unit(1.25, "cm"),
        legend.key = element_rect(colour="grey", size=1),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.margin = unit(c(0,0,0,0),"cm"))

############################################################################################################
# Comparison.
############################################################################################################

summary(lm(os_10km_grid$n_species_bto ~ os_10km_grid$n_species_flickr))
summary(lm(os_10km_grid$n_species_bto ~ os_10km_grid$n_species_inat))
summary(lm(os_10km_grid$n_species_flickr ~ os_10km_grid$n_species_inat))

############################################################################################################
# Calculate population density.
############################################################################################################

pop <- engw_pop %>% rbind(sco_pop)

lsoa_pop <- lsoa %>% 
  left_join(pop, by = c("geo_code"="lsoa")) %>%
  mutate(pop_den_km2 = pop / area_km2) %>%
  dplyr::select(geo_code, geo_label, pop_den_km2)

rm(engw_pop, sco_pop, pop, lsoa)

gb_pop_intsct <- st_intersects(os_10km_grid, lsoa_pop) %>% 
  lapply(function(x) x %>% paste(collapse = ",") %>% as_tibble()) %>%
  reduce(rbind) 

gb_pop <- gb_pop_intsct  %>% 
  mutate(pop = map_dbl(value, ~mean.pop(.x, lsoa_pop))) %>% 
  dplyr::select(-value) %>% 
  mutate(gridSquare = os_10km_grid$gridSquare)

os_10km_grid  <- os_10km_grid  %>% 
  left_join(gb_pop, by = "gridSquare") %>%
  mutate_at(vars(pop), replace_na, replace = 0)

rm(lsoa_pop)

pop_plot <- ggplot() + 
  geom_sf(data=os_10km_grid %>% 
            filter(!is.na(n_species_bto)) %>%
            filter(!is.na(pop)), aes(fill=pop), lwd=0) +
  scale_fill_gradient2(low= "#4061b0", mid = "white", high="#e83b3b",
                       midpoint = 5000, limits = c(0,10000), oob = squish, 
                       breaks = seq(0,10000,5000),
                       labels = c("0","5000","10000+")) +
  labs(title = "Human\npopulation density", fill = expression("Persons /"~km^2), x=NULL, y =NULL) +
  theme_bw() +
  theme(plot.title = element_text(size = 24, hjust = 0.5, vjust = 0), 
        legend.position = "bottom",
        legend.title = element_text(size = 19), 
        legend.text = element_text(size = 18),
        legend.key.size = unit(1, "cm"),
        legend.key.width = unit(1, "cm"),
        legend.key = element_rect(colour="grey", size=1),
        axis.text.x = element_text(size = 20),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.margin = unit(c(0,0,0,0),"cm"))

############################################################################################################
# 5. Final plot.
############################################################################################################

map_plots <- plot_grid(bto_plot, flickr_plot, inat_plot, pop_plot, align="hv", ncol=4)

ggsave(path='./data/figures/',filename='species_richness.png',device='png',
       width=21.5, height=10, dpi=300, bg="white")  

############################################################################################################
