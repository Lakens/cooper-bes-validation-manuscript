#### 0. Read in the preable -----

# source('scripts/results-final/01-main-analysis/preamble.R')
load('scripts/results-final/01-main-analysis/preamble.RData')

# folder for saving the outputs of these scripts
suppressWarnings(dir.create('figures-final-v4/05-nutrient-simulation-FAMILY/', recursive = T))

#### 1. Read in biomass and nutrient map objects ----

# read in data
biomass_index_wide      <- readRDS('processed-models/sdm-run-june2021/final-outputs-QC2024/biomass_index_wide.RDS')
calcium_wide            <- readRDS('processed-models/sdm-run-june2021/final-outputs-QC2024/calcium_wide_RNI.RDS')
iron_wide               <- readRDS('processed-models/sdm-run-june2021/final-outputs-QC2024/iron_wide_RNI.RDS')
vitamina_wide           <- readRDS('processed-models/sdm-run-june2021/final-outputs-QC2024/vitamina_wide_RNI.RDS')
zinc_wide               <- readRDS('processed-models/sdm-run-june2021/final-outputs-QC2024/zinc_wide_RNI.RDS')

# from windows machine"E:\reef-futures-sdm-modelling\processed-models\sdm-run-june2021\final-outputs\wide-matrix\biomass_index\SSP126_dispersal-limitation_novel-sst\1981_2015.RDS"
# biomass_index_wide      <- readRDS('E:/reef-futures-sdm-modelling/processed-models/sdm-run-june2021/final-outputs/wide-matrix/biomass_index/SSP126_dispersal-limitation_novel-sst/1981_2015.RDS')
# calcium_wide            <- readRDS('E:/reef-futures-sdm-modelling/processed-models/sdm-run-june2021/final-outputs/wide-matrix-nutrients/Calcium_mu/biomass_index/SSP126_dispersal-limitation_novel-sst/1981_2015.RDS')
# iron_wide               <- readRDS('E:/reef-futures-sdm-modelling/processed-models/sdm-run-june2021/final-outputs/wide-matrix-nutrients/Iron_mu/biomass_index/SSP126_dispersal-limitation_novel-sst/1981_2015.RDS')
# vitamina_wide           <- readRDS('E:/reef-futures-sdm-modelling/processed-models/sdm-run-june2021/final-outputs/wide-matrix-nutrients/Vitamin_A_mu/biomass_index/SSP126_dispersal-limitation_novel-sst/1981_2015.RDS')
# zinc_wide               <- readRDS('E:/reef-futures-sdm-modelling/processed-models/sdm-run-june2021/final-outputs/wide-matrix-nutrients/Zinc_mu/biomass_index/SSP126_dispersal-limitation_novel-sst/1981_2015.RDS')

# remove 0s from nutrients
calcium_wide[calcium_wide==0]   <- NA
iron_wide[iron_wide==0]         <- NA
vitamina_wide[vitamina_wide==0] <- NA
zinc_wide[zinc_wide==0]         <- NA
# table(calcium_wide==0)
# table(iron_wide==0)
# table(vitamina_wide==0)
# table(zinc_wide==0)

# convert back into grams from log grams
biomass_index_wide[,-1] <- exp(biomass_index_wide[,-1]) # convert back to grams 
# table(biomass_index_wide==0)

# convert back to per 100g portion
calcium_wide[,-1]  <- calcium_wide[,-1]*100
iron_wide[,-1]     <- iron_wide[,-1]*100
vitamina_wide[,-1] <- vitamina_wide[,-1]*100
zinc_wide[,-1]     <- zinc_wide[,-1]*100

# express each as percentage of RDA per species
calcium_wide[,-1] <- (calcium_wide[,-1]/700) * 100
iron_wide[-1] <- (iron_wide[,-1] / 7) * 100
vitamina_wide[,-1] <- (vitamina_wide[,-1] / 300)*100
zinc_wide[,-1] <- (zinc_wide[,-1] / 3)*100

# subset to fished and non-conservation concern species 
fished_genus <- gsub(' ', '_', fished_list$fished_genus)
fished_genus <- fished_genus[which(fished_genus %in% keep_species$valid_name_FishBase)]

# length
length(fished_genus)
# 1371

# subset the matrix to only fished species
biomass_index_wide <- cbind(cell = biomass_index_wide[,'cell'], biomass_index_wide[,colnames(biomass_index_wide) %in% fished_genus])
calcium_wide       <- cbind(cell = calcium_wide[,'cell'],       calcium_wide[,colnames(calcium_wide) %in% fished_genus])
iron_wide          <- cbind(cell = iron_wide[,'cell'],          iron_wide[,colnames(iron_wide) %in% fished_genus])
vitamina_wide      <- cbind(cell = vitamina_wide[,'cell'],      vitamina_wide[,colnames(vitamina_wide) %in% fished_genus])
zinc_wide          <- cbind(cell = zinc_wide[,'cell'],          zinc_wide[,colnames(zinc_wide) %in% fished_genus])

# set up as a list of objects for the later loop to work over
nutrient_list <- list(calcium_wide = calcium_wide, 
                      iron_wide = iron_wide, 
                      vitamina_wide = vitamina_wide, 
                      zinc_wide = zinc_wide)

#### 2. Process and summarise the sea around us data for this analysis ----

# finally, obtain the species that contribute the most to direct consumption reported in the SAUP
saup_country_tonnes <- readRDS('processed-data/fisheries-data/saup_country_tonnes.RDS')

# bind together, get the countries of interest, and remove non-fished species
saup_reef_tonnes <- bind_rows(saup_country_tonnes) %>% 
  dplyr::rename(., ISO_3 = iso_3, valid_name_FishBase = species_corrected) %>% 
  mutate(valid_name_FishBase = gsub(' ', '_', .$valid_name_FishBase)) %>% 
  left_join(social %>% dplyr::select(ISO_3, GID_0), .) %>% 
  filter(GID_0 %in% reef_associated_nations$GID_0,
         direct_consumption == 1) %>% 
  split(., .$GID_0)

# read in the raw specices list information
species_list <- read.csv('processed-data/nutrient-content/Spp_NutrientPred_REEF_FUTURESJune2021.csv')

species_list$valid_name_FishBase <- gsub(' ','_',species_list$valid_name_FishBase)

# keep only valid species 
species_list <- species_list %>% 
  filter(valid_name_FishBase %in% keep_species$valid_name_FishBase, 
         valid_name_FishBase %in% fished_genus)

# check how many species in total, and how many species per country on average

all_country_fished <- species_list$valid_name_FishBase[which(species_list$valid_name_FishBase %in% test_taxa | 
                                                             species_list$Genus_FishBase %in% test_taxa)]



## Create loop across all countries in the SAUP dataset
country_nutrient_simulation <- list() 
country_species <- list()
for(i in seq_along(saup_reef_tonnes)){

   # 1. Get the species list for the GID_0 based on the nutrient maps
   test_saup <- saup_reef_tonnes[[i]]
   
   # 2. Get the taxonomic namese of valid species
   test_taxa <- na.omit(unique(c(test_saup$valid_name_FishBase, test_saup$genus, test_saup$family)))
   
   # 3. Read in the species list 
   test_country_fished <- species_list$valid_name_FishBase[which(species_list$valid_name_FishBase %in% test_taxa | 
                                                                 species_list$Genus_FishBase %in% test_taxa | 
                                                                   species_list$Family_FishBase %in% test_taxa )]
   test_country_fished <- gsub(' ', '_', test_country_fished)
   
   # 4. Obtain the country cells that are of interest
   test_country_cells <- country_cells[[which(names(country_cells) %in% unique(test_saup$GID_0))]]
   
   nutrient_output_country <- lapply(nutrient_list, function(x){
     
     # filter the nutrient and nutrients down to the country
     nutrient_country  <- x[which(x[,1] %in% test_country_cells),-1]
     
     # here remove species that don't have any occurrences in the countries to make the code later more streamlined
     nutrient_country <- nutrient_country[ , which(colSums(nutrient_country, na.rm = T) != 0)]
     
     # filter the nutrient and nutrient information down to the identified potentially fished species (defined above)
     # ensure also that only systems with > 1 fishable species are considered in these simulations
     if(length(which(colnames(nutrient_country) %in% test_country_fished))< 2){     
       return(data.frame(GID_0 = unique(test_saup$GID_0), 
                         n_fished_species = NA,
                         max_nutrient = NA, 
                         nutrient_trueFished_raw = NA, 
                         nutrient_nullFished_raw = NA, 
                         nutrient_trueFished = NA,
                         nutrient_nullFished = NA, 
                         nutrient_selectivity = NA, 
                         mean_nutrient_selectivity = NA ,
                         sd_nutrient_selectivity = NA))
       
     }
     # otherways get the fished species
     test_nutrient_trueFished  <- nutrient_country[, which(colnames(nutrient_country) %in% test_country_fished)] 
     
     # obtain the number of species which are classified as fished
     n_fished_species <- sum(colMeans(test_nutrient_trueFished, na.rm = T) != 0)
     
     # obtain the mean potential of the system when fishing the most RDA species at n_fished_species
     max_nutrient  <- mean(sort(colMeans(nutrient_country, na.rm = T),  decreasing = T)[1:n_fished_species], na.rm = T)
     
     # obtain true values of nutrients for country-specific fished species
     nutrient_trueFished_raw <- mean(apply(test_nutrient_trueFished, 2, function(x){unique(na.omit(x))}), na.rm = T)
     nutrient_trueFished     <- nutrient_trueFished_raw / max_nutrient
     
     # estimate distribution of random values
     nutrient_nullFished_raw  <- sapply(1:999, function(x) mean(apply(nutrient_country[,sample(seq_along(colnames(nutrient_country)),n_fished_species)], 
                                                                  2, 
                                                                  function(x){unique(na.omit(x))}), na.rm = T))
     nutrient_nullFished <- nutrient_nullFished_raw / max_nutrient
     
     # how to structure the outputs for a simple way to summarise the information
     return(data.frame(GID_0 = unique(test_saup$GID_0), 
                       n_fished_species = n_fished_species,
                       max_nutrient = max_nutrient, 
                       nutrient_trueFished_raw = nutrient_trueFished_raw, 
                       nutrient_nullFished_raw = nutrient_nullFished_raw, 
                       nutrient_trueFished = nutrient_trueFished,
                       nutrient_nullFished = nutrient_nullFished, 
                       nutrient_selectivity = nutrient_trueFished - nutrient_nullFished, 
                       mean_nutrient_selectivity = mean(nutrient_trueFished - nutrient_nullFished, na.rm = T), 
                       sd_nutrient_selectivity   = sd(nutrient_trueFished - nutrient_nullFished, na.rm = T)))
     
   })
   
   # bind outputs across nutrients
   country_nutrient_simulation[[i]] <- bind_rows(nutrient_output_country, .id = 'nutrient')
   
   # get the coountries fished species list based on our analysis
   country_species[[i]] <- test_country_fished

}

# compile the outputs from the loop
nutrient_sim_all <- bind_rows(country_nutrient_simulation)

# how  many species per country
country_species_count <- sapply(country_species, function(x) length(unique(x)))
length(country_species_count[!country_species_count<2])
# 54
mean(country_species_count[!country_species_count<2])
# 161.0185
sd(country_species_count[!country_species_count<2])
# 185.1912
min(country_species_count[!country_species_count<2])
# 4
max(country_species_count[!country_species_count<2])
# 730
length(unique(do.call(c, country_species[!country_species_count<2])))
# 1166

# key caveats here is that there is still a low number of species in the 'fished'
# nationally categories, even when considered at the family level which could be a large underestimate of the locally fished species.


#### 3. Format outputs for plotting ----

# # split based on nutrients
# nutrient_sim_list <- split(nutrient_sim_all, nutrient_sim_all$nutrient)
# 
# for(i in 1:length(nutrient_sim_list)){
#   
#   # get one list
#   test_plot_data <- nutrient_sim_list[[i]]
#   
#   # get nutrient name for saving outputs
#   nutrient_name <- unique(test_plot_data$nutrient)
#   
#   # remove countries with only one species
#   test_plot_data <- na.omit(test_plot_data)
#   
#   # join in with country names
#   test_plot_data <- left_join(test_plot_data, social %>% dplyr::select(GID_0, Country_GADM))
#   
#   # set the levcels
#   levels <- unique(test_plot_data$Country_GADM[order(test_plot_data$mean_nutrient_selectivity)])
#   
#   # set levels of the countries by the mean null differences
#   test_plot_data$Country_GADM <- factor(test_plot_data$Country_GADM, 
#                                  levels = levels)
#   
#   
#   # set colours
#   if(nutrient_name == 'biomass_index_wide'){col_ramp <- colorRampPalette(c('gray75', 'gray50', 'black'))(10)}
#   if(nutrient_name == 'calcium_wide'){      col_ramp <- colorRampPalette(c('gray75', '#9efffd', '#00fffb'))(10)}
#   if(nutrient_name == 'iron_wide'){         col_ramp <- colorRampPalette(c('gray75', '#ffe4c4','#ff8a00'))(10)}
#   if(nutrient_name == 'vitamina_wide'){     col_ramp <- colorRampPalette(c('gray75', '#d4ffd6','#85ff8a'))(10)}
#   if(nutrient_name == 'zinc_wide'){         col_ramp <- colorRampPalette(c('gray75', '#ffe3f3','#ff21a1'))(10)}
#   
#   suppressWarnings(dir.create('figures-final-v4/05-nutrient-simulation-FAMILY/', recursive = T))
#   png(filename = paste0('figures-final-v4/05-nutrient-simulation-FAMILY/', nutrient_name, '-simulationRDA.png'), 
#       width = 2000, height = 2000, res = 300, bg = 'transparent')
#   # try plotting
#   print(ggplot(data = test_plot_data) + 
#           geom_density_ridges(aes(y = Country_GADM, x = nutrient_nullFished), col = 'black', lwd = 0.1, fill = 'gray75') + 
#           geom_point(aes(y = Country_GADM, x = nutrient_trueFished, fill = mean_nutrient_selectivity), 
#                      pch = 21, col = 'black', size = 2) + 
#           theme_bw() + 
#           theme(legend.position = 'none', 
#                 panel.grid.major.x = element_blank(), 
#                 panel.grid.minor.x = element_blank(), 
#                 aspect.ratio = 2) + 
#           scale_fill_gradientn(colours = col_ramp) + 
#           xlab(NULL) + 
#           ylab(NULL) + 
#           ggtitle(unique(nutrient_name)))
#   dev.off()
# 
#   
# }

#### 4. Create plots for nutrient optimality ----

nutrient_sim_all_plot <- left_join(nutrient_sim_all, social %>% dplyr::select(GID_0, Country_GADM))

# calculate optimality
nutrient_sim_all_plot$nutrient_optimality <- nutrient_sim_all_plot$nutrient_trueFished_raw / nutrient_sim_all_plot$max_nutrient

nutrient_sim_all_plot <- nutrient_sim_all_plot %>% 
  group_by(Country_GADM) %>% 
  do(max_nutrient_mean = mean(.$max_nutrient, na.rm = T), 
     fished_nutrient_mean = mean(.$nutrient_trueFished_raw, na.rm = T), 
     optimality_nutrient_mean = mean(.$nutrient_optimality, na.rm = T)) %>% 
  unnest(max_nutrient_mean, 
         fished_nutrient_mean, 
         optimality_nutrient_mean) %>% 
  left_join(nutrient_sim_all_plot, .)

# estimate mean optimality

levels <- unique(nutrient_sim_all_plot$Country_GADM[order(nutrient_sim_all_plot$optimality_nutrient_mean)])

# set levels of the countries by the mean null differences
nutrient_sim_all_plot$Country_GADM <- factor(nutrient_sim_all_plot$Country_GADM, 
                                             levels = levels)

# make plot of the maximum nutrient through simulated 'optimized' fishing
png(filename = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-allNutrients_maximum.png', 
    width = 1900, height = 1900, res = 300)
RDA_plot <- nutrient_sim_all_plot %>% dplyr::select(Country_GADM, max_nutrient, nutrient_trueFished_raw, nutrient) %>% unique() %>% na.omit() %>% data.frame()
ggplot() + 
  geom_bar(data = RDA_plot, 
           aes(x = Country_GADM, y = max_nutrient, fill = nutrient),
           alpha = 0.2,  stat = 'identity') + 
  geom_bar(data = RDA_plot, 
           aes(x = Country_GADM, y = nutrient_trueFished_raw, fill = nutrient), 
           stat = 'identity') + 
  geom_col(data = RDA_plot, 
           aes(x = Country_GADM, y = max_nutrient), 
           stat = 'identity', col = 'black', fill = 'transparent') + 
  facet_wrap(~nutrient, nrow = 4) + 
  theme_bw() + 
  theme(strip.text = element_blank(), 
        panel.grid = element_blank(), 
        axis.text.x = element_text(angle = 45, hjust = 1, margin = margin(t = 0, r = 10, b = 0, l = 10, unit = "pt")), 
        legend.position = 'none', 
        plot.margin = margin(5,5,5,10)) + 
  scale_colour_manual(breaks = c('calcium_wide', 'iron_wide', 'vitamina_wide', 'zinc_wide'), 
                      values = c('#00D1CD', '#ff8a00', '#00ad0b', '#FF76C5')) + 
  scale_fill_manual(breaks = c('calcium_wide', 'iron_wide', 'vitamina_wide', 'zinc_wide'), 
                      values = c('#00D1CD', '#ff8a00', '#00ad0b', '#FF76C5')) + 
  xlab(NULL) + 
  ylab('nutrient RDA per 100g (%)')
dev.off()

#### 5. Create plots for nutrient selectivity  ----

nutrient_sim_all_plot <- left_join(nutrient_sim_all, social %>% dplyr::select(GID_0, Country_GADM))

# mean across all nutrients to estimate the ordering of the plots
nutrient_sim_all_plot <- nutrient_sim_all_plot %>% 
  group_by(GID_0) %>% 
  do(all_nutrient_mean_deviation = mean(.$nutrient_selectivity, na.rm = T)) %>% 
  unnest(all_nutrient_mean_deviation) %>% 
  left_join(nutrient_sim_all_plot, .)

# set the levels based ono the mean values above
levels <- unique(nutrient_sim_all_plot$Country_GADM[order(nutrient_sim_all_plot$all_nutrient_mean_deviation)])

# set levels of the countries by the mean null differences
nutrient_sim_all_plot$Country_GADM <- factor(nutrient_sim_all_plot$Country_GADM, 
                                             levels = levels)

# make selectivity data
selectivity_data <- nutrient_sim_all_plot %>% 
  dplyr::select(Country_GADM, max_nutrient, mean_nutrient_selectivity, sd_nutrient_selectivity, nutrient) %>% 
  unique() %>% na.omit() %>% 
  mutate(nutrient_selectivity    = mean_nutrient_selectivity*100, 
         nutrient_selectivity_sd = sd_nutrient_selectivity*100) %>% 
  filter(nutrient != 'biomass_index_wide') %>% 
  group_by(nutrient) %>% 
  nest() %>% 
  mutate(max_nutrient_scaled = purrr::map(data, ~as.numeric(scale(.$max_nutrient)))) %>% 
  unnest() %>% 
  ungroup()

# country point plots
png(filename = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-nutrient-selectivity.png', 
    width = 1500, height = 2200, res = 300)
ggplot(data = selectivity_data) + 
  geom_hline(aes(yintercept = 0)) + 
  geom_point(aes(x = Country_GADM, y = nutrient_selectivity, col = nutrient, size = max_nutrient_scaled)) + 
  geom_linerange(aes(x = Country_GADM, 
                     ymax = nutrient_selectivity + (nutrient_selectivity_sd*2),
                     ymin = nutrient_selectivity - (nutrient_selectivity_sd*2), 
                     col = nutrient)) + 
  facet_wrap(~nutrient, nrow = 4) + 
  theme_bw() + 
  theme(strip.text = element_blank(), 
        panel.grid = element_blank(), 
        axis.text.x = element_text(size = 7.5, angle = 45, hjust = 1, margin = margin(t = 0, r = 10, b = 0, l = 10, unit = "pt")), 
        legend.position = 'none', 
        plot.margin = margin(5,5,5,10)) + 
  scale_colour_manual(breaks = c('biomass_index_wide', 'calcium_wide', 'iron_wide', 'vitamina_wide', 'zinc_wide'), 
                      values = c('gray75', '#00D1CD', '#ff8a00', '#00ad0b', '#FF76C5')) + 
  xlab(NULL) + 
  ylab('RDA nutrient selectivitiy (%)')
dev.off()

# density_plots <- ggplot() + 
#   geom_hline(aes(yintercept = 0)) + 
#   geom_boxplot(data = nutrient_sim_all_plot %>% dplyr::select(Country_GADM, mean_nutrient_selectivity, nutrient) %>% unique() %>% na.omit(), 
#                  aes(y = mean_nutrient_selectivity*100, x = nutrient, fill = nutrient), 
#                position = 'identity', alpha = 1) + 
#   theme_bw() + 
#   theme(panel.grid = element_blank(),
#         panel.border = element_blank(), 
#         axis.line.y = element_line(), 
#         axis.text.x = element_blank(), 
#         axis.ticks.x = element_blank(), 
#         legend.position = 'none') + 
#   xlab(NULL) + 
#   ylab(NULL) + 
#   scale_fill_manual(breaks = c('calcium_wide', 'iron_wide', 'vitamina_wide', 'zinc_wide'), 
#                       values = c('#00D1CD', '#ff8a00', '#00ad0b', '#FF76C5'))
#   
# png(filename = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-allNutrients.png', 
#     width = 2400, height = 1200, res = 300)
# cowplot::plot_grid(country_plots, 
#                    density_plots, 
#                    axis = 'lr', 
#                    align = 'h', 
#                    rel_widths = c(2, 0.5))
# dev.off()

#### 6. Nutrient optimality summary statistics ----

nutrient_sim_all_plot$nutrient_optimality <- nutrient_sim_all_plot$nutrient_trueFished_raw / nutrient_sim_all_plot$max_nutrient

nutrient_sim_all_plot %>% 
  dplyr::select(nutrient, GID_0, max_nutrient, nutrient_optimality, nutrient_trueFished_raw) %>% 
  unique() %>% 
  group_by(nutrient) %>% 
  do(mean_Max     = mean(.$max_nutrient, na.rm = T), 
     sd_Max       = sd(.$max_nutrient, na.rm = T),
     min_Max      = min(.$max_nutrient, na.rm = T),
     max_Max      = max(.$max_nutrient, na.rm = T),
     mean_Raw     = mean(.$nutrient_trueFished_raw, na.rm = T), 
     sd_Raw       = sd(.$nutrient_trueFished_raw, na.rm = T),
     min_Raw      = min(.$nutrient_trueFished_raw, na.rm = T),
     max_Raw      = max(.$nutrient_trueFished_raw, na.rm = T),
     mean_optimality = mean(.$nutrient_optimality, na.rm = T), 
     sd_optimality   = sd(.$nutrient_optimality, na.rm = T),
     more_than_50_perc_max = sum(.$nutrient_optimality > 0.5, na.rm = T), 
     n_countries = length(na.omit(.$nutrient_optimality))) %>% 
  unnest(colnames(.)) %>% 
  mutate_at(.vars = vars(mean_Max:n_countries), .funs = function(x) signif(x, digits = 2)) %>% 
  na.omit() %>% 
  t() %>% 
  write.csv(., file = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-nutrient-optimality-statistics.csv')



#### 7. Nutrient selectivity summary statistics ----

nutrient_statistics_summary <- nutrient_sim_all_plot %>% 
  na.omit(nutrient_sim_all_plot) %>% 
  group_by(nutrient, GID_0, Country_GADM) %>%
  do(t_test = broom::tidy(t.test(.$nutrient_selectivity))) %>% 
  unnest() %>% 
  group_by(nutrient) %>% 
  do(mean_estimate  = mean(.$estimate, na.rm = T),
     sd_estimate    = sd(.$estimate, na.rm = T),
     improvement_0  = sum(.$estimate > 0   & .$estimate < 0.1 &  .$p.value < 0.001) , 
     improvement_10 = sum(.$estimate > 0.1 & .$estimate < 0.2 &  .$p.value < 0.001), 
     improvement_20 = sum(.$estimate > 0.2 & .$p.value < 0.001), 
     decline_0  = sum(.$estimate  < 0   & .$estimate  > -0.1  &  .$p.value < 0.001), 
     decline_10 = sum(.$estimate < -0.1 & .$estimate  > -0.2  &  .$p.value < 0.001), 
     decline_20 = sum(.$estimate < -0.2 & .$p.value < 0.001), 
     countries_any_improvement = .$Country_GADM[which(.$estimate > 0 & .$p.value < 0.001)],
     countries_any_decline     = .$Country_GADM[which(.$estimate < 0 & .$p.value < 0.001)],
     countries_big_improvement = .$Country_GADM[which(.$estimate > 0.2 & .$p.value < 0.001)],
     countries_big_decline     = .$Country_GADM[which(.$estimate > -0.2 & .$p.value < 0.001)],
     significant_0.001 = sum(.$p.value < 0.001) / length(.$estimate), 
     n_countries       = length(unique(.$GID_0))) %>% 
  unnest(cols = c(mean_estimate, sd_estimate, 
                  improvement_0, improvement_10, improvement_20, 
                  decline_0, decline_10, decline_20, 
                  significant_0.001, n_countries))

big_improve_countries <- nutrient_statistics_summary %>% 
  dplyr::select(nutrient, countries_big_improvement) %>% 
  unnest()

write.csv(nutrient_statistics_summary %>% 
            dplyr::select(nutrient, mean_estimate, sd_estimate, 
                          improvement_0, improvement_10, improvement_20, 
                          decline_0, decline_10, decline_20, 
                          significant_0.001, n_countries) %>% 
            t(), 
          file = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-selectivity-statistics.csv')

# summary table
writexl::write_xlsx(
  nutrient_sim_all_plot %>% 
    na.omit() %>% 
    group_by(nutrient, GID_0) %>% 
    dplyr::select(nutrient, GID_0, nutrient_selectivity) %>% 
    do(mean_GID     = mean(.$nutrient_selectivity, na.rm = T)*100) %>%
    unnest() %>% 
    group_by(nutrient) %>% 
    dplyr::select(nutrient, mean_GID) %>% 
    unique() %>% 
    do(mean_selectivity  = paste0(round(mean(.$mean_GID, na.rm = T)), ' %'),
       sd_selectivity    = paste0(round(sd(.$mean_GID, na.rm = T)), ' %'),
       min_selectivity   = paste0(round(min(.$mean_GID, na.rm = T)), ' %'),
       max_selectivity   = paste0(round(max(.$mean_GID, na.rm = T)), ' %'),
       decline_10 = sum(.$mean_GID < -10), 
       any_decline = sum(.$mean_GID < 0), 
       any_improvement = sum(.$mean_GID > 0),
       improvement_10 = sum(.$mean_GID > 10), 
       n_country = length(.$mean_GID)) %>% 
    unnest() %>% 
    dplyr::rename('Micronutrient' = nutrient, 
                  'Mean' = mean_selectivity, 
                  'SD'   = sd_selectivity, 
                  'Min' = min_selectivity, 
                  'Max' = max_selectivity, 
                  '< -10% S' = decline_10, 
                  '< 0% S'   = any_decline, 
                  '> 0% S'   = any_improvement, 
                  '> 10% S'  = improvement_10, 
                  'No. countries' = n_country) %>% 
    mutate(Micronutrient = recode(.$Micronutrient, 
                             'calcium_wide' = 'Calcium', 
                             'iron_wide' = 'Iron',
                             'vitamina_wide' = 'Vitamin A',
                             'zinc_wide' = 'Zinc')),
  path = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-selectivity-summary.xlsx')



### Create summary table with Zfished, Znull, Zmax and optimality and selectivity summarised across countries for each nutrient ----

nutrient_sim_all_plot %>% 
  dplyr::select(GID_0, nutrient, max_nutrient, nutrient_trueFished_raw, nutrient_nullFished_raw, nutrient_optimality, mean_nutrient_selectivity) %>% 
  group_by(GID_0, nutrient) %>% 
  # average  over 999 simulationos
  do(Zmax = mean(.$max_nutrient, na.rm = T), 
     Zfished = mean(.$nutrient_trueFished_raw, na.rm = T),
     Znull = mean(.$nutrient_nullFished_raw, na.rm = T),
     optimality = mean(.$nutrient_optimality, na.rm = T)*100,
     selectivity = mean(.$mean_nutrient_selectivity, na.rm = T)*100) %>% 
  unnest() %>% 
  na.omit() %>% 
  ungroup() %>% 
  # average over all countries
  group_by(nutrient) %>% 
  do(Zmax = paste0(signif(mean(.$Zmax, na.rm = T),2), ' ± ', signif(sd(.$Zmax, na.rm = T), 2)),
     Zfished = paste0(signif(mean(.$Zfished, na.rm = T),2), ' ± ', signif(sd(.$Zfished, na.rm = T),2)),
     Znull = paste0(signif(mean(.$Znull, na.rm = T),2), ' ± ', signif(sd(.$Znull, na.rm = T),2)),
     optimality = paste0(signif(mean(.$optimality, na.rm = T),2), ' ± ', signif(sd(.$optimality, na.rm = T),2)),
     selectivity = paste0(signif(mean(.$selectivity, na.rm = T),2), ' ± ', signif(sd(.$selectivity, na.rm = T),2))) %>% 
  unnest() %>% 
  ungroup() %>% 
  dplyr::rename('Micronutrient' = nutrient) %>% 
  mutate(Micronutrient = recode(.$Micronutrient, 
                                'calcium_wide' = 'Calcium (mg)', 
                                'iron_wide' = 'Iron (mg)',
                                'vitamina_wide' = 'Vitamin A (µg)',
                                'zinc_wide' = 'Zinc (mg)')) %>% 
  writexl::write_xlsx(., path = 'figures-final-v4/05-nutrient-simulation-FAMILY/RDA-all-metric-summary.xlsx')
