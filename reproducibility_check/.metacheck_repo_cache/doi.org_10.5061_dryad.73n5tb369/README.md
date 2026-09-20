# Divergent values and perspectives drive three distinct viewpoints on grizzly bear reintroduction in Washington, USA

[https://doi.org/10.5061/dryad.73n5tb369](https://doi.org/10.5061/dryad.73n5tb369)

## Description of the data and file structure

This dataset contains answers to a short questionnaire and the Q-sort rankings each participant gave to 41 statements depending on how much they agreed or disagreed with each statement. The scale of agreement ranges from -5 (strongly disagree) to +5 (strongly agree), and participants were "forced" to prioritize statements by sorting them in a grid (see figure in supporting information) which only allowed for one statement to be ranked -5 and one statement ranked +5. Several statements could be ranked neutrally (0). 

### Files and variables

#### File: Statements\_for\_Dryad.csv

**Description:** These are the statements that were ranked by participants in the Q-sort grid and their corresponding ID number (s1, s2, ...).

##### Variables

* ID: Statement id that corresponds to the raw sorts header row. 
* Statement: Text of each statement that participants sorted in the Q-sort activity. 

#### File: Raw\_Sorts\_for\_Dryad.xlsx

**Description:** This contains the answers to the preliminary questionnaire participants answered that collected basic demographic and familiarity information. It also contains how each participant ranked each statement (-5 to +5) based on level of agreement with that statement. 

Blank cells (unanswered questions) are filled in with "N/A".

##### Variables

* Number: The numerical id of each participant. Corresponds to Figure 2 in the manuscript. 
* Participant: Participant identifier given by the software.
* Loading: The factor which each participant loaded onto in our analysis. 
* Year_born: Year the participant was born.
* Gender_identity: Self-identified gender of the participant. 
* Primary_role: The role which the participant identified with most strongly as it pertains to their activities or involvement in the North Cascades Ecosystem (See manuscript and supporting information for questionnaire details). 
* Secondary_role1 through Secondary_role3: Participants had the option to select up to 3 additional roles they identify with. Some selected their primary roles twice. 
* DEIS_familiarity: The level of familiarity participants had with the 2017 Draft Environmental Impact Statement, with 4 categories of familiarity.
* s1 through s41: The ranking given to each statement by each participant. 

## Code/software

Our analyses were performed in Q Method Software, which is a paid subscription service: [https://qmethodsoftware.com/](https://qmethodsoftware.com/) 

However, analysis is possible using the open software KenQ: [https://shawnbanasick.github.io/ken-q-analysis/](https://shawnbanasick.github.io/ken-q-analysis/) The website provides substantial instructions for use of their software, and has the same options for analysis which are:

* We generated a **Pearson correlation** matrix of every Q sort.
* We used the matrices to conduct a **centroid factor analysis**.
* We used a combination of **judgmental hand rotation** and **Varimax rotation** to explore Q sort loadings relative to two, three, and four extracted factors.

