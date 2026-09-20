Title: Data for ‘Stakeholder Perspectives on Nature, People, and Sustainability at Mount Kilimanjaro’

Recommended Citation: Masao CA, Prescott GW, Snethlage MA, Urbach D, Torre-Marin Rando A, Molina-Venegas R, Mollel NP, Hemp C, Hemp A, Fischer M (2022). Stakeholder Perspectives on Nature, People, and Sustainability at Mount Kilimanjaro. People and Nature. 

Principal Investigator:
- Markus Fischer (markus.fischer@ips.unibe.ch)

Authors:
*  joint first-author
- Catherine A. Masao (ndeutz@yahoo.com, ORCID: 0000-0002-1242-9117) *
- Graham W. Prescott (graham.prescott.research@gmail.com, ORCID: 0000-0001-5123-514X) *
- Mark A. Snethlage (mark.snethlage@ips.unibe.ch, ORCID: 0000-0002-1398-8869) *
- Davnah Urbach (davnah.payne@ips.unibe.ch, ORCID: 0000-0001-9170-7834) *
- Amor Torre-Marin Rando (amor.torre@ips.unibe.ch)
- Rafael Molina Venegas (rafmolven@gmail.com, ORCID 0000-0001-5801-0736)
- Neduvoto P. Mollel (neduvotomollel@yahoo.com, ORCID: 0000-0002-4402-4667)
- Claudia Hemp (claudiahemp@yahoo.com, ORCID: 0000-0001-9170-7113)
- Andreas Hemp (andreas.hemp@uni-bayreuth.de, ORCID: 0000-0002-5369-2122)
- Markus Fischer (markus.fischer@ips.unibe.ch, ORCID: 0000-0002-5589-5900)

Date of data collection: 2018-09
Location of data collection: Moshi, Kilimanjaro Region, Tanzania
Date of final file release: 2022-01-13 

Data Overview:

We conducted a three-day stakeholder workshop in Moshi, Tanzania, in September 2018. The workshop was attended by 73 participants (16 women and 57 men), whom we invited to represent various sectors and local communities. We established the list of invitees through an extensive online search validated and complemented by key local informants. We divided registered participants into five groups based on their sectoral affiliation: 16 residents of local communities, including farmers (herein ‘Community’), 14 researchers and scientists (‘Research’), 16 professionals in conservation and management (‘Conservation’), 17 professionals in forestry, agriculture, and water management and governance (‘Resources’), and 10 other professionals mainly drawn from the tourism sector (‘Other’). 

We used two questionnaires—herein ‘habitat’ and ‘ecosystem services’— with open and closed questions. Closed questions were scored using a Likert-type scale. 

File overview:

1. kilimanjaro_ipbes_workshop_habitat_questionnaire.csv

Data from the ‘habitat’ questionnaire, entered by Catherine A. Masao and Mark A. Snethlage (finalised 2020-09-22). Individual perceptions about the state of and trends in habitats and species diversity and about the direct and indirect factors driving these trends. We invited participants to fill out separate questionnaires for each habitat of importance to their sector or for which they had knowledge, starting with the most important one.

2. kilimanjaro_ipbes_workshop_ecosystem_services_questionnaire.csv

Data from the ‘ecosystem services’ questionnaire, entered by Catherine A. Masao and Mark A. Snethlage (finalised 2020-01-09). The ‘ecosystem services’ questionnaire collected individual perceptions about the state of, trends in, and importance of NCP (Nature's Contributions to People), as well as about the factors driving observed changes in access and provision. With reference to the preliminary group discussion on NCP, we invited participants to fill out separate forms for each NCP they deemed important to their sector or had knowledge about and to indicate which habitat(s) provide(s) each of them.

3. kilimanjaro_ipbes_workshop_ecosystem_services_access_change_codes.csv

Adapted from the ecosytem services questionnaire data (kilimanjaro_ipbes_workshop_ecosystem_services_questionnaire.csv), coding the reasons for change in access to NCP. 

4. kilimanjaro_ipbes_workshop_spatial_scales_recommended_measures.csv

Tally of recommended measures towards recorded from the carousel session, grouped by spatial scale and Conservation Measures Partnership (CMP) categories. See Table S7 for details. 


Code used for analysis:
R code used for the statistical analysis and to create the figures available from: https://github.com/grahamprescott/kilimanjaro.ipbes.workshop.paper

File details:

1. kilimanjaro_ipbes_workshop_habitat_questionnaire.csv

143 observations of 73 variables

Key Variables:
- Group 
(categorical - stakeholder group to which participants were assigned. Blue = Community, Green = Research, Orange = Conservation, Red = Other, Yellow = Resources)
- Biome2 
(categorical - standardised habitat categories used in the analysis, coded by Mark A. Snethlage)
- Habitat.area 
(categorical - trends in habitat area over past 10 years (2008-2018); Decreased, Not Changed, Increased, No Answer)
- Habitat.condition 
(categorical - trends in habitat condition over past 10 years (2008-2018); Deteriorated, Not Changed, Improved, No Answer)
- Habitat.area.will 
(categorical - prediction for trend in habitat condition over next 10 years (2018-2028); Decrease Not Change, Increase, No Answer)
- Habitat.condition.will 
(categorical - trends in habitat condition over past 10 years (2018-2028); Decrease, Not Change, Increase, No Answer)
Variables beginning with ES., DIR., IND., ACT. refer to ecosystem services (i.e. NCP), direct drivers, indirect drivers, and recommended actions associated with each habitat form. They are numerical and scored as 1 if that variable is mentioned (present) or 0 if not mentioned (absent). In a few cases where different ecosystem services listed by the participant are coded to the same variable the number is the number of times that ecosystem service is mentioned. 

Codes for ecosystem services (ES.): HAB (Habitat Creation and Maintenance), POL (Pollination and dispersal of seeds and other propagules), AIR (Regulation of Air Quality), CLI (Regulation of Climate), OCE (Regulation of Ocean Acidification), WQN (Regulation of Freshwater Quantity, Location, and Timing), WQL (Regulation of Freshwater and Coastal Water Quality), SOL (Formation, Protection, and Decontamination of Soils and Sediments), HAZ (Regulation of Hazards and Extreme Events), PST (Regulation of Organisms Detrimental to Humans), NRG (Energy), FOD (Food and Feed), MAT (Materials and Assistance), MED (Medicinal, Biochemical, and Genetic Resources), LRN (Learning and Inspiration), EXP (Physical and Psychological Experiences), IDE (Supporting Identities), OPT (Maintenance of Options), WEB (Human Wellbeing), LIV (Livelihoods). Note: WEB and LIV are not traditionally included in NCP categories, but we created them as additional categories to capture responses that could not strictly be placed into the traditional 18 categories.  

Codes for direct drivers (DIR.): ACT = ‘Human Activities’, CC = Climate Change, IAS = Invasive Alien Species, LUC = Land-Use Change, OVR = Overexploitation, POL = Pollution. 

Codes for indirect drivers (IND.): CLT = Cultural, DEM = Demographic, ECO = Economic, GOV = Governance, S.T = Science and Technology. 

Codes for recommended actions (ACT.): AWR = Awareness Raising, ECO = Livelihood, Economic & Moral Incentives, EDU = Education & Training, ENF = Law Enforcement & Prosecution, INS = Institutional Development, LAN = Land / Water Management, LAW = Legal & Policy Frameworks, PRT = Conservation Designation & Planning, RSR = Research & Monitoring, SPC = Species Management. 

2. kilimanjaro_ipbes_workshop_ecosystem_services_questionnaire.csv

144 observations of 38 variables

Key variables: 

- Group 
(categorical - stakeholder group to which participants were assigned. Blue = Community, Green = Research, Orange = Conservation, Red = Other, Yellow = Resources)
- Service.original (free text response to which ecosystem service the participant was filling out the form)
- ESCODE 
(categorical - NCP category to which we assigned the free text response. Abbreviations: HAB (Habitat Creation and Maintenance), POL (Pollination and dispersal of seeds and other propagules), AIR (Regulation of Air Quality), CLI (Regulation of Climate), OCE (Regulation of Ocean Acidification), WQN (Regulation of Freshwater Quantity, Location, and Timing), WQL (Regulation of Freshwater and Coastal Water Quality), SOL (Formation, Protection, and Decontamination of Soils and Sediments), HAZ (Regulation of Hazards and Extreme Events), PST (Regulation of Organisms Detrimental to Humans), NRG (Energy), FOD (Food and Feed), MAT (Materials and Assistance), MED (Medicinal, Biochemical, and Genetic Resources), LRN (Learning and Inspiration), EXP (Physical and Psychological Experiences), IDE (Supporting Identities), OPT (Maintenance of Options), WEB (Human Wellbeing), LIV (Livelihoods). Note: WEB and LIV are not traditionally included in NCP categories, but we created them as additional categories to capture responses that could not strictly be placed into the traditional 18 categories.)
- Biome 
(categorical - which habitat provided the ecosystem service)
- Why.changed.provision 
(free text response for why Provision changed)
- Why.changed.access 
(free text response for why Access changed) [Note: although we theoretically expected a distinction between provision and access of each ecosystem service, we observed that this distinction was not strictly followed in practice and deemed the responses about access to be most accurate]
- Access 
(categorical - changes in access to the ecosystem service over the last 10 years (2008-2018); Decreased, No Change, Increased, No Answer)
- Access.will 
(categorical - predicted changes in access to the ecosystem service over the next 10 years (2018-2028); Deteriorate, Not Change, No Answer, Improve (note: no one responded ‘Improve’))  


3. kilimanjaro_ipbes_workshop_ecosystem_services_access_change_codes.csv

144 observations of 7 variables

We took the following variables from the ecosystem services questionnaire:
- ESCODE 
(categorical - NCP category to which we assigned the free text response)
- Access 
(whether access to this NCP increased or decreased between 2008-2018)
- Why.changed.access 
(free text response for why Access changed)
And created a new variable to synthesise the drivers of change in NCP access:
- Why.changed.access.code 

Note: a challenge with the ‘Why.changed.access’ variable is that many drivers are listed in the same response. To process this, we duplicated the rows with multiple drivers so that there would be one row per driver. We did this using Microsoft Excel for Mac. We did this so that each link from a driver to an increase or decrease in a given NCP could be visualised. The individual links are not standardised by individual respondent or response. They represent every instance of a reported link between a driver of change and a change in access to a given NCP. Responses or respondents who listed multiple instances of NCP access change and/or multiple drivers have therefore contributed more to the Sankey figure (Figure 4). We chose this approach because the aim in this case was to document the complex web of drivers leading to changes in NCP access, drawing upon the collective expertise of the respondents, not to test for individual differences between groups or respondents. Graham W. Prescott and Mark A. Snethlage independently coded each of the drivers and reached a consensus on any disagreements. Graham W. Prescott edited the final file. 

4. kilimanjaro_ipbes_workshop_spatial_scales_recommended_measures.csv

11 observations of 6 variables
 
We also conducted a carousel session in which participants could suggest actions and actors that could contribute towards achieving a sustainable future for people and nature at Mt. Kilimanjaro. This file contains the tally of recommended measures arising from this carousel session, grouped by spatial scale and Conservation Measures Partnership (CMP) categories. For full list of measures, see Table S7. 


