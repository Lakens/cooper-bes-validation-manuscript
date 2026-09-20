# Results and analysis script from a discrete choice experiment assessing public preferences for rewilding in the Oder Delta

**Paper title**:

Public preference for the rewilding framework: a choice experiment in the Oder Delta 

**Authors**:

Rowan Dunn-Capper a,b, Marek Giergiczny a,c, Néstor Fernández a,b, Fabian Marder a, Henrique M. Pereira a,b,d 

a German Centre for Integrative Biodiversity Research (iDiv) Halle-Jena-Leipzig, Puschstrasse 4, 04103, Leipzig, Germany

b ﻿Institut für Biologie, Martin-Luther-University Halle-Wittenberg, Halle, Germany

c ﻿Faculty of Economic Science, University of Warsaw, ul Długa 44/50 00-241, Warsaw, Poland

d ﻿CIBIO (Research Centre in Biodiversity and Genetic Resources)–InBIO (Research Network in Biodiversity and Evolutionary Biology), Universidade do Porto, Vairão, Portugal

**Summary**:

·      File count – 5 files

·      File formats - .xls, .mat, .md

·      File sizes – 108-115 KB

**Dataset overview**:

·      MXL_d_results_pooledGER18.1.24 – .xls file containing the results from respondents to the choice experiment residing in Germany. Results show the estimations from a mixed logit model. Description of variables can be found below. More information on the methodology and interpretation of the results can be found in the manuscript.

·      ger_data18.1.24.mat – choice experiment data from respondents residing in Germany stored as a matlab structure. Columns show the outcomes of individuals choice tasks. Respondents are assigned anonymous ids. More information on analysing choice experiment data is readily available online e.g., see Train, K 2009.

·      MXL_d_results_pooledPOL18.1.24 – .xls file containing the results from respondents to the choice experiment residing in Poland. Results show the estimations from a mixed logit model. Description of variables can be found below. More information on the methodology and interpretation of the results can be found in the manuscript.

·      pl_data18.1.24.mat – choice experiment data from respondents residing in Poland stored as a matlab structure. Columns show the outcomes of individuals choice tasks. Respondents are assigned anonymous ids.

**Detailed file information**

·      ger_data18.1.24.mat & pl_data18.1.24.mat

List of variables:

·      id – anonymized respondent id from survey

·      cs – choice situation number, there are 12 cs per respondent

·      alt – alternative number, there are 3 alt per person

·      choice – dummy coding choice (takes 1 if alt was chosen)

·      sq – dummy coding status quo alt (=1)

·      forest - forest variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (deadwood on floor)

·      river – river variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (natural flooding regimes)

·      agri – agriculture variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (land abandonment)

·      connect – connectivity variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (eco bridges and road removal)

·      lc – large carnivore variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (both large carnivores present)

·      lh – large herbivore variable

o   takes 4 levels. 1 = SQ level, 2 = lowest rewilding level (intensified land use), 3 = middle rewilding level, 4 = highest rewilding level (both large herbivores present)

·      cost – cost in EUR of choice alternative

·      booster – 0 = national representative sample, 1 = booster sample on local residents

*More detail on the attribute levels and rationale for specification can be found in the paper*

·      MXL_d_results files

List of variables:

·      SQ – status quo alternative

·      Forest2 – second first level (compared against level 1 forest – intensification)

·      Forest3 – third first level (compared against level 1 forest – intensification)

·      Forest4 – fourth first level (compared against level 1 forest – intensification)

·      *Same for *River2, 3, 4 (compared against level 1 river – intensification)

·      *Same for *Agri2, 3,4 (compared against level 1 agri – intensification)

·      *Same for *Connect2, 3, 4 (compared against level 1 river – intensification)

·      Lynx – presence of lynx (compared against level 1, no lynx or wolf)

·      Wolf – presence of wolf (compared against level 1, no lynx or wolf)

·      LC_both – presence of lynx and wolf (compared against level 1, no lynx or wolf)

·      Elk – presence of elk (compared against level 1, no elk or bison)

·      Bison – presence of bison (compared against level 1, no elk or bison)

·      LH_Both – presence of elk and bison (compared against level 1, no elk or bison)

·      -Cost/100(EUR) – cost variable

Model diagnostics – measures model fit

LL – log-likelihood

*Detailed description and analysis of results found in paper*
