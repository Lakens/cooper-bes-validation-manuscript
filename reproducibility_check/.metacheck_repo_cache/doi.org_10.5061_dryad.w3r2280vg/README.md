# README
---

1) Trapping Efficiency Dataset


2) APHA Vaccination Records


3) Sett Activity Dataset



## Description of the Data and file structure

1) Trapping Efficiency Dataset
Records of badgers trapped during proactive culling operations of the Randomised Badger Culling Trial (RBCT)

Only records collected in the first five years of RBCT trapping were included in the publication analysis as few areas were culled for longer (resulting in a sparse dataset for years 6 onwards). Records from 2001 were also removed as trapping was abandoned that year in response to a foot and mouth disease outbreak. As we were interested in using the RBCT trapping data to understand how trapping for the purposes of vaccination might vary following culling, records from December to April inclusive were removed as current practice for vaccination projects in England is to only trap from May to November inclusive

**List and description of data fields:**
Season: the trapping season (May to end of November inclusive) was divided up into the following categories in order to assess seasonal variation in trapping efficiency: May-June (early season), July-August (mid season), Sept-Oct (late season) and November (end season)

Trial year: The year of the the RBCT trial (1st, 2nd, 3rd etc year of culling)

Traps caught: The number of traps that successfully caught a badger at a given trapping event

Traps empty: The number of traps that were set at a given trapping event but did not contain a badger

Team code: an anonymised identifier code for each unique trapping team. This was included in the model as a random effect to account for any potential variability in trapping success between operators

Area code: an anonymised identifier code indicating which proactive cull area a given trapping record is from. 

2) APHA Vaccination Records
Records of badgers trapped and vaccinated during Animal and Plant Health Agency vaccination operations

**List and description of data fields:**

Population Type: a descriptor of the type of badger population the data relate to. Post-Culled population is one that has recently been culled, Un-culled Populations are those that have not recently been culled

Year: The year of the vaccination project 

TotalVacNight1: this column and the following two columns contain the summary numbers required for calculation of the Lincoln-Petersen estimate of population size (and subsquently produce an estimate of vaccine coverage). Full details of how to calculate this metric can be found in Benton 2020 Badger vaccination in England; Progress operational effectiveness and participant motivations

PopEst: The population estimate derived from the Lincoln-Petersen method

UpperPopEst: The upper 95% confidence interval of the population estimate

LowerPopEst: The lower 95% confidence interval of the population estimate



3) Sett Activity Dataset
Subset of badger sett activity records from proactive cull areas of the Randomised Badger Culling Trial (RBCT)

**List and description of data fields:**

Year: The year of the the RBCT trial (1st, 2nd, 3rd etc year of culling)

Season: Spring, Summer, Autumn or Winter; included to account for expectation season variation in badger activity and therefore resultant activity at the sett

Active Holes: the number of active sett holes at the identified badger sett

Total Holes: the total number of sett holes identified by the surveyor at the badger sett

SettType: badger sett type; outlier or main as identified by the surveyor

TrialCode: an anonymised identifier code indicating which proactive cull area a given trapping record is from.

Sett_ID_Code: an anonymised identifier code for each sett identified

## Sharing/access Information

Links to other publicly accessible locations of the data:

Records from industry-led badger culls are publicly available (see example 2020 figures: https://www.gov.uk/government/publications/bovine-tb-summary-of-badger-control-monitoring-during-2020/summary-of-2020-badger-control-operations) and therefore have not been archived

