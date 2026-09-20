# Title of Dataset
How can we tackle interruptions to human-wildlife feeding management? Adding media campaigns to the wildlife manager’s toolbox.

---

This data was collected over 4 key stages based on the management activities currently in action, aiming to reduce human-deer feeding within the site. These stages occurred across 4 years (2018-2021), with each stage representing a summer collection (i.e. June-July) for a consecutive year. These stages included pre-management (Stage 1), introduction of internal controls such as signage, posters, and ranger patrols (Stage 2), interruption of management by Covid-19 (Stage 3), and release of a targeted media campaign across both traditional and social media (Stage 4).

Our dataset encompassed 267 individual herd observations over four years (resulting in 13,714 individual deer observations), with each year representing a different stage in management. Our data includes 77 herds over 15 days in 2018 (management stage 1), 72 herds over 17 days in 2019 (management stage 2), 61 herds over 11 days in 2020 (management stage 3), and 57 herds over 14 days in 2021 (management stage 4). In total our dataset included 139 female herds (9701 individual deer observations including females and immature males) and 128 male herds (4013 individual deer observations). Individual herd observations lasted approximately 1 hour and 15 minutes on average.

We fit a generalised linear model (GLM) following a priori structure with the total number of people who approached to feed each herd as our response variable. Given the nature of our response variable (i.e. count data), we fitted the model with a Poisson distribution of errors. We detected a slight overdispersion and corrected the standard errors using a quasi-GLM model (where the variance is given by φ × μ, where μ is the mean and φ is the dispersion parameter).

In terms of predictors, management stage (4-level categorical predictor) was included to determine the effects of different management controls applied and the effect of the pandemic. This was broken down into stage 1 for pre-controls in 2018, stage 2 for when internal controls were applied in 2019, stage 3 for mid-pandemic 2020, and stage 4 for when the media campaign was released in 2021. Herd size was included as we expected larger herds to attract more people due to their increased visibility. The length of time for which the herd was monitored was included as we anticipated that more feeding interactions would be documented in herds that were observed for longer. The number of total number people present (i.e. in a 250-metre radius of the herd, excluding those exercising or dog-walking) was also included as a proxy for visitor numbers available to interact in the Park. The time of the day was included, along with the month and day of the week, as we expected there may be a temporal effect. Finally, we also included the sex of the herd as a categorical predictor as male fallow deer tend to get closer to human activity than females, which meant they may also engage with more human feeding interactions. Fallow deer naturally sexually segregate outside of the rut (i.e. late September to mid November), so herds at this time were composed of either males only or females with some subadult male offspring. All predictors were screened for collinearity (Dormann et al., 2013) prior to inclusion in the model. The effects were plotted using library effects (Fox, 2003, Fox and Weisberg, 2019) and ggplot2 (Wickham, 2016) with 95% marginal confidence intervals. 

The GLM model explained 60% of variation and the following predictors were flagged as significant: the number of people present, the time of the day, the day of the week, the sex of the herd, and the stage of management. The number of people feeding decreased with the introduction of traditional management actions (i.e. from stage 1 to stage 2). However, numbers increased back to pre-management levels during the pandemic despite reapplying traditional management actions. The number of people feeding then dropped again significantly after the introduction of the media campaign, even lower than it had been during the application of the original traditional management actions in stage 2. As a priori expected, the number of people feeding increased with number of people present, peaked from 13:00-15:00 during the day, and on weekend days compared to Fridays. The number of people feeding was also higher in male herds than in female herds. 



## Description of the data and file structure

This dataset is saved in CSV format. The response variable and predictors outlined above are all included. The column names and descriptions are as follows:

Herd size: the number of individuals in the herd being observed.

Month: the month of the year kept in number format (i.e. 6 = June).

Day of the week: what day of the week the data was collected on.

Monitoring time: how long that herd was observed for (in minutes).

Sex of the herd: whether the herd was made up of males or females with some subadult males (as fallow deer are sexually segregated in the summer months).

Num of people feeding: how many people approached the deer to feed them during the observation period.

Centre timepoint for observation: what time it was at the exact mid-point of the overall observation period.

Num of people present: how many people were present overall from 15 minute scan samples over the entire observation period, excluding those who were cycling or exercising and one person per dog being walked, as they were unlikely to feed. This represents the total amount of people who were available to feed.

Management stage: which stage of management the observation was collected during, as outlined above.


## Sharing/Access information

NA


## Code/Software

NA
