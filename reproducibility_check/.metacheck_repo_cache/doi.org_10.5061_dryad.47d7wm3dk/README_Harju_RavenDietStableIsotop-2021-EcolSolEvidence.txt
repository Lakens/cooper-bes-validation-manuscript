This README files describes raw and mid-analysis input data for:

Harju, Seth; Olson, Chad; Hess, Jenn; Webb, Stephen (2021), Isotopic analysis reveals landscape patterns in the diet of a subsidized predator, the common raven. Ecological Solutions and Evidence.  Data available at: Dryad, Dataset, https://doi.org/10.5061/dryad.47d7wm3dk

Principal Investigator Contact Information:
Seth Harju
Heron Ecological, LLC
P.O. Box 235
Kingston, ID, 83839, USA
seth@heronecological.com

Co-Investigator Contact Information:
Chad Olson
HWA Wildlife Consulting, LLC
2308 S. 8th St.
Laramie, WY, 82070, USA
chad@hwa-wildlife.com

Date of data collection:
May 21, 2013 to July 3, 2013
May 15, 2014 to July 11, 2014

Geographic location of data collection:
Wyoming, United States of America

Funding sources:
This study was primarily funded by ConocoPhillips with additional funding for analyses provided by BP America Production Company.  The funders played no role in study design, analysis, interpretation, or decision to publish.  

Recommended citation for this dataset:
Harju, Seth; Olson, Chad; Hess, Jenn; Webb, Stephen (2021) Isotopic analysis reveals landscape patterns in the diet of a subsidized predator, the common raven, Dryad, Dataset, https://doi.org/10.5061/dryad.47d7wm3dk

METHODOLOGICAL INFORMATION AND DESCRIPTION

See https://doi.org/10.5061/dryad.47d7wm3dk or Harju et al. (2021) Isotopic analysis reveals landscape patterns in the diet of a subsidized predator, the common raven.  Ecological Solutions and Evidence.

DATA & FILE OVERVIEW

1. File list:
	a) 1Consumer.csv - Input file for MixSIAR program.  Description of columns:
		'Order_'	Unique row identifier.
		'Year'		Year of sample collection.
		'NestID'	Unique nest identifier (samples from two raven chicks collected per nest where possible).
		'dN15'		Difference in ratio of N15/N14 of sample over standard for nitrogen isotopes.
		'dC13'		Difference in ratio of C13/C12 of sample over standard for carbon isotopes.
		'Group'		Integer identifier aligning with 'NestID' for MixSIAR.

	b) 2Source.csv - Input file for MixSIAR program.  Description of columns:
		'Sources'	Potential diet source item.
		'MeandC13'	Mean input carbon isotope ratio.
		'SDdC13'	Standard deviation of carbon isotope ratios.
		'MeandN15'	Mean input nitrogen isotope ratio.
		'SDdN15'	Standard deviation of carbon isotope ratios.
		'n'		Sample size used to calculate mean and standard deviations of ratios. Field tissue samples used for all diet items except 					insects and plants (derived from literature).

	c) 3TEF.csv - Input file for MixSIAR program.  Description of columns:
		'Sources'	Potential diet source item.
		'MeandC13'	Trophic enrichment factor to adjust for differential fractionation of carbon isotopes in tissues.  From literature.
		'SDdC13'	Standard deviation of carbon trophic enrichment factor.  From literature.
		'MeandN15'	Trophic enrichment factor to adjust for differential fractionation of nitrogen isotopes in tissues.  From literature.
		'SDdN15'	Standard deviation of nitrogen trophic enrichment factor.  From literature.

	d) Nest_propn_dietitem_landscapevar.xlsx - Results from MixSIAR program combined with sampled landscape variables for beta regression.
		'OrigOrder'	Original unique row identifier for each nest.
		'Year'		Year of sample collection.
		'NestID'	Unique nest identifier.
		'DietItem'	Potential diet source item.
		'Mean.diet.proportion'	Posterior mean estimated contribution of diet item to raven chick diet.
		'SD'		Standard deviation of estimated contribution of diet item.
		'q0.025'	2.5% quantile of posterior distribution for estimated contribution of diet item.
		'q0.05'		5% quantile of posterior distribution for estimated contribution of diet item.
		'q0.25'		25% quantile of posterior distribution for estimated contribution of diet item.
		'q0.5'		50% quantile of posterior distribution for estimated contribution of diet item.
		'q0.75'		75% quantile of posterior distribution for estimated contribution of diet item.
		'q0.95'		95% quantile of posterior distribution for estimated contribution of diet item.
		'q0.975'	97.5% quantile of posterior distribution for estimated contribution of diet item.
		'sage_avg'	Average percent sagebrush cover within 800 m of the raven nest.
		'ndvi_avg'	Average Normalized Difference Vegetative Index within 800 m of the raven nest.
		'disthwyrr'	Distance to nearest state/federal highway or railroad.
		'distantr'	Distance to nearest anthropogenic trash subsidy (e.g., landfill).
		'distlek'	Distance to nearest active greater sage-grouse (Centrocercus urophasianus) breeding lek.
		'cdate'		Centered Julian date of collection of the stable isotope sample(s).
		'GRSG_nest'	Average index value for relative probability of greater sage-grouse nest occurrence within 800 m of the raven nest.
		'WllDns'	Density (# wells / sq. km) of active oil and gas wells and infrastructure within 800 m of the raven nest.
