This README.txt file was generated on 2022-02-12 by Michele de Sa Dechoum


GENERAL INFORMATION

1. Title of Dataset: Data from: Effects of time since invasion and control actions on a coastal ecosystem invaded by non-native pine trees.

2. Author Information
	Corresponding Investigator 
		Name: Dr Michele de Sa Dechoum
		Institution: Universidade Federal de Santa Catarina, Florianopolis, Brazil
		Email: mdechoum@gmail.com

	Co-investigator 1
		Name: Ms Leticia Mesacasa
		Institution: Universidade Federal de Santa Catarina, Florianopolis, Brazil

	Co-investigator 2
		Name: Ms Leonardo Macagnan
		Institution: Universidade Federal de Santa Catarina, Florianopolis, Brazil

	Co-investigator 3
		Name: Dr Pedro Fiaschi
		Institution: Universidade Federal de Santa Catarina, Florianopolis, Brazil
	
	


3. Date of data collection: August - October 2018

4. Geographic location of data collection: Dunas da Lagoa da Conceicao Municipal Park, Florianopolis, Brazil

5. Recommended citation for this dataset: Mesacasa, Leticia et al. (2022), Data from: Effects of time since invasion and control actions on a coastal 
ecosystem invaded by non-native pine trees. Dryad Digital Repository, https://doi.org/10.5061/dryad.63xsj3v43


DATA & FILE OVERVIEW

1. Description of dataset

These data were generated to evaluated the effects of invasion by Pinus elliottii over time on structural and functional parameters of plant communities in a 
subtropical coastal ecosystem. Structural parameters (abundance, plant cover, richness, diversity and composition of woody and non-woody native species) and 
functional traits (dispersal syndrome, fruit type, maximum height and shade tolerance) of woody native species were compared between a non-invaded area, 
an invaded area where pines were controlled, an area of recent pine invasion, and an area of older pine invasion. 


2. Methodological information

Data collection was conducted between August and October, 2018, in four areas between sand dunes with similar environmental characteristics. Four conditions were evaluated: A) area not invaded by P. eliottii, defined as non-invaded (NI – 0.075 ha); B) area previously invaded, where pines were managed in 2013, defined as managed area (MA – 0.075 ha); C) area invaded more recently, defined as recent invasion (RI – 0.025 ha); and D) area invaded for a longer time, defined as older invasion (OI – 0.050 hectares) (Figure 1). The total area of plots was 0.225 hectares. All plots and subplots were set up in areas between sand dunes where the original vegetation was characterized by herbs and shrubs (Guimarães, 2006).
The NI condition represents the control area – i.e., what the other areas would look like if pines had not invaded (Figure 1A). In the MA condition, seedlings were pulled out (< 50 cm height) and juveniles (> 50 cm height) and adults cut down in 2013 - in other words, every pine tree or seedling was removed (Dechoum et al., 2019). All residue of control was left in the area to degrade (Figure 1B). The estimated number of pines eliminated, including adults, juveniles, and seedlings in the area, was 16,000 (ca. 114 pines/ha) (Dechoum et al., 2019). In the RI condition, the herb-shrub physiognomy is still dominant, and the majority of pines consist of seedlings and small to medium size juveniles, as well as some scattered adults (Figure 1C). The forest physiognomy in the OI condition is dominated by adult pines, with scattered native shrubs and low herb cover (Figure 1D). There were no pine seedlings, only a few juvenile trees. None of the invaded areas (RI and OI) had been subjected to previous conversion and/or other management intervention. We postulate that the difference in time since invasion is a consequence of density and age of adult pines planted in private properties in the park surroundings (see subitem 2.1). In other words, there was a higher density of larger/older adult trees in private areas closer to the OI condition compared with the RI condition.
Ninety 5 x 5 m plots were set up in the four conditions. Conditions NI and MA comprised 30 plots each, 10 plots were set up in RI and 20 in OI. The minimum distance between plots was 20 meters. The number of plots varied due to the size of the areas in each of the four conditions.
All native woody plants above 1 meter in height were identified and had their height measured in each plot. Four subplots measuring 1 x 1 m were set up at the vertices of each plot, totalling 360 subplots. All plants between 0.1 and 1 m in height were identified at the species level (whenever possible) and categorized as “woody” or “non-woody”. Plants not identified in the field were collected for later identification with identification keys and taxonomic references, or with support from experts. Among the specimens not identified at the genus or species level, most are in family Poaceae (grasses), which are very hard to distinguish if not fertile, or in families Myrtaceae and Lauraceae, which are two of the richest woody species families along the Brazilian coast, therefore often hard to identify from sterile material (see Appendix 1).
Percentage of plant cover by woody and non-woody species and class of soil exposure were also measured in the subplots. The proportion of soil without live plant cover in the subplots was classified as exposed soil. Percentage of cover was divided in the following classes: Class 1: 0 a 5% (2.5%); Class 2: 5 to 15% (10%); Class 3: 15 to 25% (20%); Class 4: 25 to 50% (37.5%); Class 5: 50 to 75% (62.5%) e Class 6: 75 to 100% (87.5%) (Assumpção & Nascimento, 2000). Median values were used in statistical analyses.
All pines in the RI and OI plots were counted and the perimeter at ground level (PGL) of all trees with PGL ≥ 25 cm was measured. All the stumps remaining after pine control in MA were counted and classified in two size classes: trees with PGL ≥ 25 cm (adults) and trees with PGL < 25 cm (juveniles). 
All woody species taller than 1 m in the plots were classified according to four functional traits: (1) dispersal syndrome: anemochory (wind), zoochory (animals) or autochory (self-dispersed); (2) fruit type: dry dehiscent or indehiscent, fleshy dehiscent or indehiscent; (3) maximum height of woody plants measured in the plots; and (4) shade tolerance: tolerant or intolerant. These four functional traits were selected from scientific literature (Reitz, 1965; van der Pijl, 1982; Carvalho, 2003, 2008, 2010; Lorenzi, 2009; Pires et al., 2009; Seubert et al., 2017; Flora do Brasil, 2020).



3. File List and data-specific information per file: 

	File 1 Name: Species_list_subplots.csv
	File 1: Description: All species sampled in plots, including woody and non-woody species
	Number of variables: 6
	Number of plants/rows: 2104
	Variable List: 
		cond: if the plant was sampled in the invaded, non-invaded or managed area
		plot: plot ID
		subplot: subplot ID (within each plot)
		species: species ID
		n_ind: plant ID
		caract: if woody or non-woody species

	File 2 Name: Cover_subplots.csv
	File 2 Description: Percentage of cover by bare soil or vegetation in each sampled subplot
	Number of variables: 6
	Number of subplots/rows:360
	Variable List: 
		cond:if the plot was established in the invaded, non-invaded or managed area
		plot: plot ID
		subplot: subplot ID (within each plot)
		bare_soil: percentage of bare soil in each subplot
		cover_woody: percentage of cover of woody species in each subplot
		cover_n_woody: percentage of cover of non-woody species in each subplot

	File 3 Name: Woody_Species_Height_plots.csv
	File 3 Description: Height of each woody plant sampled in the plots
	Number of variables: 5
	Number of plants/rows: 1153
	Variable List: 
		cond: if the plant was sampled in the invaded, non-invaded or managed area
		plot: plot ID
		n_ind: plant ID
		species: species ID
		height_cm: height of each sampled plant in centimeter

	File 4 Name: N_pine_trees_plots.csv
	File 4 Description: Number of adults and regenerant pine trees sampled in each plot
	Number of variables: 4
	Number of pines/rows: 60
	Variable List: 
		cond: if the pine tree was sampled in the invaded or in the managed area
		plot: plot ID
		n_adults: number of adult pine trees sampled in each plot
		n_reg: number of regenerant (seedlings + saplings) pine trees sampled in each plot


	File 5 Name: CGL_pine_trees.csv
	File 5 Description: Circunference at ground level (CGL) of all pine trees sampled in plots
	Number of variables: 3
	Number of trees/rows: 123
	Variable List: 
		plot: Plot ID
		n_ind: Pine tree ID
		cgl: Circunference at ground level of each sampled pine tree

	File 6 Name: Funct_traits_species.csv
	File 6 Description: Functional traits of all identified species
	Number of variables: 5
	Number of species/rows: 39
	Variable List: 
		Species: species ID
		Avg_height: average height (based on field measurements)
		Shade_tolerance: if the species is shade tolerant or not (yes or no)
		Fruit_type: category of fruit type
		Disp_synd: category of dispersal syndrome

