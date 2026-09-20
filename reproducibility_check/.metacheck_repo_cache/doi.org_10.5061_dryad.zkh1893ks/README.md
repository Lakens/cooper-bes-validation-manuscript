# A new Double Observer based census framework to improve abundance estimations in mountain ungulates and other gregarious species with a reduced effort

[https://doi.org/10.5061/dryad.zkh1893ks](https://doi.org/10.5061/dryad.zkh1893ks)

## Description of the data and file structure

We provide the R script to perform computer simulations (DOAS script.R) on the reliability of the 3 census methods testes: block counts, full DO and our proposed DOAS procedure.

The "DOAS_maindata.csv" is a representative subset of the final dataset obtained running the provided script. Each row is a single simulation, the columns are (see paper for details):

* det.p = simulated detection probability
* pop.size= simulated population size 
* mean.group = average simulated group size
* size.effect= multiplying factor for the detectability of a single group compared to a large group
* miscount= miscount effect (average group abundance counted compared to the real one)
* surv.sites= number of sites in which DO is performed for the DOAS
* obs.effect= observer effect (det.p of the second observer compared to the first)
* detp.var= coefficient of variation of detection probability across sites
* totalDO.groupdetect= detectability estimated with the total DO
* totalDO= ratio of individuals estimated with total DO
* census= ratio of individuals estimated with block counts
* groupadjust.censusSR= ratio of individuals estimated with DOAS
* group.detectionSR= detectability estimated with DOAS

## Code/software

DOASscript.R is the R script to obtain all the data in DOAS_maindata.csv
