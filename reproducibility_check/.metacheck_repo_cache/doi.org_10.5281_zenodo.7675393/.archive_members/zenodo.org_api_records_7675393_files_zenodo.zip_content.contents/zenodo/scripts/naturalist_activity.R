# Script to map predictions of naturalist model on Flickr dataset versus iNaturalist observations.
# Author: Ilan Havinga.
# Date: February 2023.
# Note this script requires GADM boundaries for Great Britain to be downloaded as well as OS national grids:
# https://github.com/OrdnanceSurvey/OS-British-National-Grids, london wards: 
# https://data.london.gov.uk/dataset/statistical-gis-boundary-files-london and
# national parks shapefiles collated from government websites.

# libraries

library(foreign)
library(classInt)
library(jsonlite)
library(RColorBrewer)
library(scales)
library(viridis)
library(ggrepel)
library(patchwork)
library(cowplot)
library(lubridate)
library(raster)
library(caret)
library(sf)
library(tidyverse)
library(mapview)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.
############################################################################################################
# 1. Grids.

# 1.1. GB.

gb <- read_rds("./data/admin/boundaries/gb/gadm36_GBR_1_sf.rds") %>% 
  filter(NAME_1 %in% c("England", "Scotland", "Wales")) %>%
  st_transform(27700)

os_10km_grid <- st_read("./data/grid/OS-British-National-Grids-main/os_bng_grids.gpkg", layer = "10km_grid") %>%
  rename(gridSquare = tile_name)
os_10km_grid <- os_10km_grid[st_intersects(os_10km_grid, gb) %>% lengths > 0,] 

# 1.2. London.

london <- as(st_read("./data/admin/boundaries/gb/ldn/London_Ward.shp") %>% 
               st_transform(27700), 'Spatial') %>% raster::aggregate(dissolve=T) %>% st_as_sf() # download if neccessary


os_1km_grid <- st_read("./data/grid/OS-British-National-Grids-main/os_bng_grids.gpkg", layer = "1km_grid") %>%
  rename(gridSquare = tile_name)

ldn_1km_grid <- os_1km_grid[st_intersects(os_1km_grid, london) %>% lengths > 0,]

# 1.3. Peak District.

peak_district <- st_read("./data/admin/boundaries/gb/np/National_Parks_England.shp") %>%
  st_transform(27700) %>%
  select(NAME) %>% filter(NAME == "PEAK DISTRICT")

peak_district_grid <- st_make_grid(peak_district, cellsize = 2500) %>% 
  st_sf() %>%
  mutate(gridSquare = seq(1:nrow(.))) %>%
  select(gridSquare)

peak_district_grid <- peak_district_grid[st_intersects(peak_district_grid, peak_district) %>% lengths > 0,]

# 1.2. Flickr metadata with naturalist predictions

gb_metadata_preds_beta01 <- read_rds("./data/flickr/metadata/gb/gb_metadata_preds_beta01.rds") 

# 1.3. load iNaturalist observations

obs_gb <- read_rds("./data/inat/metadata/obs_gb.rds") %>% st_transform(27700)

############################################################################################################
# 1. Genus counts.
############################################################################################################
# 1.1. Refine data.

flickr_nat_preds <- gb_metadata_preds_beta01 %>% 
  st_drop_geometry() %>%
  filter(pred==1)

inat_nat_preds <- obs_gb %>%
  st_drop_geometry()

# 1.2. Top flickr and inaturalist genera

flickr_genus <- flickr_nat_preds %>%
  filter(entropy < 2.42) %>% # genus is quite specific so we need to refine the predictions
  group_by(genus) %>% tally() %>%
  arrange(desc(n))

top_flickr_genus_ids <- flickr_nat_preds %>%
  filter(genus %in% flickr_genus$genus[1:10]) %>%
  select(id)
write_csv(top_flickr_genus_ids, "./data/flickr/metadata/gb/top_flickr_genus_ids.csv") # for image search

geese_ids <- flickr_nat_preds %>%
  filter(genus == "Anser") %>%
  select(id)
write_csv(geese_ids, "./data/flickr/metadata/gb/greygeese_ids.csv") # for image search

inat_genus <- inat_nat_preds %>%
  filter(!is.na(pred_genus)) %>% # a lot!
  filter(entropy < 2.42) %>% # genus is quite specific so we need to refine the predictions
  group_by(pred_genus) %>% tally() %>%
  arrange(desc(n))

# 1.3. plot.

flickr_genus_plt <- ggplot(flickr_genus %>% 
                             slice(1:10) %>%
                             mutate(genus = factor(genus, levels=flickr_genus$genus[1:10])), 
                           aes(genus, n)) +
  geom_bar(stat="identity", fill="#8c7dc2", colour="black") + #  #6a4ea6
  scale_x_discrete(name = "",
                   labels = c("Swans", "Dabbling\nducks", "Robins", "Herons", "Squirrels",
                              "Black\ngeese", "Deer\n(Americas)", "Gulls","Thrushes","White/grey\ngeese")) +
  scale_y_continuous(name = "# images", breaks=seq(0,20000,4000)) +
  theme_bw() +
  theme(axis.text = element_text(size = 14.5),
        axis.title = element_text(size = 16.5),
        plot.margin = unit(c(0,0,0,0.5), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

inat_genus_plt <- ggplot(inat_genus %>% 
                           slice(1:10) %>%
                           mutate(pred_genus = factor(pred_genus, levels=inat_genus$pred_genus[1:10])), 
                         aes(pred_genus, n)) +
  geom_bar(stat="identity", fill="#69a84f", colour = "black") +
  scale_x_discrete(name = "Genus",
                   labels = c("Geraniums", "Vanessa\n(butterflies)", "Lady\nbugs",
                              "Honey\nbees", "Dabbling\nducks", "Clover", "Pieris\n(butterflies)",
                              "Swans","Aglais\n(butterflies)", "Thrushes")) +
  scale_y_continuous(name = "# images", breaks=seq(0,8000,2000)) +
  theme_bw() +
  theme(axis.text = element_text(size = 14.5),
        axis.title = element_text(size = 16.5),
        axis.title.x = element_text(vjust = -1),
        plot.margin = unit(c(0,0,0.3,0.5), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

plot_grid(flickr_genus_plt, inat_genus_plt, nrow=2, labels = c("(a)","(b)"), hjust=0.025, label_size = 17)

ggsave(path='./data/figures/',filename='genus_preds.png',device='png',
       width=11, height=10, dpi=300, bg="white")

############################################################################################################
# 2. Spatial analysis of Flickr and iNaturalist interactions
############################################################################################################
# 2.1. GB level.

os_10km_grid <- os_10km_grid %>%
  mutate(n_nat = lengths(st_intersects(os_10km_grid, gb_metadata_preds_beta01 %>% filter(pred == 1)))) 

# 2.2. London.

ldn_1km_grid <- ldn_1km_grid %>%
  mutate(n_birds = lengths(st_intersects(ldn_1km_grid, gb_metadata_preds_beta01 %>%
                                           filter(pred==1) %>%
                                           filter(supercategory == "Aves")))) %>%
  mutate(n_plants = lengths(st_intersects(ldn_1km_grid, gb_metadata_preds_beta01 %>% 
                                            filter(pred==1) %>%
                                            filter(supercategory == "Plantae")))) %>%
  mutate(n_insects = lengths(st_intersects(ldn_1km_grid, gb_metadata_preds_beta01 %>% 
                                             filter(pred==1) %>%
                                             filter(supercategory == "Insecta")))) %>%
  mutate(n_mammals = lengths(st_intersects(ldn_1km_grid, gb_metadata_preds_beta01 %>% 
                                             filter(pred==1) %>%
                                             filter(supercategory == "Mammalia")))) 

ldn_1km_grid <- ldn_1km_grid %>%
  mutate(n_birds_obs = lengths(st_intersects(ldn_1km_grid, obs_gb %>%
                                           filter(pred_supercategory == "Aves")))) %>%
  mutate(n_plants_obs = lengths(st_intersects(ldn_1km_grid, obs_gb %>% 
                                            filter(pred_supercategory == "Plantae")))) %>%
  mutate(n_insects_obs = lengths(st_intersects(ldn_1km_grid, obs_gb %>% 
                                             filter(pred_supercategory == "Insecta")))) %>%
  mutate(n_mammals_obs = lengths(st_intersects(ldn_1km_grid, obs_gb %>% 
                                             filter(pred_supercategory == "Mammalia")))) 

# 2.3. Peak District.

peak_district_grid <- peak_district_grid %>%
  mutate(n_birds = lengths(st_intersects(peak_district_grid, gb_metadata_preds_beta01 %>%
                                           filter(pred==1) %>%
                                           filter(supercategory == "Aves")))) %>%
  mutate(n_plants = lengths(st_intersects(peak_district_grid, gb_metadata_preds_beta01 %>% 
                                            filter(pred==1) %>%
                                            filter(supercategory == "Plantae")))) %>%
  mutate(n_insects = lengths(st_intersects(peak_district_grid, gb_metadata_preds_beta01 %>% 
                                             filter(pred==1) %>%
                                             filter(supercategory == "Insecta")))) %>%
  mutate(n_mammals = lengths(st_intersects(peak_district_grid, gb_metadata_preds_beta01 %>% 
                                             filter(pred==1) %>%
                                             filter(supercategory == "Mammalia")))) 

peak_district_grid <- peak_district_grid %>%
  mutate(n_birds_obs = lengths(st_intersects(peak_district_grid, obs_gb %>%
                                               filter(pred_supercategory == "Aves")))) %>%
  mutate(n_plants_obs = lengths(st_intersects(peak_district_grid, obs_gb %>% 
                                                filter(pred_supercategory == "Plantae")))) %>%
  mutate(n_insects_obs = lengths(st_intersects(peak_district_grid, obs_gb %>% 
                                                 filter(pred_supercategory == "Insecta")))) %>%
  mutate(n_mammals_obs = lengths(st_intersects(peak_district_grid, obs_gb %>% 
                                                 filter(pred_supercategory == "Mammalia")))) 



############################################################################################################
# 3. Plot.
############################################################################################################
# 3.1. GB.

gb_plot <- ggplot() +
  geom_sf(data = os_10km_grid %>% 
            mutate(n_nat = log(n_nat)) %>% 
            filter(n_nat != -Inf), aes(fill=n_nat), lwd=0) +
  scale_fill_gradient2(low= "#4061b0", mid = "white", high="#e83b3b", midpoint = 4.66) +
  geom_sf(data=london, fill=NA, colour="black", lwd=1) +
  geom_sf_text(data=london %>% mutate(name="(c)"), aes(label = name), size = 8,
               colour = "black", fontface = "bold", nudge_x = -63000, nudge_y = 35000) +
  geom_sf(data=peak_district, fill=NA, colour="black", lwd=1) +
  geom_sf_text(data=peak_district %>% mutate(name="(b)"), aes(label = name), size = 8,
               colour = "black", fontface = "bold", nudge_x = -60000, nudge_y = 32000) +
  labs(title = "Flickr", fill="Inter-\nactions\n(log)") +
  theme_bw() +
  theme(plot.title = element_text(size = 16.5, hjust = 0.5),
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(1, "cm"),
        axis.text = element_text(size = 14),
        axis.title = element_blank(),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0),"cm"))

gb_plot_final <- plot_grid(gb_plot, labels = c("(a)"), label_size = 20)

# 3.2. London

london_long <- ldn_1km_grid %>% 
  select(gridSquare, n_birds, n_birds_obs, n_plants, n_plants_obs,
         n_insects, n_insects_obs, n_mammals, n_mammals_obs) %>%
  pivot_longer(cols = c("n_birds", "n_birds_obs", "n_plants", "n_plants_obs",
                        "n_insects", "n_insects_obs", "n_mammals", "n_mammals_obs"), 
               names_to = "species", 
               values_to = "n") %>%
  mutate(species = factor(species, levels=c("n_birds", "n_birds_obs", "n_plants", "n_plants_obs",
                                            "n_insects", "n_insects_obs", "n_mammals", "n_mammals_obs"))) %>%
  st_sf()

ldn_birds <- ggplot(london_long %>%
                      filter(species %in% c("n_birds", "n_birds_obs")) %>%
                      mutate(n = log(n)) %>% 
                      filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_birds"="Flickr",
                                                   "n_birds_obs"="iNaturalist")),
             nrow=2, strip.position = "left") +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#227bc3", high="#0e314e", midpoint = 3.5,
                       breaks = seq(0,7.5,2), limits = c(0,7.5), oob=squish) +
  geom_sf(data=london, fill=NA, colour="grey") +
  labs(fill = "Interactions (log)", title = "Birds") +
  ylab(NULL) +
  theme_bw() + 
  theme(strip.text = element_text(size = 16.5, vjust = 1),
        strip.background = element_blank(),
        strip.placement = "outside",
        plot.title = element_text(size = 16.5, hjust = 0.5),
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        legend.position="bottom",
        axis.text = element_text(size = 14),
        axis.title =  element_blank(),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines")) 


ldn_plants <- ggplot(london_long %>%
                       filter(species %in% c("n_plants", "n_plants_obs")) %>%
                       mutate(n = log(n)) %>% 
                       filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_plants"="Flickr",
                                                   "n_plants_obs"="iNaturalist")),
             nrow=2, strip.position = "left") +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#65c322", high="#294e0e", midpoint = 3.5,
                       breaks = seq(0,7.5,2), limits = c(0,7.5), oob=squish) +
  geom_sf(data=london, fill=NA, colour="grey") +
  labs(fill = "Interactions (log)", title = "Plants") +
  ylab(NULL) +
  theme_bw() + 
  theme(strip.text = element_text(size = 16.5, colour = "white", vjust = 1),
        strip.background = element_blank(),
        strip.placement = "outside",
        plot.title = element_text(size = 16.5, hjust = 0.5),
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        legend.position="bottom",
        axis.text = element_text(size = 14),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title =  element_blank(),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines")) 

ldn_insects <- ggplot(london_long %>%
                        filter(species %in% c("n_insects", "n_insects_obs")) %>%
                        mutate(n = log(n)) %>% 
                        filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_insects"="Flickr",
                                                   "n_insects_obs"="iNaturalist")),
             nrow=2, strip.position = "left") +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#c3a622", high="#4e420e", midpoint = 2.8,
                       breaks = seq(0,7.5,2), limits = c(0,7.5), oob=squish) +
  geom_sf(data=london, fill=NA, colour="grey") +
  labs(fill = "Interactions (log)", title = "Insects") +
  ylab(NULL) +
  theme_bw() + 
  theme(strip.text = element_text(size = 16.5, colour = "white", vjust = 1),
        strip.background = element_blank(),
        strip.placement = "outside",
        plot.title = element_text(size = 16.5, hjust = 0.5),
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        legend.position="bottom",
        axis.text = element_text(size = 14),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title =  element_blank(),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines")) 


ldn_mammals <- ggplot(london_long %>%
                        filter(species %in% c("n_mammals", "n_mammals_obs")) %>%
                        mutate(n = log(n)) %>% 
                        filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_mammals"="Flickr",
                                                   "n_mammals_obs"="iNaturalist")),
             nrow=2, strip.position = "left") +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#6022c3", high="#260e4e", midpoint = 2.8,
                       breaks = seq(0,7.5,2), limits = c(0,7.5), oob=squish) +
  geom_sf(data=london, fill=NA, colour="grey") +
  labs(fill = "Interactions (log)", title = "Mammals") +
  ylab(NULL) +
  theme_bw() + 
  theme(strip.text = element_text(size = 16.5, colour = "white", vjust = 1),
        strip.background = element_blank(),
        strip.placement = "outside",
        plot.title = element_text(size = 16.5, hjust = 0.5),
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        legend.position="bottom",
        axis.text = element_text(size = 14),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title =  element_blank(),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines")) 


ldn_plots <- plot_grid(ldn_birds, ldn_plants, ldn_insects, 
                       labels = c("(c)", ""), align = "hv", 
                       ncol=3, label_size = 20, vjust = 4)

# 3.3. Peak District.

peak_district_long <- peak_district_grid %>% 
  select(gridSquare, n_mammals, n_mammals_obs, n_birds, n_birds_obs, 
         n_insects, n_insects_obs, n_plants, n_plants_obs) %>%
  pivot_longer(cols = c("n_mammals", "n_mammals_obs", "n_birds", "n_birds_obs", 
                        "n_insects", "n_insects_obs", "n_plants", "n_plants_obs"), 
               names_to = "species", 
               values_to = "n") %>%
  mutate(species = factor(species, levels=c("n_mammals", "n_mammals_obs", "n_birds", "n_birds_obs", 
                                            "n_insects", "n_insects_obs", "n_plants", "n_plants_obs"))) %>%
  st_sf()


peak_mammals <- ggplot(peak_district_long %>%
         filter(species %in% c("n_mammals", "n_mammals_obs")) %>%
         mutate(n = log(n)) %>% 
         filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_mammals"="Flickr",
                                                   "n_mammals_obs"="iNaturalist")),
             ncol=2) +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#6022c3", high="#260e4e", midpoint = 2.9) +
  geom_sf(data=peak_district, fill=NA, colour="grey") +
  scale_x_continuous(breaks = seq(-2,2,0.3)) +
  labs(fill = "Inter-\nactions\n(log)", y = "Mammals") +
  theme_bw() + 
  theme(strip.text = element_text(size = 16.5),
        strip.background = element_blank(),
        strip.placement = "outside",
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        axis.text = element_text(size = 14),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.y =  element_text(size = 16.5, vjust = 3),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines"))

peak_birds <- ggplot(peak_district_long %>%
                         filter(species %in% c("n_birds", "n_birds_obs")) %>%
                         mutate(n = log(n)) %>% 
                         filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_birds"="Flickr",
                                                   "n_birds_obs"="iNaturalist")),
             ncol=2) +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#227bc3", high="#0e314e", midpoint = 2.8,
                       breaks = seq(0,6,2), limits = c(0,6), oob=squish) +
  geom_sf(data=peak_district, fill=NA, colour="grey") +
  scale_x_continuous(breaks = seq(-2,2,0.3)) +
  labs(fill = "Inter-\nactions\n(log)", y = "Birds") +
  theme_bw() + 
  theme(strip.text = element_blank(),
        strip.background = element_blank(),
        strip.placement = "outside",
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        axis.text = element_text(size = 14),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.y =  element_text(size = 16.5, vjust = 3),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines"))

peak_insects <- ggplot(peak_district_long %>%
                         filter(species %in% c("n_insects", "n_insects_obs")) %>%
                         mutate(n = log(n)) %>% 
                         filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_insects"="Flickr",
                                                   "n_insects_obs"="iNaturalist")),
             ncol=2) +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#c32d22", high="#4e120e", midpoint = 2.8,
                       breaks = seq(0,6,2), limits = c(0,6), oob=squish) +
  geom_sf(data=peak_district, fill=NA, colour="grey") +
  scale_x_continuous(breaks = seq(-2,2,0.3)) +
  labs(fill = "Inter-\nactions\n(log)", y = "Insects") +
  theme_bw() + 
  theme(strip.text = element_blank(),
        strip.background = element_blank(),
        strip.placement = "outside",
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        axis.text = element_text(size = 14),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.y =  element_text(size = 16.5, vjust = 3),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines"))


peak_plants <- ggplot(peak_district_long %>%
                         filter(species %in% c("n_plants", "n_plants_obs")) %>%
                         mutate(n = log(n)) %>% 
                         filter(n != -Inf)) + 
  facet_wrap(. ~ species, labeller = as_labeller(c("n_plants"="Flickr",
                                                   "n_plants_obs"="iNaturalist")),
             ncol=2) +
  geom_sf(aes(fill=n), lwd=NA) +
  scale_fill_gradient2(low="white", mid="#65c322", high="#294e0e", midpoint = 2.8,
                       breaks = seq(0,6,2), limits = c(0,6), oob=squish) +
  geom_sf(data=peak_district, fill=NA, colour="grey") +
  scale_x_continuous(breaks = seq(-2,2,0.3)) +
  labs(fill = "Inter-\nactions\n(log)", y = "Plants") +
  theme_bw() + 
  theme(strip.text = element_blank(),
        strip.background = element_blank(),
        strip.placement = "outside",
        legend.title = element_text(size = 16.5), 
        legend.text = element_text(size = 14),
        legend.key.size = unit(0.6, "cm"),
        axis.text = element_text(size = 14),
        axis.title.y =  element_text(size = 16.5, vjust = 3),
        panel.border = element_rect(colour = "grey"),
        plot.margin = unit(c(0.0,0.0,0.0,0.7),"cm"),
        panel.spacing = unit(1, "lines"))

peak_plots <- plot_grid(peak_mammals, peak_birds, 
                        peak_plants,
                        labels = c("(b)","","",""),
                        align = "hv", nrow=3, label_size = 20)

# 3.4. All together.

top_row <- gb_plot_final + (plot_spacer() + peak_plots + plot_spacer() + plot_layout(nrow=3,
                                                                          heights=c(0,1,0))) +
    plot_layout(ncol=2)

bottom_row <- plot_spacer() + ldn_plots + plot_spacer() + plot_layout(ncol=3, widths = c(0,1,0))

plot_grid(top_row, bottom_row, nrow=2, rel_heights = c(1,1))

ggsave(path='./data/figures/',filename='overall_fig.png',device='png',
       width=16, height=20, dpi=300, bg="white")

############################################################################################################
# 4. Summary table.
############################################################################################################

tally_imgs <- gb_metadata_preds_beta01 %>% 
  st_drop_geometry() %>% 
  filter(pred==1) %>% 
  group_by(owner, supercategory) %>% 
  tally()

tally_imgs_total <- gb_metadata_preds_beta01 %>% 
  st_drop_geometry() %>% 
  filter(pred==1) %>% 
  group_by(owner) %>% 
  tally()

tibble(
  species = c("birds", "plants", "mammals", "insects", "reptiles", "fungi", "other", "total"),
  n_imgs = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% summarise(sum(n)) %>% pull(),
             tally_imgs %>% ungroup() %>% 
               filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>% 
               summarise(sum(n)) %>% pull(),
             tally_imgs  %>% ungroup() %>% summarise(sum(n)) %>% pull()),
  n_users = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% nrow(),
              tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% nrow(),
              tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% nrow(),
              tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% nrow(),
              tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% nrow(),
              tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% nrow(),
              tally_imgs %>% ungroup() %>% 
                filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>%
                nrow(),
              tally_imgs_total %>% nrow()),
  min_user = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% summarise(min(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% 
                 filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>%
                 summarise(min(n)) %>% pull(),
               tally_imgs_total %>% summarise(min(n)) %>% pull()),
  median_user = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% summarise(median(n)) %>% pull(),
               tally_imgs %>% ungroup() %>% 
                 filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>%
                 summarise(median(n)) %>% pull(),
               tally_imgs_total %>% summarise(median(n)) %>% pull()),
  mean_user = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% summarise(mean(n)) %>% pull(),
                  tally_imgs %>% ungroup() %>% 
                    filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>%
                    summarise(mean(n)) %>% pull(),
                tally_imgs_total %>% summarise(mean(n)) %>% pull()),
  max_user = c(tally_imgs %>% ungroup() %>% filter(supercategory == "Aves") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% filter(supercategory == "Plantae") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% filter(supercategory == "Mammalia") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% filter(supercategory == "Insecta") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% filter(supercategory == "Reptilia") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% filter(supercategory == "Fungi") %>% summarise(max(n)) %>% pull(),
                tally_imgs %>% ungroup() %>% 
                  filter(!supercategory %in% c("Aves","Insecta","Mammalia","Plantae","Fungi","Reptilia")) %>%
                  summarise(max(n)) %>% pull(),
               tally_imgs_total %>% summarise(max(n)) %>% pull())
)

############################################################################################################

