

# Title of Dataset:
---

Nature and well-being: The association of nature engagement and well-being during the SARS-CoV-2 pandemic


## Description of the Data and file structure

This study relied on a cross-sectional online survey that yielded a sample of 3,282 adults over 18 years of age, residing in the United States from two primary groups: (1) participants involved in public engagement programs through the Cornell Lab of Ornithology (NGO), and (2) members of the public with varying degrees of nature engagement. The two surveys were identical except for a few additional questions posed to the NGO group about engagement in NGO-specific activities. All data were initially cleaned using Excel. All analyses were completed using SPSS, version 28 (IBM Corp., 2019).


Data feilds are summarized below.

CODE BOOK
*=Cornell Lab of Ornithology only
**=National Panel Only

Variable name	CONSTRUCT/ VARIABLE, items		scale
	GROUP		
	Group Variable – Distinguishing between CLO and National Panel participants		1 = CLO
2 = NP
	FILTER QUESTION		
	Measure Citation 		
FQ	Filter Question (FQ) – A continuous variable meant to quickly assess people’s relationship to nature as a means of filtering participants for better sampling. 

“Please indicate the extent to which the following statement describes you by using the appropriate number from the scale below where “1 = Not at all true of me” and “7 = Completely true of me.” 

When possible, in my leisure time, I like to spend time outdoors in natural settings (such as woods, local parks, lake or beach, or a leafy yard or garden). “		Not at all true of me = 1 
2
3
Neither true or not true = 4
5
6
Completely true of me = 7 
	LAB OF ORNITHOLOGY QUESTIONS*		
LoO1	Lab of O 1 (LoO1) – Indicating which Lab of O programs participants are involved with. 

“In the last six months have you signed up for or participated in any of these Lab of Ornithology projects/resources?” 		Yes = 1
No = 0 
Unsure = 2
Missing = . 
LoO1.1	Bird Academy		
LoO1.2	Merlin		
LoO1.3	NestWatch		
LoO1.4	BirdCams		
LoO1.5	eBird		
LoO1.6	Other (Please describe) 		
LoO1.6_TEXT			
			
LoO2	Lab of O 2 (LoO2) – Indicating a change in birdwatching behavior. 

“During the last six months, has your engagement with any of these activities changed? If so, how?”		Decreased a lot = 1
Decreased a little = 2
Stayed about the same = 3
Increased a little = 4
Increased a lot = 5
Not applicable = 999
Missing = .
LoO2.1	Birdwatching outdoors		
LoO2.2	Birdwatching online		
LoO2.3	Observing birds from my window		
LoO2.4	Feeding birds or other wildlife		
LoO2.5	Engaging in citizen science		
LoO2.6	Other (please describe)		
LoO2.6_TEXT			
LoO3	Lab of O 3 (LoO3) – Indicating people’s self-reported skill at identifying birds.

“How would you rate your own ability to identify birds? Please respond on a scale where 1 = Novice to 7 = Expert.” 		Novice = 1
2
3
Intermediate = 4
5
6
Expert = 7 
Missing = .
LoO4	Lab of O 4 (LoO4) – Indicating the importance of bird watching.

“How important to you personally is bird watching as a recreational activity?” 		Birdwatching is … ______ recreational activity(ies)
1= …my least important… 
2= … one of my least important… 
3= … no more important than other … 
4= … one of my most important… 
5= … my most important …
Missing = . 
	INDEPENDENT VARIABLES		
	LEVELS OF NATURE ENGAGEMENT (IV) 		
	Levels of Nature Engagement (LNE)- A continuous variable with 3 subscales reflecting whether individuals mostly engage with nature: (a) directly (e.g., via hikes, in-person birding); (b) indirectly (e.g., looking at nature/ birds through a window); or (c) vicariously (e.g., participating in nature education / entertainment online).

“To begin, please think about some of the activities that you do. How often do you engage in each of the following activities.”
	0=Never
1=A few times
2=Monthly
3=1-2 times per week
4=Almost daily
Missing = .
LNE_1	Fishing or hunting	Direct	
LNE_2	Camping	Direct	
LNE_3	Backpacking in wilderness	Direct	
LNE_4	Bird watching	Direct	
LNE_5	Day hiking/walking in nature	Direct	
LNE_6	Biking (mountain or road)	Direct	
LNE_7	Non-motor water sports (eg,. Canoeing)	Direct	
LNE_8	Gardening	Direct	
LNE9	Visiting a park or natural area	Indirect	
LNE_10	Visiting a zoo or nature center	Indirect	
LNE_11	Wildlife photography 	Indirect	
LNE_12	Watching nature through my window	Indirect	
LNE_13	Watching online wildlife cams	Vicarious	
LNE_14	 Reading books/articles about nature	Vicarious	
LNE_15	Watching nature documentaries	Vicarious	
LNE_16	Other (Please Describe)	Other	
LNE_16_TEXT			
LNE_tot	LNE_tot = SUM (Lne1-15)		Sum of all items
LNE_D_tot	LNE_D_tot = SUM (Lne1-8)		Lne16 must be categorized and added to correct sum
LNE_I_tot	LNE_I_tot = SUM(Lne9-12)		
LNE_V_tot	LNE_V_tot= SUM(Lne13-15)		
LNE_mean	MEAN(LNE_1-15)		
LNE_D_mean	MEAN(LNE_1-8)		
LNE_I_mean	MEAN(LNE_9-12)		
LNE_V_mean	MEAN(LNE_13-15)		
LNE_Travel.Resource	MEAN(LNE_1,2,3,6,7,10)		Based on Factor Analysis; “Nature excursions”
LNE_Home	MEAN(LNE_4,5,8,9,11,12)		“” “Nature nearby”
LNE_Media.Passive	MEAN(LNE_13,14,15)		“” “Nature media”
	CONNECTION TO NATURE 		
	Nature Connection Index.   Richardson, M., Hunt, A., Hinds, J., Bragg, R., Fido, D., Petronzi, D., ... & White, M. (2019). A measure of nature connectedness for children and adults: Validation, performance, and insights. Sustainability, 11(12), 3250
 
		α = 0.92
Connection to Nature (CN) - A continuous variable reflecting to what degree people agree or disagree with a series of statements related to the experience of engaging in nature (e.g., treating nature with respect, feeling a part of nature). 

“For each of the following statements, please indicate how much you agree or disagree.”
	1=Completely Disagree
2=Strongly Disagree
3=Disagree
4=Neutral
5=Agree
6=Strongly Agree
7=Completely Agree 
Missing = .
CN_1	I always find beauty in nature		1-7
CN_1_rec	“”		0-15 (per Table 2 above)
CN_2	I always treat nature with respect		1-7
CN_2_rec	“”		0-10 (per Table 2)
CN_3	Being in nature makes me very happy		1-7
CN_3_rec	“”		0-16 (per Table 2)
CN_4	Spending time in nature is very important to me		1-7
CN_4_rec	“”		0-19 (per Table 2)
CN_5	I find being in nature really amazing		1-7
CN_5_rec	“”		0-17 (per Table 2)
CN_6	I feel part of nature 		1-7
CN_6_rec 	“”		0-23 (per Table 2)
CN_tot	=Sum (cn1rec, cn2rec, cn3rec, cn4rec, cn5rec, cn6rec)		Sum of all items; Range 0-100.
CN_mean	=MEAN (cn1rec, cn2rec, cn3rec, cn4rec, cn5rec, cn6rec)		
	PANDEMIC STRESS		
Pandemic Stress (PS) – A categorical variable reflecting the extent to which people agree or disagree with statements about how the COVID-19 Pandemic has impacted them personally. “While we have all been impacted by the COVID-19 pandemic, it has affected people in different ways. Please indicate the extern to which you agree or disagree with each of the statements below regarding how the pandemic has affected you.”	1=strongly disagree
2=disagree
3=neither agree nor disagree
4=agree
5=strongly agree 
Missing = . 
PS_1	Economically, the pandemic has hit me very hard.		1-5
PS_2	Being socially isolated during the pandemic has been very difficult for me. 		1-5
PS_3	I have had trouble concentrating during the pandemic.		1-5
PS_4	Fortunately, I have not be negatively affected financially by the pandemic. (-)		1-5
PS_4_rev	“  (reverse coded)	Rev	1-->5, 2 -> 4, 3 -> 3,4 -> 2, 5 -> 1
PS_5	I have found the pandemic to be a restful and restorative time. (-)		1-5
PS_5_rev	“  (reverse coded)	Rev	1-->5, 2 -> 4, 3 -> 3,4 -> 2, 5 -> 1

PS__6	During the pandemic, I have felt extremely stressed.		1-5
PS_7	During the pandemic, I have missed spending time with people.		1-5
PS_8	I have enjoyed having more time at home during the pandemic. (-)		1-5
PS_8_rev	“  (reverse coded)	Rev	1-->5, 2 -> 4, 3 -> 3,4 -> 2, 5 -> 1

PS__9	During the pandemic, I have had more difficulty sleeping.		1-5
PS_10	For me, the pandemic has been a good time to focus my attention on tasks. (-)		1-5
PS_10_rev	“  (reverse coded)	Rev	1-->5, 2 -> 4, 3 -> 3,4 -> 2, 5 -> 1
PS_tot	PS_tot = SUM(Ps1, Ps2, Ps3, Ps4rev, Ps5rev, Ps6, Ps7, Ps8rev, Ps9, Ps10rev) 		Sum of these items
PS_mean	PS_mean = MEAN(Ps1, Ps2, Ps3, Ps4rev, Ps5rev, Ps6, Ps7, Ps8rev, Ps9, Ps10rev) 		
	LOCAL SEVERITY OF PANDEMIC 		
	This variable was derived from objective online data based on the respondent’s county and survey response date.  Data were compiled using the “Known Cases,” “Deaths,” and “County Populations” data provided by USA Fact’s Covid Dashboard. https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/?fbclid=IwAR2JKuRz7xqnt71wKbOOL2_GD4-tT7RgO6pMCWT6nsD4LJ6Z7vOi2MgPDpY    

	Total cases in county + total deaths in county due to Covid19, per capita.  ( per 100,000)

The Pandas Package was utilized in Python to match the total cumulative cases from the entire pandemic  for each unique date of completion and county  with their corresponding ID numbers.  All values were divided by "County Population” counts for each county and multiplied by 100,000.
This process produced data for the total cumulative cases and deaths in each individual’s county at date of survey completion. 

Sample Calculation:
LSPtCp= (Total cumulative cases in county during entire pandemic @ date of completion)/(County population) x 100,000

LSPtCp	On date of survey total cases ever (all of 2020) in county per 100,000	
LSPtDp 	On date of survey: total deaths (all of 2020) in County per 100,000 	
	Average cases in county in past 14 or 30 days + Average deaths in county in past 14 or 30 days due to Covid19, per capita. (per 100,000)

The Pandas Package was used in Python to compute the average for “Known Cases” and “Deaths” for the 14 and 30-day period between October 1st and November 1st for each specific county.  First, the software subtracted the total cases 14 and 30 days before each date of completion from each date of completion for each county to calculate the total amount of new cases within each time increment. These values were divided by 14 and 30 respectively to calculate averages.   Python was then used to match the averages and sums for each unique date, state, and county combination with their corresponding ID numbers. Finally, the averages were divided by “County Population” counts for each county. These values were then multiplied by 100,000.

Sample Calculation:
New cases in county = (Total Cases in county @ date of completion) - (Total Cases in county 14 days before date of completion))/14)
LSPc14p = (New cases in county)/(County Population) x 100,000

All data is specific to each individual participant. For example, an individual who completed the survey on October 3rd in county X would have a different 14- and 30-day average than another individual who completed the survey on October 3rd in county Y.  Likewise, this same individual from  county X who completed the survey on October 3rd would have a have a different 14- and 30-day average than another individual living in county X who completed the survey on October 16th  (or any other date for that matter).

LSPc14p	Average number of new cases 14 days before date of completion per 100,000 individuals
LSPc30p	Average number of new cases 30 days before date of completion per 100,000 individuals
LSPd14p	Average number of new deaths 14 days before date of completion per 100,000 individuals
LSPd30p	Average number of new deaths 30 days before date of completion per 100,000 individuals
	PANDEMIC HEALTH EXPERIENCE (change to PHE)		
PHI	Pandemic Health Experience (PHI) – A categorical variable reflecting the direct Covid-19 health experience of respondents and those close to them . 

“Next, we would like to understand what impact the Covid-19 pandemic has had on your own health or on the health of people close to you. Please answer Yes or No to the following seven statements.”
		Yes = 1 = True
No = 0 = False 
Missing = . 
PHI_1	I was diagnosed with COVID-19.		
PHI_2	I, myself, was very ill due to COVID-19.		
PHI_3	One or more close friend(s) or family member(s) were diagnosed with COVID-19.		
PHI_4	Aside from close family and friends, I personally know one or more people who were diagnosed with COVID-19. 		
PHI_5	I have close friend(s) or family member(s) who are experiencing long-term physical health impacts of COVID-19.		
PHI_6	A close friend or family member of mine died due to COVID-19.		
PHI_7	Aside from close family and friends, I personally know one or more people who died due to COVID-19.		
PHI_tot	PHI_tot = SUM (phi1-7)		Sum of all items 
PHI_mean	MEAN(PHI_1-7)		
	THE PANDEMIC EMOTIONAL IMPACT SCALE		
	Palsson, O. S., Ballou, S., Gray, S. (2020) Validation of the pandemic emotional impact scale. Published Online October 17, 2020 doi: 10.1016/j.bbih.2020.100161
	
PEI	The Pandemic Emotional Impact Scale (PEI) – A categorical variable reflecting the self-reported change in an individual’s well-being and functioning from the past month compared to before the beginning of the pandemic in the U.S. 

“How much has your well-being and functioning been different during the past month, compared to the way it was before the beginning of the COVID-19 pandemic in the U.S.? Please indicate this change, if any, using the following scale.” 		0 = Not at all 
1 = A little bit
2 = Moderately
3 = A lot
4 = Extremely 
Missing = .

Note: I added four items to the original scale to be reverse coded
PEI_1	More worried about your finances		
PEI_2	More anxious or ill at ease		
PEI_3	More difficulty concentrating		
PEI_4	Feeling more rested and restored. (-)	Rev	
PEI_4_rev	“  (reverse coded)*		
PEI_5	Being less productive		
PEI_6	More worried about your personal health and safety		
PEI_7	Being more bored		
PEI_8	More difficulty sleeping		
PEI_9	Feeling more lonely or isolated		
PEI_10	Feeling generally happy (-)*	Rev	
PEI_10_rev	“  (reverse coded)		
PEI_11	Feeling more down and depressed		
PEI_12	More worried about getting necessities like groceries or medications		
PEI_13	More worries about the health and safety of family members or friends		
PEI_14	Feeling more frustrated about not being able to do what you usually enjoy doing		
PEI_15	Being more able to concentrate and focus*	Rev	
PEI_15_rev	“  (reverse coded)		
PEI_16	More worried about possible breakdown of society		
PEI_17	Feeling more angry or irritated		
PEI_18	Feeling that the future is darker than before		
PEI_19	Feeling more grief or sense of loss		
PEI_20	Feeling more patient and calm*	Rev	
PEI_20_rev	“  (reverse coded)		
PEI_tot	PEI_tot = SUM(Pei1, Pei2, Pei3, Pei4rev, Pei5, Pei6, Pei7, Pei8, Pei9. Pei10rev, Pei11, Pei12, Pei13, Pei14, Pei15rev, Pei16, Pei17, Pei18, Pei19, Pei20rev)		Sum of all items, with all reversed variables substituted in
PEI_mean	PEI_mean = MEAN(Pei1, Pei2, Pei3, Pei4rev, Pei5, Pei6, Pei7, Pei8, Pei9. Pei10rev, Pei11, Pei12, Pei13, Pei14, Pei15rev, Pei16, Pei17, Pei18, Pei19, Pei20rev)		
	COMPLIANCE
	
C	Compliance (C) – a categorical variable reflecting how strictly people have followed guidelines on altering behavior in response to the pandemic. 

“For each statement, please indicate how often you did this behavior, if applicable, in response to the pandemic. In response to the pandemic, I…” 		999 = not applicable 
1= Strongly disagree
2= Disagree
3= neither agree nor disagree
4 = Agree
5= Strongly agree
Missing = .
C_1	…reduced out-of-state travel		1-5
C_2	…reduced non-essential local travel		1-5
C_3	…decreased human encounters		1-5
C_4	…wore a mask in public places		1-5
C_5	…maintained 6 feet physical distance when interacting with people outside my home		1-5
C_6	…have sheltered in place at home		1-5
C_tot	C_tot = SUM (C_1-6)		Sum of all items
C_mean	C_mean = MEAN(C_1-6)		
	DEPENDENT VARIABLES		
	RUMINATION (DV)		
	Trapnell + Campbell (1999).  Private self-consciousness and the five-factor model of personality: distinguishing rumination from reflection. Journal of personality and social psychology, 76(2), 284.	12 items 
Responses 1-5
RUM	Rumination (RUM) – A categorical variable reflecting the degree to which people agree or disagree with statements related to well-being, specifically thinking and reflecting repeatedly on matters. 

“To begin, please think about the last month. For each of the statements below, please think about how you have felt in the last month and indicate your level of agreement or disagreement by clicking one of the categories.”
	1=Strongly Disagree
2=Disagree
3=Neutral
4=Agree 
5=Strongly Agree
Missing = .
RUM_1	My attention is often focused on aspects of myself I wish I’d stop thinking about.  		
RUM_2	I always seem to be rehashing in my mind recent things I’ve said or done.		
RUM_3	Sometimes it is hard for me to shut off thoughts about myself.		
RUM_4	Long after an argument or disagreement is over with, my thoughts keep going back to what happened.		
RUM_5	I tend to “ruminate” or dwell over things that happen to me for a really long time afterward.		
RUM_6	I don’t waste time rethinking things that are over and done with. (-)	rev	
RUM_6_rev	“  (reverse coded)		
RUM_7	Often, I’m playing back over in my mind how I acted in a past situation.		
RUM_8	I often find myself reevaluating something I’ve done.		
RUM_9	I never ruminate or dwell on myself for very long (-)	rev	
RUM_9_rev	“  (reverse coded)		
RUM_10	It is easy for me to put unwanted thoughts out of my mind. (-)	rev	
RUM_10_rev	“  (reverse coded)		
RUM_11	I often reflect on episodes in my life that I should no longer concern myself with.		
RUM_12	I spend a great deal of time thinking back over my embarrassing or disappointing moments.		
RUM_tot	RUM_tot = Sum (rum1, rum2, rum3, rum4, rum5, rum6rev, rum7, rum8, rum9rev, rum10rev, rum11, rum12).		Sum of all items, with reverse items substituted properly
RUM_mean	RUM_mean = MEAN(rum1, rum2, rum3, rum4, rum5, rum6rev, rum7, rum8, rum9rev, rum10rev, rum11, rum12)		
	LONELINESS		
	Wongpakaran, N., Wongpakaran, T., Pinyopornpanish, M., Simcharoen, S., Suradom, C., Varnado, P., & Kuntawong, P. (2020). Development and validation of a 6‐item Revised UCLA Loneliness Scale (RULS‐6) using Rasch analysis. British Journal of Health Psychology, 25(2), 233-256.		
LON	Loneliness (LON) – A variable reflecting how often people feel certain things related to well-being, specifically companionship and involvement and connection to others.

“The following statements describe how people sometimes feel. For each statement, please indicate how often, in the last month you have felt the way described.” 		1=Never
2= Rarely
3= Sometimes,
4= Always
Missing = . 
LON_1	How often have you felt that you lack companionship?	ucla2	


LON_2	How often have you felt alone?	ucla4	
LON_3	How often have you felt that you are no longer close to anyone?	ucla7	
LON_4	How often have you felt, in the last month, left out?	ucla11	
LON_5	How often have you felt that no one really knows you well?	ucla13	
LON_6	How often have you felt that people are around you but not with you? 	ucla18	
LON_tot	LON_tot = SUM(lon1-6)		Sum of all items 
LON_mean	LON_mean = MEAN(LON_1-6)		
	HABITS/BEHAVIOR		
BEH	Habits/Behavior (BEH) – A categorical variable reflecting the self-reported change in an individual’s behavior

“Some people report that the pandemic experience has changed them, or more specifically, changed their behavior. For each of the following please indicate the extent to which you did this more or less, or if it remained about the same, during the time when the pandemic was more severe in your area. 	1= Much less
2= Somewhat less
3= About the same 
4= Somewhat more
5= Much more 
Missing = . 
BEH_1	Drive car 		
BEH_1_rev	“”		
BEH_2	Exercise		
BEH_3	Eat at home		
BEH_4	Purchase material goods (aside from food/beverage)		
BEH_4_rev	“”		
BEH_5	Spend time in nature		
BEH_6	Eat healthy food		
BEH_7	Slow down my pace of life		
BEH_8	Ride a bike		
BEH_9	Engage in civic action		
BEH_10	Eat restaurant food		
BEH_10_rev	“”		
BEH_11	Be politically active		
BEH_12	Buy stuff I don’t need		
BEH_12_rev	“”		
BEH_13	Garden at home		
BEH_14	Walk to destinations		
BEH_15	Eat unhealthy food		
BEH_15_rev	“”		
BEH_16	Go for walks		
BEH_17	Watch television or stream shows (ie. Netflix, Hulu, etc.)		
BEH_17_rev	“”		
BEH_tot	Note re: scoring.  May run factor analyses here.  Will consider which to reverse code. 		
hab	Are there some (new) habits that you hope to maintain beyond the pandemic?		1=yes
0=no
Hab-q	What are the (new) habits you hope to maintain? 	Only show if behcont1 is 1=yes	Free response
	MENTAL HEALTH		
	Kessler, R. C., Andrews, G., Colpe, L. J., Hiripi, E., Mroczek, D. K., Normand, S. L., ... & Zaslavsky, A. M. (2002). Short screening scales to monitor population prevalences and trends in non-specific psychological distress. Psychological medicine, 32(6), 959-976.		Kessler Psychological Distress scale“K 10”
10 items
https://www.tac.vic.gov.au/files-to-move/media/upload/k10_english.pdf 

K10	Mental Health (K10) – A categorical variable reflecting how often people feel certain things related to well-being, specifically anxiety or depression and its symptoms like fatigue or restlessness. 

“Again, thinking about the last month, for each question below, please indicate how often you had this feeling using the scale below. During the last month, how often did you feel…”		1=none of the time,
2=a little of the time, 
3= some of the time, 
4=most of the time, 
5= all of the time.
Missing = . 

NOTE: I have reversed these response options to be consistent with the prior (loneliness) questions. In the original scale, 1= all of the time… 5=none of the time!

K10_1	… tired out for no good reason?	  				Rev	
K10_1_rev	                                   “  (reverse coded)		
K10_2	… nervous	Rev	
K10_2_rev	                                  “  (reverse coded)		
K10_3	… so nervous that nothing could calm you down?	Rev	
K10_3_rev	                                 “  (reverse coded)		
K10_4	… hopeless?	Rev	
K10_4_rev	                                 “  (reverse coded)		
K10_5	… restless or fidgety?	Rev	
K10_5_rev	                                 “  (reverse coded)		
K10_6	… so restless that you could not sit still?	Rev	
K10_6_rev	                                 “  (reverse coded)		
K10_7	… depressed?	Rev	
K10_7_rev	                                 “  (reverse coded)		
K10_8	… so depressed that nothing could cheer you up?	Rev	
K10_8_rev	                                 “  (reverse coded)		
K10_9	… that everything was an effort?	Rev	
K10_9_rev	                                 “  (reverse coded)		
K10_10	… worthless?	Rev	
K10_10_rev	                                 “  (reverse coded)		
K10_tot	First recode all 10 items since I reversed these as noted to the right.
K10tot = SUM(k10-1-10) 		Sum of all variables
	FREE RESPONSE		

FR_1	Lastly, we would like you to reflect on to what extent you feel that accessing nature helped you cope during the pandemic?		
FR_2	What role, if any, did watching birds play in helping you to cope during the pandemic?		
Contact_q*	Would you be interested in potentially having a conversation with someone from our research team about your experiences during the COVID-19 pandemic?		
Contact_E*	If yes, please provide the best email address for us to contact you.		
			
	DEMOGRAPHIC / LOCATION DATA		
Cntry	Do you live in the United States? 	If answer = 0, sent to end of survey	Yes = 1
No = 0 
State	For the next couple of questions, please provide state and county information so that we can better understand the impacts of the COVID-19 pandemic across different parts of the country

In what state do you live? 	Pull down menu 	50 states + DC 
county	In what county do you live? 	Pull down menu, based on answer to state Q	Removed from dataset to maintain anonymity 
Zip	What is your zip code?	Free response, validation for US postal code	Removed from dataset to maintain anonymity 
area	    Which of the following best describes the area where you live? 

Urban, Inner City, Metropolitan = 1
Small City = 2
Suburban = 3
Rural or Farming community = 4
Missing = . 
Decline to respond = 999	Categorical MC	 1 2 3 4 5
Byear	In what year were you born?	Free response	Removed from dataset to maintain anonymity 
Age	Calculate: i.e., age = 2020-byear		Removed from dataset to maintain anonymity 
Gen	   How do you describe your gender identity?

Male = 1 
Female =2
Trans male/trans man =3 
Trans female/trans woman =4 
Non-binary =5 
Decline to respond = 99
Missing = . 	Categorical MC 	1 2 3 4 5 6 7
Gen_rec	Male = 1 
Female =2
Trans male/trans man, Trans female/trans woman, Non-binary =3
Decline to respond = 999
Missing = .
		
Hisp	Are you of Hispanic, Latino, or Spanish origin?

No, not of Hispanic, Latino, or Spanish origin = 1
Yes, Mexican, Mexican American, Chicano = 2
Yes, Puerto Rican = 3
Yes, Cuban = 4
Yes, another Hispanic, Latino, or Spanish origin (for example, Salvadoran, Dominican, Colombian, Guatemalan, Spaniard, Ecuadorian, etc.) = 5
Decline to respond = 999
Missing = . 	Categorical MC	Removed from dataset to maintain anonymity 
Hisp_rec	Are you of Hispanic, Latino, or Spanish origin?

No, not of Hispanic, Latino, or Spanish origin = 1
Yes, Mexican, Mexican American, Chicano, Puerto Rican, Cuban, another Hispanic, Latino, or Spanish origin (for example, Salvadoran, Dominican, Colombian, Guatemalan, Spaniard, Ecuadorian, etc.) = 2
Decline to respond = 999
Missing = .		Removed from dataset to maintain anonymity 
Race	What is your race? (please check all that apply.)

White (for example, German, Irish, English, Italian, Lebanese, Egyptian, etc.)  = 1
Black or African-American (for example, African American, Jamaican, Haitian, Nigerian, Ethiopian, Somali, etc.)  = 2
American Indian or Alaska Native (name of enrolled or principal tribes(s), for example, Navajo Nation, Blackfeet Tribe, Mayan, Aztec, Native Village of Barrow Inupiat Traditional Government, Nome Eskimo Community, etc.)  = 3
Asian (for example Chinese, Vietnamese, Indian, Filipino, Korean, Japanese, Pakistani, Cambodian, Hmong, etc.) = 4
Native Hawaiian or Pacific Islander (for example Samoan, Chamorro, Tongan, Fijian, Marshallese, etc.) = 5
Other (please describe) = 6
Mixed = 7
Decline to respond = 999
Missing = . 	Categorical MC 	Removed from dataset to maintain anonymity 
Race_rec	What is your race? (please check all that apply.)

White (for example, German, Irish, English, Italian, Lebanese, Egyptian, etc.)  = 1
Black or African-American (for example, African American, Jamaican, Haitian, Nigerian, Ethiopian, Somali, etc.)  = 2
American Indian or Alaska Native (name of enrolled or principal tribes(s), for example, Navajo Nation, Blackfeet Tribe, Mayan, Aztec, Native Village of Barrow Inupiat Traditional Government, Nome Eskimo Community, etc.)  = 3
Asian (for example Chinese, Vietnamese, Indian, Filipino, Korean, Japanese, Pakistani, Cambodian, Hmong, etc.) OR Native Hawaiian or Pacific Islander (for example Samoan, Chamorro, Tongan, Fijian, Marshallese, etc.) = 4
Other (please describe) = 5
Mixed = 6
Decline to respond = 999
Missing = .
		Removed from dataset to maintain anonymity 
Mar	Are you currently...

Married = 1
Single = 2
In a relationship, but not married = 3

Divorced = 4
Widowed = 5
Separated = 6
Decline to respond = 999
Missing = . 
	Categorical MC	Removed from dataset to maintain anonymity 
Mar_rec	Married = 1
Single = 2
In a relationship, but not married = 3
Divorced, widowed, separated = 4		Removed from dataset to maintain anonymity 
Hshld1	Please fill in the following information: 

Including yourself, how many people currently live full-time in your household? 	fill in the blank	
Hshld1_rec	(Only numerical values 0-29 only included)		
Hshld2	Of those, how many are less than 18 years old?	Fill in the blank	
Hshld2_rec	(Only numerical values 0-19 included)		
Hshld3	Of those, how many are elderly or disabled?	Fill in the blank	
Hshld3_rec	(Only numerical values 0-25 included)		
Edu	What is the highest level of education you have completed or the highest degree you have received?

Did not complete High School = 1
High school diploma or equivalent (e.g., GED) = 2
Some college or technical school but no degree = 3 
Two year or Associate degree = 4
College/University degree (Bachelor degree_ = 5
Post-graduate degree (Masters) = 6
Post-graduate degree (PhD, MD, JD, etc) = 7 
Decline to respond = 999
Missing = . 	Categorical MC	Removed from dataset to maintain anonymity 
Empl	What is your current employment status? (Choose one response below.) 

Employed full-time by others = 1 
Employed part-time by others = 2
Operate own business = 3
Retired = 4
Temporarily unemployed = 5
Full-time student = 6
Not employed at all = 7
Decline to respond = 999
Missing = . 	Categorical MC	 1 2 3 4 5 6 7 8
Inc	What is your annual household income?

Less than $24,999 = 1 8i
$25,000 - $49,999  = 2
$50,000 - $99,999  = 3 
$100,000 - $199,999  = 4 
More than $200,000  = 5 
Decline to respond = 999
Missing = . 	Categorical MC	 1 2 3 4 5 6
Pol	Generally speaking, how do you describe your political leaning?

Very conservative = 1
Somewhat conservative = 2
Neither conservative nor liberal = 3
Somewhat liberal = 4
Very liberal = 5
Decline to respond = 999
Missing = . 
 	Categorical MC	 1 2 3 4 5 6









## Sharing/access Information

Links to other publicly accessible locations of the data:

Was data derived from another source?
If yes, list source(s):