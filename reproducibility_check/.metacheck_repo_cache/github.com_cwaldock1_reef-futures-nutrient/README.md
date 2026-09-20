## Waldock et al. (2024) "Decoupling of micronutrients in tropical fishes between ecosystem availability and realised fisheries catch". People and Nature. 

Here we provide scripts to reproduce all figures and supporting analyses presented in our manuscript.

### **Code:**

The analyses are seperated into two main scripts present in RMarkDown files, also viewable as html files. These are presented in 01-SAUP-nutrient-targetting (Figure 1) and 02-optimality-and-sensitivity (Figures 2-4). The supporting analyses are provided in the seperated folders.

**01-SAUP-nutrient-targetting** *- Figure 1.* This script provides an empirical comparison between reconstructed catch estimates from the Sea Around Us data, and the micronutrient content in fishes modelled using SDMs.

**02-optimality-and-sensitivity** *- Figure 2, 3, 4 + Table 1.* This script provides the simulations required to estimate two new metrics of fisheries micronutrient capture: optimality and selectivity. Here we assess the nutrient content of countries fished species compared to those modelled-as-available in the ecosystem (through SDMs). We compare the set of captured species to the set of most nutrient rich species (optimality) and compare the set of captured species to randomised subsets of the community (selectivity).

**Supporting analyses.** This set of scripts test various assumptions about:

-   Our definitions of fished species using family level definitions vs. genus level definitions i.e., including all species within the family as "fished" if a species is recorded as fished in that family (sensitivity-family-fished).

-   Undersampling errors, but subsampling each datasets species pool independently, and together (sensitivity-analysis-downsampling).

-   Direct use of SCUBA surveys for a smaller subset of species and countries to estimate optimality and selectivity, compared to SDM outputs in the main manuscript (sensitivity-analysis-survey-biomass).

-   Use of mean vs. summed aggregates of species biomass across countries cells (02-optimality-and-selectivity_checkAGG.Rmd)

### **Data:**

Data to reproduce the analyses presented in the main manuscript are stored at FigShare here which requires downloading prior to running the above scripts.

Files required:

-   preamble.RData

    -   This data is contains required objects on multiple themes necessary to join with the output of the *species nutrients by cell* matrix and SAU data. A brief summary is provided below.

        -   *global_grid*: the grid system as a raster used as predictive grid system on which SDM outputs are projected.

        -   *countries*: the countries boundaries data are from gadm version 3.6 (<https://gadm.org/old_versions.html>)

        -   *social:* contains socio-economic data per country including prevelance of inadequate intake (Beal et al. 2017), spatially explicit population size (Gao et al. 2017), human development index (United Nations development programme) and diet (Micha et al. 2015).

        -   *nuts:* nutrient data provided by Eva Maire, available at fishbase with model details documented at <https://github.com/mamacneil/NutrientFishbase>; accessed 21.07.2021.

        -   *fished_list:* all species recorded as fished as described in the main manuscript

        -   *sp_conservation*: species conservation related traits.

        -   *keep_species:* species retained based on conservation criteria

        -   *reef_associated_nations:* countries identified as reef associated based on the data-based thresholds in our analyses.

        -   *country_cells*: grid cells per country based on the *global_grid* system.

-   Cell X Species matrices stored in "*final-outputs-QC2024*".

    -   These objects are outputs of SDM models and biomass models that have been converted to represent micronutrient concentrations of species, and micronutrient mass of species within each grid cell. These are presented for four micronutrients (calcum, iron, vitamin A and zinc) and in terms of both micronutrient concentration and micronutrient mass. We also provide the wide matrix which forms the biomass data.

-   saup_country_tonnes.RDS

    -   Fisheries catch reconstructions were manually downloaded and compiled for all Exclusive Economic Zones from <https://www.seaaroundus.org/data/#/eez>. These were further processed to represent all taxa caught, whether they are for direct consumption and tonnage.

-   Spp_NutrientPred_REEF_FUTURESJune2021.csv contains the provided nutrient data in its raw format along with matches to fishbase taxonomy system.

### **Primary data:**

Primary data underlying the species distribution models are not the property of the corresponding author so only the derived outputs from analyses are available here. Please contact the corresponding author for further information.

### References:

Beal, T., Massiot, E., Arsenault, J.E., Smith, M.R. & Hijmans, R.J. (2017). Global trends in dietary micronutrient supplies and estimated prevalence of inadequate intakes. *PLOS ONE*, 12, e0175554.

Gao, J. 2017. *Downscaling Global Spatial Population Projections from 1/8-degree to 1-km Grid Cells*. NCAR Technical Note NCAR/TN-537+STR, <https://doi.org/10.5065/D60Z721H>

Jones, B. and B. C. O’Neill. 2016. Spatially explicit global population scenarios consistent with the Shared Socioeconomic Pathways. *Environmental Research Letters*, 11: 084003. <https://doi.org/10.1088/1748-9326/11/8/084003>

Micha, R., Khatibzadeh, S., Shi, P., Andrews, K.G., Engell, R.E., Mozaffarian, D., *et al.* (2015). Global, regional and national consumption of major food groups in 1990 and 2010: a systematic analysis including 266 country-specific nutrition surveys worldwide. *BMJ Open*, 5, e008705.
