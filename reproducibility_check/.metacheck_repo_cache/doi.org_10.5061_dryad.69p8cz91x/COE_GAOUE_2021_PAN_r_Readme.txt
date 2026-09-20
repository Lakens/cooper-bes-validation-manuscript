Phylogeny explains why less therapeutically redundant plant species are not necessarily facing greater use pressure_readme.txt file was generated on 2021-04-14 by the Authors



GENERAL INFORMATION

1. Title of Dataset: Phylogeny explains why less therapeutically redundant plant species are not necessarily facing greater use pressure

2. Author Information
	A. Principal Investigator Contact Information
		Name: Michael A. Coe
		Institution:Department of Botany, University of Hawai‘i at Mānoa,
		Email: coem@hawaii.edu

	B. Associate or Co-investigator Contact Information
		Name: Orou G. Gaoue
		Institution: Department of Ecology and Evolutionary Biology, University of Tennessee
		Email: ogaoue@utk.edu



3. Date of data collection (single date, range, approximate date) <suggested format YYYY-MM-DD>: 
June 2017 and July 2018 (on average 16 days a month) 

4. Geographic location of data collection  Ucayali, Peru, Amazon

5. Information about funding sources that supported the collection of the data: 

See associated publication for  details etc. link :https://doi.org/10.1002/pan3.10216

SHARING/ACCESS INFORMATION


6. Recommended citation for this dataset: 

See associated publication for  details etc. link :https://doi.org/10.1002/pan3.10216



METHODOLOGICAL INFORMATION

1. Description of methods used for collection/generation of data: 

see link: https://doi.org/10.1002/pan3.10216


2. Methods for processing the data: 


See associated publication found here: https://doi.org/10.1002/pan3.10216


3. Instrument- or software-specific information needed to interpret the data: 


All analyses were done in R.  See associated publication for package details etc. link https://doi.org/10.1002/pan3.10216


DATA-SPECIFIC INFORMATION FOR: COE_GAOUE_2021_PAN


1. Number of variables:  Response variable and predictor variables. See  variable list below and associated publication for details etc. link :https://doi.org/10.1002/pan3.10216


2. Number of cases/rows: 
62

3. Variable List: 


1. Botanical species cited by participants; 2. Plant family according to current nomenclature; 3. Species therapeutic redundancy; 4. local preference (data are binary); 5. use pressure (kilograms of biomass harvested for each species cited by participants; 6. species use values.


1. Use-Value index (Albuquerque et al. 2006) modified from (Phillips and Gentry 1993)  uv_total 
2. redundancy estimated as R = (ΣSi/n)*W. 
3. tip_taxa corresponding to phylo tree generated from S phylomaker function in R. see PAN manuscript for details.
4. use-pressure estimated as kilograms of biomass harvested monthly for each species cited by participants.


5. Specialized formats or other abbreviations used: URM = Utilitarian Redundancy Model.

Notes:

•	Data on the list of plant species and their family to build the phylogeny (data_2_phylo.csv)
•	Phylogeny which is pruned from the general phylogeny (data_3_shipibo_phylo.nex)
•	Ethnobiological data for which one which to conduct PGLS (data_4_shipibo_redundancy.csv).
 
To build the phylogeny used for the PGLS source data and function from Qian & Jin (2016). This includes 
•	The general phylogeny (Qian_PhytoPhylo.tre)
•	The nodes (Qian_nodes.csv)
•	The R function (Qian_S.phyloMaker.R). 


To test for the phylogenetic signal you need 
•	Data on the phylogeny constructed for the plant list, here as an R script (data_5_shipibo_tree.txt)
•	Ethnobiological data that includes a column of the trait(s) or variable(s) for which one wants to test for signal (data_4_shipibo_redundancy.csv)



