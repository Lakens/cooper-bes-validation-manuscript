# maps for manuscript
library(here)
library(sf)
library(mapview)
library(tidyverse)
library(tmap) #maybe??
library(rnaturalearth)
library(colorspace)
library(grid)
library(USAboundaries)

# bring in cleaned data
if(!(file.exists(here("Data/cleaned_responses/sea_eagle_cleaning_2022_06_07_geocoded_travel_cost.csv")))){
  stop("Go get cleaning code from here('Scripts/002 - Analysis.R'), lines 0 - 110")
} else{
  clean_data <- read_csv(here("Data/cleaned_responses/sea_eagle_cleaning_2022_06_07_geocoded_travel_cost.csv"))
}

clean_data <- clean_data %>%
  mutate(travel_dist_km = travel_dist_meter / 1000)

clean_data <- clean_data %>%
  mutate(`Transportation Mode` = ifelse(airfare_cost_new > 0, "Flying", "Driving"))
# get north america shapefile
data(countries110)
nam <- countries110 %>%
  st_as_sf() %>%
  filter(continent == 'North America')

states <- us_states() %>%
  st_transform(us_states, crs = 4326)


# get respondents home zips in spatial format
clean_data <- clean_data %>%
  filter(!is.na(home_lng)) %>%
  st_as_sf(coords = c('home_lng', 'home_lat'), crs = 4326)

# get eagle locations 
eagle_locs <- clean_data %>%
  filter(!duplicated(attempt_lng)) %>%
  st_as_sf(coords = c('attempt_lng', 'attempt_lat'), crs = 4326)

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #

# MAKE MAP OF RESPONDENTS HOME ZIPS

# color palette
pal <- qualitative_hcl(9, palette = 'Dark 2')[2]
pal <- c("#d8b365", "#5ab4ac")
# bounding box for northeast
# northeast = st_bbox(c(xmin = -77.629395, xmax = -66.511230,
#                       ymin = 36.544949, ymax = 45.996962),
#                     crs = st_crs(4326)) |> 
#   st_as_sfc()

northeast = st_bbox(c(xmin = -73.476563, xmax = -66.994629,
                      ymin = 41.244772, ymax = 45.127805),
                    crs = st_crs(4326)) |> 
  st_as_sfc()


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

us_states_map = tm_shape(states %>% 
                           filter(!(state_name %in% c('Hawaii','Alaska','Puerto Rico'))),
                         projection = 2163) + 
  tm_polygons(col = '#d9d9d9') + 
  tm_layout(frame = FALSE,bg.color = NA, inner.margins = c(rep(0.04, 4))) +
  tm_shape(clean_data, projection = 2163) +
  tm_symbols(col = pal,border.col = "white", size = 0.5) +
  tm_layout(legend.show = F) +
  tm_shape(northeast, projection = 2163) +
  tm_borders(lwd = 2)

hawaii_map = tm_shape(states %>% filter(state_name == 'Hawaii'),projection = 32604) + tm_polygons() + 
  tm_layout(title = "Hawaii", frame = FALSE, bg.color = NA, 
            title.position = c("LEFT", "BOTTOM"))
alaska_map = tm_shape(states %>% filter(state_name == 'Alaska'),projection = 32605) + tm_polygons() + 
  tm_layout(title = "Alaska", frame = FALSE, bg.color = NA)
pr_map = tm_shape(states %>% filter(state_name == 'Puerto Rico'),projection = 32619) + 
  tm_polygons() + 
  tm_layout(title = "Puerto Rico", frame = FALSE, bg.color = NA,
            title.position = c(0,0.8))
NE_map <- tm_shape(nam, bbox = northeast) +
  tm_polygons() + 
  tm_shape(states, bbox = northeast) +
  tm_borders() +
  tm_shape(clean_data, bbox = northeast) +
  tm_symbols(col = pal,border.col = "white", size = 0.25) +
  tm_layout(legend.show = F)


tmap_save(us_states_map, filename = here('Results/Figures/respondents_home_zip.jpg'),
          height = 8, width = 8, dpi = 300,
          insets_tm = list(hawaii_map,alaska_map,pr_map, NE_map),
          insets_vp = list(grid::viewport(0.45, 0.1, width = 0.2, height = 0.1),
                           grid::viewport(0.15, 0.15, width = 0.3, height = 0.3),
                           grid::viewport(0.75, 0.1, width = 0.3, height = 0.3),
                           grid::viewport(0.75, 0.85, width = 0.3, height = 0.3)))

tmap_save(us_states_map, filename = here('Results/Figures/respondents_home_zip_noAK_HI_PR.jpg'),
          height = 8, width = 8, dpi = 300,
          insets_tm = list(NE_map),
          insets_vp = list(grid::viewport(0.75, 0.85, width = 0.3, height = 0.3)))

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #

# map showing differences in transportation mode
trans_map = tm_shape(states %>% 
                           filter(!(state_name %in% c('Hawaii','Alaska','Puerto Rico'))),
                         projection = 2163) + 
  tm_polygons(col = '#d9d9d9') + 
  tm_layout(frame = FALSE,bg.color = NA, inner.margins = c(rep(0.04, 4))) +
  tm_shape(clean_data, projection = 2163) +
  tm_symbols(col = "Transportation Mode", palette = pal,
             border.col = "white", size = 0.5,) +
  tm_layout(legend.show = T, legend.text.size = 1.5, legend.title.size = 1.75) +
  tm_shape(northeast, projection = 2163) +
  tm_borders(lwd = 2)

NE_trans <- tm_shape(nam, bbox = northeast) +
  tm_polygons() + 
  tm_shape(states, bbox = northeast) +
  tm_borders() +
  tm_shape(clean_data, bbox = northeast) +
  tm_symbols(col = "Transportation Mode", palette = pal,border.col = "white", size = 0.25) +
  tm_layout(legend.show = F)

tmap_save(trans_map, filename = here('Results/Figures/respondents_home_zip_trans_mode.jpg'),
          height = 8, width = 8, dpi = 300,
          insets_tm = list(NE_trans),
          insets_vp = list(grid::viewport(0.75, 0.85, width = 0.3, height = 0.3)))

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
par(bg=NA)
nam_map <- tm_shape(nam,projection = 2163) + 
  tm_polygons(col = '#d9d9d9') + 
  tm_layout(frame = FALSE,inner.margins = c(rep(0.04, 4)),
            bg.color = "#00000000", outer.bg.color = "#00000000") 


tmap_save(nam_map, filename = here('Results/Figures/nam_map.png'),
          height = 8, width = 8, dpi = 300, bg = 'transparent')
