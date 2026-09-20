# Define a list of packages
packages <- c("lavaan", "semPower")

# Install and load packages if they are not already installed
for (package in packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)}
  library(package, character.only = TRUE)}
source("Code/1_set_themes.R")

#Load data 
pa <- read.csv("Data/pa_statements.csv")

#get sums and summary stats
sums_pa <- pa %>% mutate(sum = q1+q2+q3+q4+q5+q6+q7+q8)
high <- filter(sums_pa, sum >= 30)
length(high$ID)/length(sums_pa$ID) #65% higher than 30
round(cor(pa[,2:9]),2)

#run cfa to confirm 2 dimensions
#load psych package now
if (!requireNamespace("psych", quietly = TRUE)) {
  install.packages("psych")}
library(psych)

dim2 <- 'Personal =~ q1 + q2 + q5 + q6 
         Social =~ q3 + q7 + q8'
cfa_dim2 <- cfa(dim2, data=pa[,-1])

#extract measures of fit and summary
aic_dim2 <- as.data.frame(fitmeasures(cfa_dim2,  c("aic", "rmsea", "cfi", "chisq")))
summary(cfa_dim2, standardized=TRUE, fit.measures = TRUE)
cfa_dim2
aic_dim2 

#check dimensions
per <- select(pa, q1, q2, q5, q6)
cult <- select(pa, q3, q7, q8)
psych::alpha(per)
psych::alpha(cult)

#plot
cfa_plot <- semPlot::semPaths(cfa_dim2 , "std")

#tutorials and papers used:
#https://benwhalley.github.io/just-enough-r/cfa.html
#Koran 2020 paper on number of indicators per factor
