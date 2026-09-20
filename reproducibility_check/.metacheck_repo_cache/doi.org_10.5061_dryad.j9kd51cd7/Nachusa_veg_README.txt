README FOR Nachusa_veg_transect_data1994_2016.csv

File name: Nachusa_veg_transcet_data1994_2016.csv
File author: Elizabeth M. Bach
Author affiliation: The Nature Conservancy, Nachusa Grasslands, Franklin Grove, IL USA
Contact email: elizabeth.bach@tnc.org
Associated publication: Bach, E.M. and Kleiman, B.P. 2021. Twenty years of tallgrass prairie restoration in northern Illinois, USA. Ecological Solutions and Evidence

Data file is comma seperated value spreadsheet.
This data file includes the original cover values, analytical code reduces it to presence/absence for analyses used in the publication. Transects sampled fewer than three times between 1994 and 2016 were not included in the published analyses and are removed in the analytical code. 
Summarized data is also available at www.universalfqa.org at the transect level. 
Statistical analyses performed in R Studio. Code for analyses is available at https://github.com/ebach/Nachusa_plants2021

Column descriptions:
Scientific_name: Genus species, nomenclature was updated to match Wilhelm & Rericha 2017 Flora of the Chicago Region. In cases where the plant was not identified to species, the name appears as Genus sp
Sample_Day: day of the month data was collected, if known. Unknown values=NA
Sample_Month: month of the year data was collected
Sample_Year: year data was collected
Data_Collector: First initial and last name of person who collected field data. In cases with more than 1 person, names separated by “,”
Transect: transect ID number, see Table 1 in Bach & Kleiman for additional details
Unit: Unit name within Nachusa Grasslands where transect is located. This is helpful for internal purposes at Nachusa Grasslands, but was not used in the publication.
Quadrat: number of the quadrat within the transect from which data was collected
Quadrat_size_m: size of the quadrat in m2, in some cases this information was not recorded by the original data collector and EM Bach made the best educated presumption based on number of species and comparison with data known to come from 1m2.
Cover_metric: method used to estimate cover, options include: “presence_absence”, “daubenmire”, and “percent”. Daubenmire is a standard cover class approach with values 1-6 corresponding to range of cover value. “Percent” refers to an exact estimation of percent cover.
Cover_value: cover value originally assigned to each species at each sampling time
C1994: Coefficient of conservatism for the species published in Swink & Wilhelm 1994. Flora of the Chicago Region. Some species present in this dataset were not listed in the 1994 Flora and the cell is left blank. Some plants were not identified to species level, so C value left blank. These C values were originally assigned when the data was collected. Values range 0-10. 
C2016: Coefficient of conservatism for the species published in Wilhelm & Rericha 2016. Flora of the Chicago Region. Values range 0-10. Some plants were not identified to species level, so C value left blank.
Native2016: signifies if the plant species is native or not native to the Chicago region based on Wilhelm & Rericha 2016 Flora of the Chicago Region. Options are “native” and “not-native”. Some plants were not identified to species level, so native value is left blank.
Duration2016: growth duration of the plant species based on Wilhelm & Rericha 2016 Flora of the Chicago Region. Options are “annual”, “biennial”, “perennial”. Some plants were not identified to species level, so duration value is left blank.
Physiognomy2016: Plant species physiognomy based on Wilhelm & Rericha 2016 Flora of the Chicago Region. Options include: “fern”, “forb”, “grass”, “sedge”, “shrub”, “tree”, “vine”. Some plants were not identified to species level, so physiognomy value is left blank.

All unknown values are explictly mentioned above and cells are left blank.

Methodology:
Data was collected at The Nature Conservancy's Nachusa Grasslands (Franklin Grove, IL, USA). Between 1994 and 1996, managers set-up transects in 12 independent sites within the preserve to evaluate and monitor plant community changes in both native and restored prairie units across the preserve (see Bach & Kleiman 2021 for map and additional information). Sites were replicated within three habitat types: native prairie (n=4), restored planted prairie (n=4), and savanna (n=4). Transects in native prairie each included 15 quadrats (1m2) and transects in restored and savanna habitat each included 10 quadrats. All quadrats were spaced approximately 1 m apart on alternating sides of the transect tape. In 1994, we believe 0.5m2 quadrats were used instead of 1m2, although no documentation could verify one way or the other. Given that adjusting the number of species to a per meter basis does not reflect the true species richness at 1m2, we opted to keep the 0.5m2 data in the seven instances that it occurs. In all quadrats, plants were identified to species level. The transects were permanently marked and resampled over time. Due to differences in cover metrics used over the years, Bach & Kleiman (2021) consider species presence/absence only. Original field data was digitized and coalesced into this format. Plant species nomenclature, coefficient of conservatism, and native status were updated to match Wilhelm & Rericha 2017 Flora of the Chicago Region. 

