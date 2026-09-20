##### Aboveground Phenology #####
agphen.min <-read.csv(".../aboveground_phenology.csv", header=T, sep=",")

# overall model first leaf
phen.model.leaf <- lme((doy) ~ treatment * veg_type, random=~1|plot.ID/species, data=subset(agphen.min, phen==2), na.action=na.exclude)  
Anova(phen.model.leaf, type="II", test.statistic="F")

# overall model first flower
phen.model.flower <- lme((doy) ~ treatment * veg_type, random=~1|plot.ID/species, data=subset(agphen.min, phen==3), na.action=na.exclude)
Anova(phen.model.flower, type="II", test.statistic="F")


# _____________________________species-specific models______________________________________
#  model first leaf
eh <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Empetrum_hermaphroditum"), na.action=na.exclude)
Anova(eh, type="II", test.statistic="F")

vm <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Vaccinium_myrtillus"), na.action=na.exclude)
vma <- aggregate(doy ~ treatment, data=subset(agphen.min, phen==2 & species=="Vaccinium_myrtillus"), FUN=mean)

vv <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Vaccinium_vitis-idaea"), na.action=na.exclude)
Anova(vv, type="II", test.statistic="F")

ca <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Chamerion_angustifolium"), na.action=na.exclude)

gs <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Geranium_sylvaticum"), na.action=na.exclude)
Anova(gs, type="II", test.statistic="F")

mp <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Melampyrum_pratense"), na.action=na.exclude)
Anova(mp, type="II", test.statistic="F")

md <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Myosotis_decumbens"), na.action=na.exclude)
Anova(md, type="II", test.statistic="F")

pq <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Paris_quadrifolia"), na.action=na.exclude)

pm <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Pyrola_minor"), na.action=na.exclude)
Anova(pm, type="II", test.statistic="F")

rs <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Rubus_saxatilis"), na.action=na.exclude)

sv <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Solidago_virgaurea"), na.action=na.exclude)

sm <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Stellaria_nemorum"), na.action=na.exclude)
Anova(sm, type="II", test.statistic="F")

te <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Trientalis_europaea"), na.action=na.exclude)

vsp <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Valeriana_sambucifolia_ssp_procurrens"), na.action=na.exclude)
Anova(vsp, type="II", test.statistic="F")

cp <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Calamagrostis_phragmitoides"), na.action=na.exclude)
Anova(cp, type="II", test.statistic="F")

cs <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Carex_spec"), na.action=na.exclude)
Anova(cs, type="II", test.statistic="F")

ls <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==2 & species=="Luzula_spec"), na.action=na.exclude)
Anova(ls, type="II", test.statistic="F")


############################# flower individual models

ehf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Empetrum_hermaphroditum"), na.action=na.exclude)
Anova(ehf, type="II", test.statistic="F")

vmf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Vaccinium_myrtillus"), na.action=na.exclude)
Anova(vmf, type="II", test.statistic="F")

vvf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Vaccinium_vitis-idaea"), na.action=na.exclude)
Anova(vvf, type="II", test.statistic="F")

ca <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Chamerion_angustifolium"), na.action=na.exclude)

gsf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Geranium_sylvaticum"), na.action=na.exclude)
Anova(gsf, type="II", test.statistic="F")

mpf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Melampyrum_pratense"), na.action=na.exclude)
Anova(mpf, type="II", test.statistic="F")

mdf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Myosotis_decumbens"), na.action=na.exclude)
Anova(mdf, type="II", test.statistic="F")

pqf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Paris_quadrifolia"), na.action=na.exclude)

pmf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Pyrola_minor"), na.action=na.exclude)

rsf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Rubus_saxatilis"), na.action=na.exclude)

svf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Solidago_virgaurea"), na.action=na.exclude)

smf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Stellaria_nemorum"), na.action=na.exclude)
Anova(smf, type="II", test.statistic="F")

tef <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Trientalis_europaea"), na.action=na.exclude)
Anova(tef, type="II", test.statistic="F")

vspf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Valeriana_sambucifolia_ssp_procurrens"), na.action=na.exclude)

cpf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Calamagrostis_phragmitoides"), na.action=na.exclude)

csf <- lme(sqrt(doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Carex_spec"), na.action=na.exclude)
Anova(csf, type="II", test.statistic="F")

lsf <- lme((doy) ~ treatment, random=~1|plot.ID, data=subset(agphen.min, phen==3 & species=="Luzula_spec"), na.action=na.exclude)
Anova(lsf, type="II", test.statistic="F")

#### Belowground Phenology #####
root.growth.sum <- read.csv(".../root_growth.csv", sep=",")
root.length.tube <- read.csv(".../root_length.csv", sep=",")

# ______________ Root growth __________________________________________
root.growth.model.lmer <- lmer(sqrt(growth_area) ~ treatment * vegtype * doy + (1|doy/plotnr), data=root.growth.sum)
Anova(root.growth.model.lmer, type="II", test.statistic="F")
# zoom in into time of snowmelt
root.growth.model.zoom <- lmer(sqrt(growth_area) ~ treatment * vegtype * doy + (1|doy/plotnr), data=subset(root.growth.sum, doy %in% 133:153))
Anova(root.growth.model.zoom, type="II", test.statistic="F")
# ________________ root length at the end of the experiment__________________________________________
rootlength.model <- lme(sqrt(length_per_area) ~ treatment * vegtype, random=~1|plotnr, data=root.length.tube)
Anova(rootlength.model, type="II", test.statistic="F")


#### Treatment effects #####

## ___________ SNOWDEPTH & SNOWMELT _____________________________________________________________________
snowdepth <- read.csv(".../snowdepth.csv", header=T, sep=";")
#if plot melted out between snowdepth measurements and aboveground phenoloy was recorded before the next snowdepth measurement, the snowmet doy in 'snowmelt_doy' is adapted to that date
#delete unnecessary columns
snowdepth <- snowdepth[,-c(6,8)]
heath  <- subset(snowdepth, type=="heath")
meadow <- subset(snowdepth, type=="meadow")

snowmelt  <- read.csv(".../snowmelt_doy.csv", header=T, sep=";")
#delete unnecessary columns and rows
snowmelt <- snowmelt[ ,-c(7:27)]
snowmelt <- snowmelt[-c(29:33), ]
heathsm  <- subset(snowmelt, type=="heath")
meadowsm <- subset(snowmelt, type=="meadow")

# _________________ Soil temperatures ______________________________________________________
temp <- read.csv(".../soiltemperatures.csv")
temp <- temp[, -1]
temp$doy = as.numeric(temp$doy)
#average daily values
daily_temp <- aggregate(temp ~ Date*doy*tube*veg_type*treatment*plot, data=temp, FUN=mean)
daily_temp$doy=as.factor(daily_temp$doy) 
# 'de-seasonalizing' the temperature date (such that one can see the difference between the treatments better, despite the general warming over the course of the experiment)
# substract the overall daily average from the value of each individual plot
overall.mean <- aggregate(temp ~ Date * doy, data=daily_temp, FUN=mean)
overall.mean <- rename(overall.mean, c("temp"="overall.temp"))
deseason <- merge(overall.mean, daily_temp, by=c("Date", "doy"))
deseason$deseason.temp <- deseason$temp - deseason$overall.temp

### Air temperature from ANS    
air_temp <- read.csv(".../ANS_Air_temp.csv", sep=";", header=T)
head(air_temp)
str(air_temp)
View(subset(air_temp, doy %in% 129:150 & year=="2014"))
# add day of year
air_temp$doy <- strftime(air_temp$Date, format = "%j")
air_temp$doy = as.numeric(air_temp$doy)
#add column with year
air_temp$Date <- as.Date(air_temp$Date)
air_temp$year <- format(air_temp$Date, "%Y")
air_temp$year <- as.factor(air_temp$year)

## statistics
# snowmelt
snowmelt.model <- lme(snow_doy ~ type * treatment, data=snowmelt, random=~1|plot, na.action=na.exclude)
anova.lme(snowmelt.model, type="marginal") 

# deseasonalised temperature values
soiltemp.model <- lme((deseason.temp) ~ treatment * veg_type, random=~1|plot, data=subset(deseason, doy %in% 129:150))
Anova(soiltemp.model, type="II", test.statistic="F")