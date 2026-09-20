# The Steller’s Sea-Eagle in North America: an economic assessment of birdwatchers traveling to see a vagrant raptor

### [Brent S. Pease](https://peaselab.com), [Neil A. Gilbert](https://gilbertecology.com), [William R. Casola](https://scholar.google.com/citations?user=5Tepgy4AAAAJ), & [Kofi Akamani](https://academics.siu.edu/agriculture/forestry/faculty/akamani-kofi.php)

### Data/code DOI: [![DOI](https://zenodo.org/badge/462378107.svg)](https://zenodo.org/badge/latestdoi/462378107)

#### Please contact the first author for questions about the code or data: Brent S. Pease (bpease1@siu.edu)
__________________________________________________________________________________________________________________________________________

## Abstract:  
1.	Birdwatching—a cultural ecosystem service—is among the most popular outdoor recreational activities. Existing economic valuations of birdwatching typically overlook the economic contributions of birdwatchers travelling to see vagrant (out-of-range) birds. 
2.	Economic valuations of vagrant birdwatching are few, and to date, no valuation of a large, charismatic vagrant species—or of a recurring individual vagrant bird—has been reported.
3.	During 2020–2022, a vagrant Steller’s Sea-Eagle (Haliaeetus pelagicus) was reported in several locations in North America, representing the first record of this species in these locations. In Winter 2020–2021, the eagle spent nearly a month on the eastern seaboard of the United States, and thousands of people traveled to see it.
4.	We conducted an online survey of individuals who traveled to see the eagle to estimate the individual and collective non-consumptive use value of this vagrant birdwatching event. Using individual travel cost methodology, we estimated an average individual expenditure and, together with estimates of the total number of birdwatchers, we estimated non-consumptive use value of the vagrant birdwatching event. Finally, we used a willingness to pay framework (via hypothetical donations to view the eagle) to evaluate the non-consumptive use consumer surplus of the event.
5.	We estimated that, on average, individual birdwatchers spent \$180 USD (95% CI = \$156–\$207) ignoring travel time—or \$277 (95% CI = \$243–\$314) when accounting for travel time—to view the eagle. Furthermore, we estimated between 2,115 and 2,645 individuals travelled to see the eagle during December 2021 to January 2022. Thus, we estimated that the eagle generated a total expenditure between \$380,604 and \$476,626, or between \$584,373 and \$731,809 when accounting for travel time. Finally, based on travelers’ willingness to pay, we estimated a non-consumptive use consumer surplus of the event between \$139,036 and \$174,114.
6.	Assigning economic value to nature gives policymakers and business leaders footing to advance conservation in decision-making. Although often overlooked in these decisions, vagrant birds supply ephemeral ecosystem services that might bolster community development efforts, particularly if vagrancy events occur with some predictability (e.g., recurring annually).


## Repository Directory

### [Scripts](./Scripts): Contains code for cleaning, processing, and analyzing survey and supplemental data
* 101 - Data Prep - bring data together and get distances.R - script used to read in Survey Monkey responses and geocode zipcodes provided.
* 102 - Data Prep - calculate distance of multiple trips for an individual.R - script used to geocode zipcodes of individuals who took several trips.
* 103 - Data Prep - add ebird status to cleaned data.R - supplemental script to 101 that added the respondent's ebird status - whether they reported observation on eBird - to the cleaned data frame in R.
* 104 - Data Prep - cleaning_script_v01.R - script used to prep data frames for analysis in `rstan`.
* 201 - Analysis.R - 'master' analysis script. This was used to calculate individual and cumulative spending.
* 202 - Analysis - Sociodemographics.R - script used for summarizing sociodemographics and describing spending across groups.
* 203 - Analysis - driving distance.R - quick script used for generating summary statistics of driving distance.
* 204 - Analysis - get twitter user information.R - script for downloading and summarizing tweets about steller's sea eagle.
* 205 - Analysis - analysis_stan_v02.R - script used for analyzing individual and collective spending using `rstan`.
* 206 - Analysis - revision1.R - script for making revisions following reviewer comments.
* 207 - Analysis - reviewer 1 requested table.R - script used for creating summary table requested by reviewer 1.
* 301 - Maps - script for making maps.
* stan_code - folder created for holding output from `rstan`

### [Data](./Data): Contains raw and processed data used in scripts
* cleaned_responses - response data collected from Survey Monkey. Cleaned for reading into R but not manipulated. 
* ebd_stseag_relJun-2022 - eBird data downloaded from basic dataset available on www.ebird.org
* ebd_US_stseag_prv_relApr-2022 - eBird data downloaded from basic dataset available on www.ebird.org
* flight_distances.csv - contains flight distances and times based on respondents zip code information
* maps - contains shapfile of eagle_sightings for making figure 1
* stan_data - processed data in format needed for `rstan`.
* survey_monkey - contains raw, original survey monkey data as well as processed files.
* twitter - stores output from 204 - Analysis - get twitter user information.R.

### [Results](./Results): Contains figures and output
* Figures - folder to hold output figures
* result_summary_v01.csv
* result_summary_v02.csv
* reviewer1_requested_table.csv
* revision_analysis_stan_output_v01.RData
* table of model results.docx
