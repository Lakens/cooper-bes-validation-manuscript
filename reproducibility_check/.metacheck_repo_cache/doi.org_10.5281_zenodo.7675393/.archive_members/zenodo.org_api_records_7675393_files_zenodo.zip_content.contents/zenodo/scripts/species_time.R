# Script to examine interactions with bird species of concern on Flickr and iNaturalist.
# Author: Ilan Havinga.
# Date: February 2023.

# libraries

library(httr)
library(jsonlite)
library(viridis)
library(taxize)
library(rinat)
library(cowplot)
library(lubridate)
library(tidytext)
library(tm)
library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.
############################################################################################################
# 1. Interactions.

gb_metadata_preds_beta01 <- read_rds("./data/flickr/gb/metadata/gb_metadata_preds_beta01.rds")

obs_gb <- read_rds("./data/inat/gb/metadata/obs_gb.rds")

############################################################################################################
# Plot.
############################################################################################################
# Nightingales

gb_nightingale_flickr <- gb_metadata_preds_beta01 %>%
  st_drop_geometry() %>%
  filter(genus == "Luscinia") %>%
  filter(pred==1) %>%
  filter(entropy < 2.42) %>%
  mutate(datetaken = as_date(datetaken)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(flickr_n = sum(n)) %>%
  rbind(tibble(month = c("Jan", "Feb"), flickr_n = c(0,0)))

gb_nightingale_inat <- obs_gb %>%
  st_drop_geometry() %>%
  filter(genus == "Luscinia") %>%
  mutate(datetaken = as_date(datetime)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(inat_n = sum(n)) 

gb_nightingale <- gb_nightingale_flickr %>%
  full_join(gb_nightingale_inat, by = "month") %>%
  mutate_at(vars(flickr_n, inat_n), ~replace_na(., 0)) %>%
  pivot_longer(cols=c('flickr_n','inat_n'), names_to = "source", values_to = "count") %>%
  mutate(month = factor(month, levels=c("Jan", "Feb", "Mar", "Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))) %>%
  mutate(source = factor(source, levels=c("flickr_n","inat_n")))

nightingale <- ggplot(gb_nightingale, aes(x = month, y= count, fill = source)) +
  geom_bar(stat="identity", width=.75, position = "dodge") +
  scale_fill_manual(labels = c("Flickr", "iNaturalist"), values=c("#8c7dc2","#69a84f")) +
  scale_y_continuous(breaks = seq(0,200,2)) + 
  labs(x = NULL, y = "Nightingale", fill = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 18.5),
        axis.text = element_text(size = 16.5),
        axis.title = element_text(size = 18.5, vjust = -3),
        plot.margin = unit(c(0.6,0.6,0,0.3), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

# Swifts.

gb_swifts_flickr <- gb_metadata_preds_beta01 %>%
  st_drop_geometry() %>%
  filter(family == "Apodidae") %>%
  filter(pred==1) %>%
  filter(entropy < 2.42) %>%
  mutate(datetaken = as_date(datetaken)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(flickr_n = sum(n))

gb_swifts_inat <- obs_gb %>%
  st_drop_geometry() %>%
  filter(pred_family == "Apodidae") %>%
  mutate(datetaken = as_date(datetime)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(inat_n = sum(n))

gb_swifts <- gb_swifts_flickr %>%
  full_join(gb_swifts_inat, by = "month") %>%
  mutate_at(vars(flickr_n, inat_n), ~replace_na(., 0)) %>%
  pivot_longer(cols=c('flickr_n','inat_n'), names_to = "source", values_to = "count") %>%
  mutate(month = factor(month, levels=c("Jan", "Feb", "Mar", "Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))) %>%
  mutate(source = factor(source, levels=c("flickr_n","inat_n")))

swifts <- ggplot(gb_swifts, aes(x = month, y= count, fill = source)) +
  geom_bar(stat="identity", width=.75, position = "dodge") +
  scale_fill_manual(labels = c("Flickr", "iNaturalist"), values=c("#8c7dc2","#69a84f")) +
  scale_y_continuous(breaks = seq(0,200,4)) + 
  labs(x = NULL, y = "Swifts", fill = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 18.5),
        axis.text = element_text(size = 16.5),
        axis.title = element_text(size = 18.5, vjust = -3),
        plot.margin = unit(c(0.6,0.6,0,0.3), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

# Turnstone.

gb_turnstone_flickr <- gb_metadata_preds_beta01 %>%
  st_drop_geometry() %>%
  filter(genus == "Arenaria") %>% 
  filter(supercategory == "Aves") %>%
  filter(pred==1) %>%
  filter(entropy < 2.42) %>%
  mutate(datetaken = as_date(datetaken)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(flickr_n = sum(n)) 

gb_turnstone_inat <- obs_gb %>%
  st_drop_geometry() %>%
  filter(genus == "Arenaria") %>% 
  filter(iconic_taxon_name == "Aves") %>%
  mutate(datetaken = as_date(datetime)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(inat_n = sum(n)) 

gb_turnstone <- gb_turnstone_flickr %>%
  full_join(gb_turnstone_inat, by = "month") %>%
  mutate_at(vars(flickr_n, inat_n), ~replace_na(., 0)) %>%
  pivot_longer(cols=c('flickr_n','inat_n'), names_to = "source", values_to = "count") %>%
  mutate(month = factor(month, levels=c("Jan", "Feb", "Mar", "Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))) %>%
  mutate(source = factor(source, levels=c("flickr_n","inat_n")))

turnstone <- ggplot(gb_turnstone, aes(x = month, y= count, fill = source)) +
  geom_bar(stat="identity", width=.75, position = "dodge") +
  scale_fill_manual(labels = c("Flickr", "iNaturalist"), values=c("#8c7dc2","#69a84f")) +
  scale_y_continuous(breaks = seq(0,200,20)) + 
  labs(x = NULL, y = "Turnstone", fill = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 18.5),
        axis.text = element_text(size = 16.5),
        axis.title = element_text(size = 18.5, vjust = -3),
        plot.margin = unit(c(0.6,0.6,0,0.3), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

# Wheateater

gb_wheateater_flickr <- gb_metadata_preds_beta01 %>%
  st_drop_geometry() %>%
  filter(genus == "Oenanthe") %>% 
  filter(pred==1) %>%
  filter(entropy < 2.42) %>%
  mutate(datetaken = as_date(datetaken)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(flickr_n = sum(n)) 

gb_wheateater_inat <- obs_gb %>%
  st_drop_geometry() %>%
  filter(genus == "Oenanthe") %>% 
  mutate(datetaken = as_date(datetime)) %>%
  mutate(datetaken = floor_date(datetaken, "month")) %>%
  group_by(datetaken) %>%
  tally() %>%
  filter(datetaken >= as_date("2010-01-01") & datetaken <= as_date("2019-12-01")) %>%
  mutate(month = month(datetaken, label = TRUE)) %>%
  group_by(month) %>%
  summarise(inat_n = sum(n)) 

gb_wheateater <- gb_wheateater_flickr %>%
  full_join(gb_wheateater_inat, by = "month") %>%
  mutate_at(vars(flickr_n, inat_n), ~replace_na(., 0)) %>%
  pivot_longer(cols=c('flickr_n','inat_n'), names_to = "source", values_to = "count") %>%
  mutate(month = factor(month, levels=c("Jan", "Feb", "Mar", "Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))) %>%
  mutate(source = factor(source, levels=c("flickr_n","inat_n")))

wheateater <- ggplot(gb_wheateater, aes(x = month, y= count, fill = source)) +
  geom_bar(stat="identity", width=.75, position = "dodge") +
  scale_fill_manual(labels = c("Flickr", "iNaturalist"), values=c("#8c7dc2","#69a84f")) +
  scale_y_continuous(breaks = seq(0,200,30)) + 
  labs(x = NULL, y = "Wheatear", fill = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.spacing.x = unit(0.5, 'cm'),
        legend.text = element_text(size = 18.5),
        axis.text = element_text(size = 16.5),
        axis.title = element_text(size = 18.5, vjust = -3),
        plot.margin = unit(c(0,0.6,0,0.3), "cm"),
        panel.grid.minor = element_line(size = 0.5), 
        panel.grid.major = element_line(size = 1),
        panel.border = element_blank())

bird_plots <- plot_grid(nightingale + theme(legend.position = "none"), 
                        swifts + theme(legend.position = "none"), 
                        turnstone + theme(legend.position = "none"),
                        wheateater + theme(legend.position = "none"),
                        nrow=4, align = "hv")

plot_grid(bird_plots, get_legend(wheateater), nrow=2, rel_heights = c(1,0.05))

ggsave(path='./data/figures/',filename='species_time.png',device='png',
       width=7.5, height=18, dpi=300, bg="white")

############################################################################################################