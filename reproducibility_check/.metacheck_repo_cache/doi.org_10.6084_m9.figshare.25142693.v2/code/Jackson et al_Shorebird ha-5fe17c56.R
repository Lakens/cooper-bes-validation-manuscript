library(bbmle)
library(broom.mixed)
library(car)
library(colorBlindness)
library(DHARMa)
library(emmeans)
library(glmmTMB)
library(lubridate)
library(MuMIn)
library(performance)
library(scales)
library(sjPlot)
library(tidyverse)

shorecounts_unprocessed <- read_csv("./01_data/CoorongShorebirdCounts.csv") 

shorecounts <- shorecounts_unprocessed %>%
  filter(!is.na(MudflatAreaM)) %>%
  mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
  mutate(month = factor(format(Date, "%m"), 
         levels = c('04', '06', '08', '10', '12', '02', '03'))) %>%
  mutate(tod = if_else(am(Starttime), "am", "pm"),
         mudshal = MudflatAreaM*.0001+ShallowAreaha) %>%
  group_by(Site) %>%
  mutate(avgsal = mean(Salinity),
         avgmudshal = mean(mudshal)) %>%
  mutate(Salinity.c = as.vector(scale(Salinity, scale = TRUE)), 
         Mudshal.c = as.vector(scale(mudshal, scale = TRUE))) %>%
  ungroup() %>%
  mutate(Winddirection = dplyr::recode(Winddirection, E="Oth", ENE="Oth", ESE="Oth",    
                         NE="N", NNE="N", NNW="N", NW="N", S="Oth", SE="Oth", SSE="Oth",  
                         SSW="Oth", SW="Oth", W="Oth", WNW="Oth", WSW="Oth"))

shorecounts <- shorecounts %>%
  group_by(Date, Site, Temperature, Winddirection, Windspeed,
           Salinity, MudflatAreaM, ShallowAreaha, 
           mudshal, avgsal, avgmudshal, Salinity.c, Mudshal.c,
           tod, month) %>%
  summarise(across(BandedStilt:SmallShorebird, ~ max(., na.rm = FALSE))) 

shorecounts <- shorecounts %>%
  rowwise() %>%
  mutate(shoreabun = sum(c_across(BandedStilt:SmallShorebird), na.rm=T))

shorecounts <- shorecounts %>%
  mutate(siteTOD = interaction(Site, tod, drop = TRUE),
         siteMonth = interaction(Site, month, drop = TRUE),
         todMonth = interaction(tod, month, drop = TRUE),
         siteTODMonth = interaction(Site, tod, month, drop = TRUE))

countsavg <- shorecounts %>%
  ungroup() %>%
  select(Site, month, BandedStilt, RedcappedPlover, RedcappedPlover, RedneckedAvocet,  shoreabun) %>%
  gather(Species, Counts, BandedStilt:shoreabun) %>%
  group_by(Site, Species) %>%
  summarise(meancount=mean(Counts),
            sdcount=sd(Counts))

countsavg <- countsavg  %>%
  mutate(Species = dplyr::recode(Species, 
                                 shoreabun="Total abundance",
                                 BandedStilt="Banded Stilt",
                                 RedcappedPlover="Red-capped Plover",
                                 RedneckedAvocet="Red-necked Avocet",
                                 RedneckedStint="Red-necked Stint"))

countsavgtot <- countsavg %>%
  filter(Species == "Total abundance")

countsavgsel <- countsavg %>%
  filter(Species != "Total abundance")

level_order <- c('NC1', 'NC2', 'NC3', 'SL1', 'SL2', 'SL3', 'SC') 

plotsiteavg1 <- ggplot(countsavgtot, aes(x=factor(Site, level = level_order), y=meancount))+
  geom_bar(stat="identity", width=0.7) +
  geom_errorbar(aes(x=factor(Site, level = level_order), 
                ymin=ifelse(meancount-sdcount< 0, 0, meancount-sdcount),                 
                ymax=meancount+sdcount)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(x = "", y = "Total average shorebird abundance") +
  ggtitle("a")
plotsiteavg1

ggsave("./03_plots/plotsiteavg1.png", plot = plotsiteavg1, width = 6, height = 3, dpi = 300)

plotsiteavg2 <- ggplot(countsavgsel, aes(x=factor(Site, level = level_order), y=meancount)) +
  geom_bar(stat="identity", width=0.9) +
  geom_errorbar(aes(x=factor(Site, level = level_order), ymin=ifelse(meancount-sdcount< 0, 0,   
                meancount-sdcount), ymax=meancount+sdcount)) +
  theme_minimal() +
  theme(axis.text.x = element_text(vjust=0.5, angle = 90)) +
  facet_wrap(~Species, ncol = 4, scales = "free") +
  labs(x = "", y = "Average abundance") +
  ggtitle("b") +
  theme(legend.position="none")
plotsiteavg2

ggsave("./03_plots/plotsiteavg2.png", plot = plotsiteavg2, width = 6, height = 2, dpi = 300)

monthcountmax <- shorecounts %>%
  group_by(Site, month) %>%
  summarise(across(BandedStilt:shoreabun, ~ max(., na.rm = TRUE))) 

monthcountmax <- monthcountmax %>%
  group_by(month) %>%
  summarise(across(BandedStilt:shoreabun, ~ sum(., na.rm = TRUE))) 

monthcountmax <- monthcountmax %>%
  gather(Species, Abundance, BandedStilt:shoreabun) %>%
  filter(Species!="SmallShorebird")

monthcountmax <- monthcountmax %>%
  mutate(Species = dplyr::recode(Species, 
                                 shoreabun="Total abundance",
                                 BandedStilt="Banded Stilt",
                                 CommonGreenshank="Common Greenshank",
                                 CommonSandpiper="Common Sandpiper",
                                 CurlewSandpiper="Curlew Sandpiper",
                                 MaskedLapwing="Masked Lapwing",
                                 PiedOystercatcher="Pied Oystercatcher",
                                 PiedStilt = "Pied Stilt",
                                 RedcappedPlover="Red-capped Plover",
                                 RedneckedAvocet="Red-necked Avocet",
                                 RedneckedStint="Red-necked Stint",
                                 SharptailedSandpiper="Sharp-tailed Sandpiper"))
  
plotmonthabun <- ggplot(monthcountmax, aes(x=month, y=Abundance, group=1)) +
  geom_point () +
  geom_line () +
  scale_y_continuous(expand = c(0.1, 0.1), limits = c(0, NA)) +
  labs(x = "Month (April 2021 - March 2022)", y = "Abundance") +
  facet_wrap(~Species, scales = "free_y")
plotmonthabun

ggsave("./03_plots/plotmonthabun.png", plot = plotmonthabun, width = 7, height = 4, dpi = 300)

allmonthscountmax <- shorecounts %>%
  group_by(Site, month) %>%
  summarise(across(BandedStilt:shoreabun, ~ max(., na.rm = TRUE))) 

allmonthscountmax <- allmonthscountmax %>%
  summarise(across(BandedStilt:shoreabun, ~ sum(., na.rm = TRUE)))

allmonthscountmax <- allmonthscountmax %>%
  gather(Species, Abundance, BandedStilt:shoreabun)%>%
  filter(Species!="shoreabun")%>%
  spread(Site, Abundance)%>%
  rowwise() %>%
  mutate(All = sum(c_across(NC1:SL3), na.rm=T))%>%
  gather(Site, Abundance, NC1:All)

level_order1 <- c('NC1', 'NC2', 'NC3', 'SL1', 'SL2', 'SL3', 'SC', 'All')   

allmonthscountmax <- allmonthscountmax %>%
  mutate(Species = dplyr::recode(Species, 
                                 BandedStilt="Banded Stilt",
                                 CommonGreenshank="Common Greenshank",
                                 CommonSandpiper="Common Sandpiper",
                                 CurlewSandpiper="Curlew Sandpiper",
                                 DoubleBandedPlover="Double-banded Plover",
                                 MaskedLapwing="Masked Lapwing",
                                 PiedOystercatcher="Pied Oystercatcher",
                                 PiedStilt = "Pied Stilt",
                                 RedcappedPlover="Red-capped Plover",
                                 RedneckedAvocet="Red-necked Avocet",
                                 RedneckedStint="Red-necked Stint",
                                 SharptailedSandpiper="Sharp-tailed Sandpiper",
                                 SmallShorebird="Small Shorebird"))

plotallmonthsmax <- ggplot(allmonthscountmax, aes(fill = Species, x=factor(Site, level = level_order1), y=Abundance)) +
  geom_bar(position="fill", stat="identity", width=0.9) +
  theme_minimal() +
  theme(axis.text.x = element_text(vjust=0.5, angle = 90)) +
  labs(x = "", y = "Abundance") +
  ggtitle("") 
plotallmonthsmax <- plotallmonthsmax +  scale_fill_manual(values=Blue2DarkRed18Steps)
plotallmonthsmax

ggsave("./03_plots/plotallmonthsmax.png", plot = plotallmonthsmax, width = 6, height = 5, dpi = 300)

monthlysitesal <-
  shorecounts %>%
  select(Date, Site, month, Salinity) %>%
  group_by(Site, month) %>%
  summarise(avgsal=mean(Salinity),
            maxsal=max(Salinity),
            minsal=min(Salinity))

monthlysitesal <- arrange(transform(monthlysitesal,
       Site=factor(Site,levels=level_order)),Site)

monthlysitesalplot <-
  ggplot(monthlysitesal, aes(month, avgsal)) +
  geom_point(size=0.5) + 
  geom_pointrange(aes(ymin = minsal, ymax = maxsal), size=0.3)+
  labs(x = "Month", y = "Average salinity (ppt)") +
  ggtitle ("A") +
  facet_wrap(~Site, ncol = 4)
monthlysitesalplot

ggsave("./03_plots/monthlysitesalplot.png", plot = monthlysitesalplot, width = 6, height = 3, dpi = 300)

monthlysitehab <-
  shorecounts %>%
  select(Date, Site, month, mudshal) %>%
  group_by(Site, month) %>%
  summarise(avghab=mean(mudshal),
            maxhab=max(mudshal),
            minhab=min(mudshal))

monthlysitehab <- arrange(transform(monthlysitehab,
       Site=factor(Site,levels=level_order)),Site)

monthlysitehabplot <-
  ggplot(monthlysitehab, aes(month, avghab)) +
  geom_point(size=0.5) + 
  geom_pointrange(aes(ymin = minhab, ymax = maxhab), size=0.3)+
  labs(x = "Month", y = "Average potential habitat area (ha)") +
  ggtitle ("B") +
  facet_wrap(~Site, ncol = 4)
monthlysitehabplot

ggsave("./03_plots/monthlysitehabplot.png", plot = monthlysitehabplot, width = 6, height = 3, dpi = 300)

benthic_data <- read_csv("./01_data/CoorongBenthicSampling.csv") 

benthictotal <- benthic_data %>%
  mutate(Total = select(., Oligochaeta:Other) %>%
         rowSums(na.rm = TRUE)) %>%
  mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
  mutate(month = factor(format(Date, "%m"), 
         levels = c('04', '06', '08', '10', '12', '02', '03'))) 

benthictable <- benthictotal %>%
  summarise(across(Oligochaeta:Total, ~ sum(., na.rm = TRUE))) %>%
  gather(taxa, total_count) %>%
  mutate(percentage = total_count/15039*100)%>% 
  mutate_at(3, round, 2)%>%
  arrange(desc(total_count))
benthictable

tab_df(benthictable, file='./04_outputs/benthictable.doc')

benthicavg <- benthictotal %>%
  select(Site, month, Total, Polychaete_Simplisetia, Diptera_Chironomid, Amphipod) %>%
  group_by(Site, month) %>%
  summarise(avgtot = mean(Total),
         maxtotal = max(Total),
         mintotal = min(Total),
         avgsimp = mean(Polychaete_Simplisetia),
         maxsimp = max(Polychaete_Simplisetia),
         minsimp = min(Polychaete_Simplisetia),
         avgchi = mean(Diptera_Chironomid),
         maxchi = max(Diptera_Chironomid),
         minchi = min(Diptera_Chironomid),
         avgamp = mean(Amphipod),
         maxamp = max(Amphipod),
         minamp = min(Amphipod))

benthicavg1 <- benthicavg %>%
  mutate(avgtotm2 = avgtot*(1/0.0064),
         maxtotm2 = maxtotal*(1/0.0064),
         mintotm2 = mintotal*(1/0.0064),
         avgsimpm2 = avgsimp*(1/0.0064),
         maxsimpm2 = maxsimp*(1/0.0064), 
         minsimpm2 = minsimp*(1/0.0064),
         avgchim2 = avgchi*(1/0.0064),
         maxchim2 = maxchi*(1/0.0064), 
         minchim2 = minchi*(1/0.0064), 
         avgampm2 = avgamp*(1/0.0064), 
         maxampm2 = maxamp*(1/0.0064),
         minampm2 = minamp*(1/0.0064), 
         )

level_order1 <- c('NC1', 'NC2', 'NC3', 'SL1', 'SL2', 'SL3', 'SC') 

benthicavg1 <- arrange(transform(benthicavg1,
                Site=factor(Site,levels=level_order1)),Site)

benthicavgtotpersite <-
  ggplot(benthicavg1, aes(month, avgtotm2)) +
  geom_point() +
  geom_errorbar(aes(ymin=mintotm2, ymax=maxtotm2), width=.1)+
  labs(x = "Month", y = "Avg total invertebrates (m2)") +
  facet_wrap(~Site, ncol = 4) +
  ggtitle("A")
benthicavgtotpersite

ggsave("./03_plots/benthicavgtotpersite.png", plot = benthicavgtotpersite, width = 6, height = 3, dpi = 300)

benthicavgchironpersite <-
  ggplot(benthicavg1, aes(month, avgchim2)) +
  geom_point() +
  geom_errorbar(aes(ymin=minchim2, ymax=maxchim2), width=.1)+
  labs(x = "Month", y = "Avg chironomid larvae (m2)") +
  facet_wrap(~Site, ncol = 4) +
  ggtitle("B")
benthicavgchironpersite

ggsave("./03_plots/benthicavgchironpersite.png", plot = benthicavgchironpersite, width = 6, height = 3, dpi = 300)

benthicavgamppersite <-
  ggplot(benthicavg1, aes(month, avgampm2)) +
  geom_point() +
  geom_errorbar(aes(ymin=minampm2, ymax=maxampm2), width=.1)+
  labs(x = "Month", y = "Avg amphipods (m2)") +
  facet_wrap(~Site, ncol = 4)+
  ggtitle("C")
benthicavgamppersite

ggsave("./03_plots/benthicavgamppersite.png", plot = benthicavgamppersite, width = 6, height = 3, dpi = 300)

benthicavgsimppersite <-
  ggplot(benthicavg1, aes(month, avgsimpm2)) +
  geom_point() +
  geom_errorbar(aes(ymin=minsimpm2, ymax=maxsimpm2), width=.1)+
  labs(x = "Month", y = "Avg Simplisetia (m2)") +
  facet_wrap(~Site, ncol = 4) +
  ggtitle("D")
benthicavgsimppersite

ggsave("./03_plots/benthicavgsimppersite.png", plot = benthicavgsimppersite, width = 6, height = 3, dpi = 300)

prey_data <- benthic_data %>%
  select(Date, tod, Site, Sample_num, Polychaete_Simplisetia, Diptera_Chironomid, Amphipod)

preytotal <- prey_data %>%
  mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
  mutate(month = factor(format(Date, "%m"), 
         levels = c('04', '06', '08', '10', '12', '02', '03'))) %>%
  mutate(total = select(., Polychaete_Simplisetia:Amphipod) %>%
         rowSums(na.rm = TRUE)) %>%
  mutate (siteTODMonth = interaction(Site, tod, month, drop = TRUE))

with(preytotal, hist(total))

with(preytotal, plot(month, total))

preyden <- preytotal %>%
  group_by(Date, Site, tod, siteTODMonth) %>%
  summarise_at(.vars = vars(total),
               .funs = c(den="mean")) 

preyden <- preyden %>%
  mutate(logden=log(den+1))

shorecountsprey <- left_join(shorecounts, preyden)

shorecountsprey <- shorecountsprey %>%
  group_by(Site) %>%
  mutate(avgprey = mean(logden)) %>%
  mutate(prey.c = as.vector(scale(logden, scale = TRUE)))%>%
  ungroup()

glmmpoimonthnull <- glmmTMB(shoreabun ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmpoimonthnull)

car::Anova(glmmpoimonthnull)

performance::check_overdispersion(glmmpoimonthnull)

plot(simres <- simulateResiduals(glmmpoimonthnull))

glmmmonthnull_total <- glmmTMB(shoreabun ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmmonthnull_total)

car::Anova(glmmmonthnull_total)

plot(simres <- simulateResiduals(glmmmonthnull_total))

glmmmonth_total <- glmmTMB(shoreabun ~ tod + month + month*tod + 
                       (1|Site) + (1|siteMonth), 
                     data = shorecountsprey, family = 'nbinom2')
summary(glmmmonth_total)

plot(simres <- simulateResiduals(glmmmonth_total))

car::Anova(glmmmonth_total)

testZeroInflation(simres, plot = FALSE)

month.model.est_total <- as.data.frame(emmeans(glmmmonth_total, specs = "month"))
tod.model.est_total <- as.data.frame(emmeans(glmmmonth_total, specs = "tod"))

pd <- position_dodge(width = 0.5)

plotmonth_total <- ggplot(month.model.est_total, aes(x = month, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Total shorebird abundance") +
  ggtitle("A")
plotmonth_total

ggsave("./03_plots/plotmonth_total.png", plot = plotmonth_total, width = 6, height = 6, dpi = 300)


plottod_total <- ggplot(tod.model.est_total, aes(x = tod, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Total shorebird abundance")+
  ggtitle("A")
plottod_total

ggsave("./03_plots/plottod_total.png", plot = plottod_total, width = 6, height = 6, dpi = 300)

glmmpoimonthnull <- glmmTMB(RedneckedStint ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmpoimonthnull)

car::Anova(glmmpoimonthnull)

performance::check_overdispersion(glmmpoimonthnull)

plot(simres <- simulateResiduals(glmmpoimonthnull))

glmmmonthnull_REST <- glmmTMB(RedneckedStint ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmmonthnull_REST)

car::Anova(glmmmonthnull_REST)

plot(simres <- simulateResiduals(glmmmonthnull_REST))

glmmmonth_REST <- glmmTMB(RedneckedStint ~ tod + month + month*tod + 
                       (1|Site) + (1|siteMonth), 
                     data = shorecountsprey, family = 'nbinom2')
summary(glmmmonth_REST)

plot(simres <- simulateResiduals(glmmmonth_REST))

car::Anova(glmmmonth_REST)

testZeroInflation(simres, plot = FALSE)

month.model.est_REST <- as.data.frame(emmeans(glmmmonth_REST, specs = "month"))
tod.model.est_REST <- as.data.frame(emmeans(glmmmonth_REST, specs = "tod"))

pd <- position_dodge(width = 0.5)

plotmonth_REST <- ggplot(month.model.est_REST, aes(x = month, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Red-necked Stint abundance") +
  ggtitle("B")
plotmonth_REST

ggsave("./03_plots/plotmonth_REST.png", plot = plotmonth_REST, width = 6, height = 6, dpi = 300)


plottod_REST <- ggplot(tod.model.est_REST, aes(x = tod, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Red-necked Stint abundance")+
  ggtitle("B")
plottod_REST

ggsave("./03_plots/plottod_REST.png", plot = plottod_REST, width = 6, height = 6, dpi = 300)

glmmpoimonthnull <- glmmTMB(RedcappedPlover ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmpoimonthnull)

car::Anova(glmmpoimonthnull)

performance::check_overdispersion(glmmpoimonthnull)

plot(simres <- simulateResiduals(glmmpoimonthnull))

glmmmonthnull_REPL <- glmmTMB(RedcappedPlover ~ 1 + (1|Site) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmmonthnull_REPL)

car::Anova(glmmmonthnull_REPL)

plot(simres <- simulateResiduals(glmmmonthnull_REPL))

glmmmonth_REPL <- glmmTMB(RedcappedPlover ~ tod + month + month*tod + 
                       (1|Site) + (1|siteMonth), 
                     data = shorecountsprey, family = 'nbinom2')
summary(glmmmonth_REPL)

plot(simres <- simulateResiduals(glmmmonth_REPL))

car::Anova(glmmmonth_REPL)

testZeroInflation(simres, plot = FALSE)

month.model.est_REPL <- as.data.frame(emmeans(glmmmonth_REPL, specs = "month"))
tod.model.est_REPL <- as.data.frame(emmeans(glmmmonth_REPL, specs = "tod"))

pd <- position_dodge(width = 0.5)

plotmonth_REPL <- ggplot(month.model.est_REPL, aes(x = month, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Red-capped Plover abundance") +
  ggtitle("C")
plotmonth_REPL

ggsave("./03_plots/plotmonth_REPL.png", plot = plotmonth_REPL, width = 6, height = 6, dpi = 300)


plottod_REPL <- ggplot(tod.model.est_REPL, aes(x = tod, y = emmean)) +
  geom_point(size = 3, position = pd) + geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.5, position = pd) +
  scale_y_continuous(breaks = log(c(0.01, 0.1, 1, 10, 100, 1000)), labels = c(0.01, 0.1, 1, 10, 100, 1000)) +
  theme_bw(base_size = 18) +
  labs(y = "Red-capped Plover abundance") +
  ggtitle("C")
plottod_REPL

ggsave("./03_plots/plottod_REPL.png", plot = plottod_REPL, width = 6, height = 6, dpi = 300)

glmmnull_poi_total <- glmmTMB(shoreabun ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmnull_poi_total)

car::Anova(glmmnull_poi_total)

performance::check_overdispersion(glmmnull_poi_total)

plot(simres <- simulateResiduals(glmmnull_poi_total))

glmmtod_poi_total <- glmmTMB(shoreabun ~ tod + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmtod_poi_total)

car::Anova(glmmtod_poi_total)

performance::check_overdispersion(glmmtod_poi_total)

plot(simres <- simulateResiduals(glmmtod_poi_total))

glmmnull_nb_total <- glmmTMB(shoreabun ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmnull_nb_total)

car::Anova(glmmnull_nb_total)

plot(simres <- simulateResiduals(glmmnull_nb_total))

testZeroInflation(simres, plot = FALSE)

glmmtod_nb_total <- glmmTMB(shoreabun ~ tod + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmtod_nb_total)

car::Anova(glmmtod_nb_total)

plot(simres <- simulateResiduals(glmmtod_nb_total))

testZeroInflation(simres, plot = FALSE)

glmm_sal_nb_total <- glmmTMB(shoreabun ~ tod + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_salC_nb_total <- glmmTMB(shoreabun ~ tod + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_sal2_nb_total <- glmmTMB(shoreabun ~ tod + avgsal + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal1_nb_total <- glmmTMB(shoreabun ~ tod + avgmudshal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal2_nb_total <- glmmTMB(shoreabun ~ tod + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal3_nb_total <- glmmTMB(shoreabun ~ tod + avgmudshal + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey1_nb_total <- glmmTMB(shoreabun ~ tod + avgprey + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey2_nb_total <- glmmTMB(shoreabun ~ tod + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey3_nb_total <- glmmTMB(shoreabun ~ tod + avgprey + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind1_nb_total <- glmmTMB(shoreabun ~ tod + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind2_nb_total <- glmmTMB(shoreabun ~ tod + Windspeed + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_temp_nb_total <- glmmTMB(shoreabun ~ tod + Temperature + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalwind_nb_total <- glmmTMB(shoreabun ~ tod + avgmudshal + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalsal_nb_total <- glmmTMB(shoreabun ~ tod + avgmudshal + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

AICtabletotal <-
  AICctab(glmmnull_nb_total, glmmtod_nb_total, 
        glmm_sal_nb_total, glmm_salC_nb_total, glmm_sal2_nb_total, 
        glmm_mudshal1_nb_total, glmm_mudshal2_nb_total, glmm_mudshal3_nb_total,
        glmm_prey1_nb_total, glmm_prey2_nb_total, glmm_prey3_nb_total,
        glmm_wind1_nb_total, glmm_wind2_nb_total,
        glmm_temp_nb_total, glmm_mudshalwind_nb_total, glmm_mudshalsal_nb_total, 
        base = TRUE, weights = TRUE)

tab_df(AICtabletotal, file='./04_outputs/AICtableall_total.doc')

write.csv(AICtabletotal, './04_outputs/AICtableall_total.csv')

r.squaredGLMM(glmm_mudshal3_nb_total)

car::Anova(glmm_mudshal3_nb_total)

plot(simres <- simulateResiduals(glmm_mudshal3_nb_total))

testZeroInflation(simres, plot = FALSE)

Topmodeltotal1 <- tidy(glmm_mudshal3_nb_total)

tab_df(Topmodeltotal1, file='./04_outputs/Topmodeltotal1.doc')

write.csv(Topmodeltotal1, './04_outputs/Topmodeltotal1.csv')

r.squaredGLMM(glmm_mudshal1_nb_total)

car::Anova(glmm_mudshal1_nb_total)

plot(simres <- simulateResiduals(glmm_mudshal1_nb_total))

testZeroInflation(simres, plot = FALSE)

Topmodeltotal2 <- tidy(glmm_mudshal1_nb_total)

tab_df(Topmodeltotal2, file='./04_outputs/Topmodeltotal2.doc')

write.csv(Topmodeltotal2, './04_outputs/Topmodeltotal2.csv')

r.squaredGLMM(glmm_mudshalwind_nb_total)

car::Anova(glmm_mudshalwind_nb_total)

plot(simres <- simulateResiduals(glmm_mudshalwind_nb_total))

testZeroInflation(simres, plot = FALSE)

Topmodeltotal3 <- tidy(glmm_mudshalwind_nb_total)

tab_df(Topmodeltotal3, file='./04_outputs/Topmodeltotal3.doc')

write.csv(Topmodeltotal3, './04_outputs/Topmodeltotal3.csv')

glmmnull_poi_REST <- glmmTMB(RedneckedStint ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmnull_poi_REST)

car::Anova(glmmnull_poi_REST)

performance::check_overdispersion(glmmnull_poi_REST)

plot(simres <- simulateResiduals(glmmnull_poi_REST))

glmmtod_poi_REST <- glmmTMB(RedneckedStint ~ tod + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmtod_poi_REST)

car::Anova(glmmtod_poi_REST)

performance::check_overdispersion(glmmtod_poi_REST)

plot(simres <- simulateResiduals(glmmtod_poi_REST))

glmmnull_nb_REST <- glmmTMB(RedneckedStint ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmnull_nb_REST)

car::Anova(glmmnull_nb_REST)

plot(simres <- simulateResiduals(glmmnull_nb_REST))

testZeroInflation(simres, plot = FALSE)

glmmtod_nb_REST <- glmmTMB(RedneckedStint ~ tod +  (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmtod_nb_REST)

car::Anova(glmmtod_nb_REST)

plot(simres <- simulateResiduals(glmmtod_nb_REST))

testZeroInflation(simres, plot = FALSE)

glmm_sal_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_salC_nb_REST <- glmmTMB(RedneckedStint ~ tod + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_sal2_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgsal + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal1_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgmudshal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal2_nb_REST <- glmmTMB(RedneckedStint ~ tod + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal3_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgmudshal + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey1_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgprey + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey2_nb_REST <- glmmTMB(RedneckedStint ~ tod + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey3_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgprey + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind1_nb_REST <- glmmTMB(RedneckedStint ~ tod + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind2_nb_REST <- glmmTMB(RedneckedStint ~ tod + Windspeed + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_temp_nb_REST <- glmmTMB(RedneckedStint ~ tod + Temperature + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalwind_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgmudshal + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalsal_nb_REST <- glmmTMB(RedneckedStint ~ tod + avgmudshal + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

AICtableREST <-
  AICctab(glmmnull_nb_REST, glmmtod_nb_REST, 
        glmm_sal_nb_REST, glmm_salC_nb_REST, glmm_sal2_nb_REST, 
        glmm_mudshal1_nb_REST, glmm_mudshal2_nb_REST, glmm_mudshal3_nb_REST,
        glmm_prey1_nb_REST, glmm_prey2_nb_REST, glmm_prey3_nb_REST,
        glmm_wind1_nb_REST, glmm_wind2_nb_REST,
        glmm_temp_nb_REST, glmm_mudshalwind_nb_REST, glmm_mudshalsal_nb_REST, 
        base = TRUE, weights = TRUE)

tab_df(AICtableREST, file='./04_outputs/AICtableall_REST.doc')

write.csv(AICtableREST, './04_outputs/AICtableall_REST.csv')

r.squaredGLMM(glmm_mudshal3_nb_REST)

car::Anova(glmm_mudshal3_nb_REST)

plot(simres <- simulateResiduals(glmm_mudshal3_nb_REST))

testZeroInflation(simres, plot = FALSE)

TopmodelREST <- tidy(glmm_mudshal3_nb_REST)

tab_df(TopmodelREST, file='./04_outputs/TopmodelREST.doc')

write.csv(TopmodelREST, './04_outputs/TopmodelREST.csv')

glmmnull_poi_REPL <- glmmTMB(RedcappedPlover ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmnull_poi_REPL)

car::Anova(glmmnull_poi_REPL)

performance::check_overdispersion(glmmnull_poi_REPL)

plot(simres <- simulateResiduals(glmmnull_poi_REPL))

glmmtod_poi_REPL <- glmmTMB(RedcappedPlover ~ tod + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = poisson)
summary(glmmtod_poi_REPL)

car::Anova(glmmtod_poi_REPL)

performance::check_overdispersion(glmmtod_poi_REPL)

plot(simres <- simulateResiduals(glmmtod_poi_REPL))

glmmnull_nb_REPL <- glmmTMB(RedcappedPlover ~ 1 + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmnull_nb_REPL)

car::Anova(glmmnull_nb_REPL)

plot(simres <- simulateResiduals(glmmnull_nb_REPL))

testZeroInflation(simres, plot = FALSE)

glmmtod_nb_REPL <- glmmTMB(RedcappedPlover ~ tod +  (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')
summary(glmmtod_nb_REPL)

car::Anova(glmmtod_nb_REPL)

plot(simres <- simulateResiduals(glmmtod_nb_REPL))

testZeroInflation(simres, plot = FALSE)

glmm_sal_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_salC_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_sal2_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgsal + Salinity.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal1_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgmudshal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal2_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshal3_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + + avgmudshal + Mudshal.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey1_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgprey + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey2_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_prey3_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgprey + prey.c + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind1_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_wind2_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + Windspeed + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_temp_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + Temperature + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalwind_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgmudshal + Winddirection + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

glmm_mudshalsal_nb_REPL <- glmmTMB(RedcappedPlover ~ tod + avgmudshal + avgsal + (1|Site) + (1|month) + (1|siteMonth), data = shorecountsprey, family = 'nbinom2')

AICtableREPL <-
  AICctab(glmmnull_nb_REPL, glmmtod_nb_REPL, 
        glmm_sal_nb_REPL, glmm_salC_nb_REPL, glmm_sal2_nb_REPL, 
        glmm_mudshal1_nb_REPL, glmm_mudshal2_nb_REPL, glmm_mudshal3_nb_REPL,
        glmm_prey1_nb_REPL, glmm_prey2_nb_REPL, glmm_prey3_nb_REPL,
        glmm_wind1_nb_REPL, glmm_wind2_nb_REPL,
        glmm_temp_nb_REPL, glmm_mudshalwind_nb_REPL, glmm_mudshalsal_nb_REPL, 
        base = TRUE, weights = TRUE)

tab_df(AICtableREPL, file='./04_outputs/AICtableall_REPL.doc')

write.csv(AICtableREPL, './04_outputs/AICtableall_REPL.csv')

r.squaredGLMM(glmm_mudshal3_nb_REPL)

car::Anova(glmm_mudshal3_nb_REPL)

plot(simres <- simulateResiduals(glmm_mudshal3_nb_REPL))

testZeroInflation(simres, plot = FALSE)

TopmodelREPL <- tidy(glmm_mudshal3_nb_REPL)

tab_df(TopmodelREPL, file='./04_outputs/TopmodelREPL.doc')

write.csv(TopmodelREPL, './04_outputs/TopmodelREPL.csv')

new_data <- data.frame(tod='am', avgmudshal=mean(shorecountsprey$avgmudshal), 
                       Mudshal.c=mean(shorecountsprey$Mudshal.c),
                       Site=shorecountsprey$Site[1], month=shorecountsprey$month[1],
                       siteMonth=shorecountsprey$siteMonth[1])
new_data1 <- new_data2 <- new_data[rep(1,100),] 
new_data1$avgmudshal <- seq(min(shorecountsprey$avgmudshal), max(shorecountsprey$avgmudshal), length.out=100)
new_data1$x <- new_data1$avgmudshal
new_data1$Variable <- 'Average Potential Habitat'
new_data2$Mudshal.c <- seq(min(shorecountsprey$Mudshal.c), max(shorecountsprey$Mudshal.c), length.out=100)
new_data2$Variable <- 'Standardised Potential Habitat'
new_data2$x <- new_data2$Mudshal.c
new_data <- rbind(new_data1, new_data2)

ilink_REST <- family(glmm_mudshal3_nb_REST)$linkinv

pred_REST <- predict(glmm_mudshal3_nb_REST, new_data, type = "link", se.fit = TRUE, re.form=~0)
pred_REST <- cbind(pred_REST, new_data)

pred_REST <- transform(pred_REST, lwr_ci = ilink_REST(fit - (1.96* se.fit)),
                  upr_ci = ilink_REST(fit + (1.96 * se.fit)),
                  fitted = ilink_REST(fit))

predicted_REST <- ggplot(pred_REST, aes(x, fitted)) + 
  geom_ribbon(aes(ymin=lwr_ci, ymax=upr_ci), fill='blue', alpha=0.2, ) +
  geom_line(colour='blue', size=1) + 
  scale_y_log10() +
  facet_grid(~Variable, scales='free_x', switch='x') +
  ggtitle("A") +
  xlab('') +
  ylab('Estimated Red-necked Stint abundance') + theme_bw() +
  theme(strip.placement='outside',strip.background = element_blank())

predicted_REST

ggsave("./03_plots/predicted_REST.png", plot = predicted_REST, width = 8, height = 5, dpi = 300)

ilink_REPL <- family(glmm_mudshal3_nb_REPL)$linkinv

pred_REPL <- predict(glmm_mudshal3_nb_REPL, new_data, type = "link", se.fit = TRUE, re.form=~0)
pred_REPL <- cbind(pred_REPL, new_data)

pred_REPL <- transform(pred_REPL, lwr_ci = ilink_REPL(fit - (1.96* se.fit)),
                  upr_ci = ilink_REPL(fit + (1.96 * se.fit)),
                  fitted = ilink_REPL(fit))

options(scipen=999)

predicted_REPL <- ggplot(pred_REPL, aes(x, fitted)) + 
  geom_ribbon(aes(ymin=lwr_ci, ymax=upr_ci), fill='blue', alpha=0.2, ) +
  geom_line(colour='blue', size=1) + 
  scale_y_log10(labels = label_number(drop0trailing = TRUE)) +
  facet_grid(~Variable, scales='free_x', switch='x') +
  ggtitle("B") +
  xlab('') +
  ylab('Estimated Red-capped Plover abundance') + theme_bw() +
  theme(strip.placement='outside',strip.background = element_blank())

predicted_REPL

ggsave("./03_plots/predicted_REPL.png", plot = predicted_REPL, width = 8, height = 5, dpi = 300)


predicted_both <- ggplot() + 
  geom_line(data = pred_REST, aes(x, fitted, colour='Red-necked Stint')) + 
  geom_ribbon(data = pred_REST, aes(x, fitted, ymin=lwr_ci, ymax=upr_ci), 
              fill='red', alpha=0.2, ) +
  geom_line(data = pred_REPL, aes(x, fitted, colour='Red-capped Plover')) + 
  geom_ribbon(data = pred_REPL, aes(x, fitted, ymin=lwr_ci, ymax=upr_ci), 
              fill='blue', alpha=0.2, ) +
  scale_y_log10(labels = label_number(drop0trailing = TRUE)) +
  facet_grid(~Variable, scales='free_x', switch='x') +
  scale_color_manual(name='Species',
                     breaks=c('Red-necked Stint', 'Red-capped Plover'),
                     values=c('Red-necked Stint'='red', 'Red-capped Plover'='blue')) +
  xlab('') +
  ylab('Estimated abundance') + theme_bw() +
  theme(strip.placement='outside',strip.background = element_blank())
predicted_both

ggsave("./03_plots/predicted_both.png", plot = predicted_both, width = 8, height = 3.5, dpi = 300)

shfor <- read_csv("./01_data/CoorongForagingVideos.csv")

shfor <- shfor %>%
  filter(Difficulty != "High") %>%
  mutate(peckprobe = Pecks + Probes)

shfor <- shfor %>%
  mutate(pprate = (peckprobe/Time_sec)*60,
         steprate = (Steps/Time_sec)*60) 

shfor <- shfor %>%
  mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
  mutate(month = factor(format(Date, "%m"), levels = c('04', '06', '08', '10', '12', '02', '03'))) %>%
  mutate(day = format(Date, "%d"))

foragesumm1 <- shfor %>%
  count(Species)
  
foragesumm2 <- shfor %>%
  count(Site)

meanrates <- shfor %>%
  select(Species, pprate, steprate) %>%
  group_by(Species) %>%
  summarise(meanpp=mean(pprate),
            meanstep=mean(steprate),
            sdpp=sd(pprate),
            sdstep=sd(steprate))

level_order1 <- c('NC1', 'NC2', 'NC3', 'SL1', 'SL2', 'SL3', 'SC') 

RESTfor <- shfor %>%
  filter(Species=="REST")

REPLfor <- shfor %>%
  filter(Species=="REPL")

PPpersite_REST <-
  ggplot(RESTfor, aes(x=factor(Site, level = level_order1), pprate)) +
  labs(x = "Site", y = "(pecks+probes)/minute") +
  theme(text = element_text(size=18)) +
  geom_boxplot() +
  ggtitle("A - Pecks plus probes rate - Red-necked Stint")
PPpersite_REST

ggsave("./03_plots/PPpersite_REST.png", plot = PPpersite_REST, width = 10, height = 5, dpi = 300)

PPpersite_REPL <-
  ggplot(REPLfor, aes(x=factor(Site, level = level_order1), pprate)) +
  labs(x = "Site", y = "(pecks+probes)/minute") +
  theme(text = element_text(size=18)) +
  geom_boxplot() +
  ggtitle("B - Pecks plus probes rate - Red-capped Plove")
PPpersite_REPL

ggsave("./03_plots/PPpersite_REPL.png", plot = PPpersite_REPL, width = 10, height = 5, dpi = 300)

stepspersite_REST <-
  ggplot(RESTfor, aes(x=factor(Site, level = level_order1), steprate)) +
  labs(x = "Site", y = "steps/minute") +
  theme(text = element_text(size=18)) +
  geom_boxplot() +
  ggtitle("C - Step rate - Red-necked Stint")
stepspersite_REST

ggsave("./03_plots/stepspersite_REST.png", plot = stepspersite_REST, width = 10, height = 5, dpi = 300)


stepspersite_REPL <-
  ggplot(REPLfor, aes(x=factor(Site, level = level_order1), steprate)) +
  labs(x = "Site", y = "steps/minute") +
  theme(text = element_text(size=18)) +
  geom_boxplot() +
  ggtitle("D - Step rate - Red-capped Plover")
stepspersite_REPL

ggsave("./03_plots/stepspersite_REPL.png", plot = stepspersite_REPL, width = 10, height = 5, dpi = 300)

sitecharben <-
  shorecountsprey %>%
  select(Date, Site, Winddirection, Windspeed, Salinity,
         MudflatAreaM, ShallowAreaha, mudshal, avgsal, avgmudshal, 
         Salinity.c, Mudshal.c, avgprey, prey.c, 
         tod, month, siteTOD, siteMonth, todMonth, siteTODMonth)

peckstepmod <-
  left_join(shfor, sitecharben)

peckstepmod_REST <-
  peckstepmod %>%
  filter(Species=="REST")

peckstepmod_REPL <-
  peckstepmod %>%
  filter(Species=="REPL")

plotRESTpecksprobes <- ggplot(peckstepmod_REST, aes(x = Time_sec, y = peckprobe)) +
  geom_point(size = 3) +
  labs(x = "Video length in seconds",
       y = "Pecks + probes") +
  ggtitle("a - Red-necked Stint")
plotRESTpecksprobes

ggsave("./03_plots/plotRESTpecksprobes.png", plot = plotRESTpecksprobes, width = 5, height = 3, dpi = 300)

plotREPLpecksprobes <- ggplot(peckstepmod_REPL, aes(x = Time_sec, y = peckprobe)) +
  geom_point(size = 3) +
  labs(x = "Video length in seconds",
       y = "Pecks + probes") +
  ggtitle("b - Red-capped Plover")
plotREPLpecksprobes

ggsave("./03_plots/plotREPLpecksprobes.png", plot = plotREPLpecksprobes, width = 5, height = 3, dpi = 300)

plotRESTsteps <- ggplot(peckstepmod_REST, aes(x = Time_sec, y = Steps)) +
  geom_point(size = 3) +
  labs(x = "Video length in seconds",
       y = "Steps") +
  ggtitle("c - Red-necked Stint")
plotRESTsteps

ggsave("./03_plots/plotRESTsteps.png", plot = plotRESTsteps, width = 5, height = 3, dpi = 300)

plotREPLsteps <- ggplot(peckstepmod_REPL, aes(x = Time_sec, y = Steps)) +
  geom_point(size = 3) +
  labs(x = "Video length in seconds",
       y = "Steps") +
  ggtitle("d - Red-capped Plover")
plotREPLsteps 

ggsave("./03_plots/plotREPLsteps.png", plot = plotREPLsteps, width = 5, height = 3, dpi = 300)

peckstepmod_REST <-
  peckstepmod_REST %>%
  filter(!is.na(MudflatAreaM))

peckstepmod_REPL <-
  peckstepmod_REPL %>%
  filter(!is.na(MudflatAreaM))


glmmpp_REST.null <- glmmTMB(peckprobe ~ 1 + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.tod <- glmmTMB(peckprobe ~ as.factor(tod) + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.sal <- glmmTMB(peckprobe ~ avgsal + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.salC <- glmmTMB(peckprobe ~ Salinity.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.sal2 <- glmmTMB(peckprobe ~ avgsal + Salinity.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.prey <- glmmTMB(peckprobe ~ avgprey + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.preyC <- glmmTMB(peckprobe ~ prey.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.prey2 <- glmmTMB(peckprobe ~ avgprey + prey.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.windD <- glmmTMB(peckprobe ~ Winddirection + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REST.windS <- glmmTMB(peckprobe ~ Windspeed + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

## Model selection
AICtableREST_pp <-
AICctab(glmmpp_REST.null, glmmpp_REST.tod,  
        glmmpp_REST.sal, glmmpp_REST.salC, glmmpp_REST.sal2,
        glmmpp_REST.prey, glmmpp_REST.preyC, glmmpp_REST.prey2, 
        glmmpp_REST.windD, glmmpp_REST.windS, 
        base = TRUE, weights = TRUE)
print(AICtableREST_pp)

tab_df(AICtableREST_pp, file='./04_outputs/AICtableREST_pp.doc')

write.csv(AICtableREST_pp, './04_outputs/AICtableREST_pp.csv')

glmmstep_REST.null <- glmmTMB(Steps ~ 1 + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.tod <- glmmTMB(Steps ~ as.factor(tod) + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.sal <- glmmTMB(Steps ~ avgsal + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.salC <- glmmTMB(Steps ~ Salinity.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.sal2 <- glmmTMB(Steps ~ avgsal + Salinity.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.prey <- glmmTMB(Steps ~ avgprey + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.preyC <- glmmTMB(Steps ~ prey.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.prey2 <- glmmTMB(Steps ~ avgprey + prey.c + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.windD <- glmmTMB(Steps ~ Winddirection + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REST.windS <- glmmTMB(Steps ~ Windspeed + (1|Site) + (1|month), data = peckstepmod_REST, family = 'nbinom2', offset = log(Time_sec/60))

## Model selection
AICtableREST_step <-
AICctab(glmmstep_REST.null, glmmstep_REST.tod,  
        glmmstep_REST.sal, glmmstep_REST.salC, glmmstep_REST.sal2,
        glmmstep_REST.prey, glmmstep_REST.preyC, glmmstep_REST.prey2, 
        glmmstep_REST.windD, glmmstep_REST.windS, 
        base = TRUE, weights = TRUE)
print(AICtableREST_step)

tab_df(AICtableREST_step, file='./04_outputs/AICtableREST_step.doc')

write.csv(AICtableREST_step, './04_outputs/AICtableREST_step.csv')

glmmpp_REPL.null <- glmmTMB(peckprobe ~ 1 + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.tod <- glmmTMB(peckprobe ~ as.factor(tod) + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.sal <- glmmTMB(peckprobe ~ avgsal + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.salC <- glmmTMB(peckprobe ~ Salinity.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.sal2 <- glmmTMB(peckprobe ~ avgsal + Salinity.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.prey <- glmmTMB(peckprobe ~ avgprey + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.preyC <- glmmTMB(peckprobe ~ prey.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.prey2 <- glmmTMB(peckprobe ~ avgprey + prey.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.windD <- glmmTMB(peckprobe ~ Winddirection + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmpp_REPL.windS <- glmmTMB(peckprobe ~ Windspeed + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

## Model selection
AICtableREPL_pp <-
AICctab(glmmpp_REPL.null, glmmpp_REPL.tod,  
        glmmpp_REPL.sal, glmmpp_REPL.salC, glmmpp_REPL.sal2,
        glmmpp_REPL.prey, glmmpp_REPL.preyC, glmmpp_REPL.prey2, 
        glmmpp_REPL.windD, glmmpp_REPL.windS, 
        base = TRUE, weights = TRUE)
print(AICtableREPL_pp)

tab_df(AICtableREPL_pp, file='./04_outputs/AICtableREPL_pp.doc')

write.csv(AICtableREPL_pp, './04_outputs/AICtableREPL_pp.csv')

glmmstep_REPL.null <- glmmTMB(Steps ~ 1 + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.tod <- glmmTMB(Steps ~ as.factor(tod) + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.sal <- glmmTMB(Steps ~ avgsal + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.salC <- glmmTMB(Steps ~ Salinity.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.sal2 <- glmmTMB(Steps ~ avgsal + Salinity.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.prey <- glmmTMB(Steps ~ avgprey + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.preyC <- glmmTMB(Steps ~ prey.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.prey2 <- glmmTMB(Steps ~ avgprey + prey.c + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.windD <- glmmTMB(Steps ~ Winddirection + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

glmmstep_REPL.windS <- glmmTMB(Steps ~ Windspeed + (1|Site) + (1|month), data = peckstepmod_REPL, family = 'nbinom2', offset = log(Time_sec/60))

## Model selection
AICtableREPL_step <-
AICctab(glmmstep_REPL.null, glmmstep_REPL.tod,  
        glmmstep_REPL.sal, glmmstep_REPL.salC, glmmstep_REPL.sal2,
        glmmstep_REPL.prey, glmmstep_REPL.preyC, glmmstep_REPL.prey2, 
        glmmstep_REPL.windD, glmmstep_REPL.windS, 
        base = TRUE, weights = TRUE)
print(AICtableREPL_step)

tab_df(AICtableREPL_step, file='./04_outputs/AICtableREPL_step.doc')

write.csv(AICtableREPL_step, './04_outputs/AICtableREPL_step.csv')

r.squaredGLMM(glmmpp_REST.windD)

car::Anova(glmmpp_REST.windD)

plot(simres <- simulateResiduals(glmmpp_REST.windD))

testZeroInflation(simres, plot = FALSE)

TopmodelREST_pp1 <- tidy(glmmpp_REST.windD)

tab_df(TopmodelREST_pp1, file='./04_outputs/TopmodelREST_pp1.doc')

write.csv(TopmodelREST_pp1, './04_outputs/TopmodelREST_pp1.csv')

r.squaredGLMM(glmmpp_REST.salC)

car::Anova(glmmpp_REST.salC)

plot(simres <- simulateResiduals(glmmpp_REST.salC))

testZeroInflation(simres, plot = FALSE)

TopmodelREST_pp2 <- tidy(glmmpp_REST.salC)

tab_df(TopmodelREST_pp2, file='./04_outputs/TopmodelREST_pp2.doc')

write.csv(TopmodelREST_pp2, './04_outputs/TopmodelREST_pp2.csv')

r.squaredGLMM(glmmpp_REST.sal)

car::Anova(glmmpp_REST.sal)

plot(simres <- simulateResiduals(glmmpp_REST.sal))

testZeroInflation(simres, plot = FALSE)

TopmodelREST_pp3 <- tidy(glmmpp_REST.sal)

tab_df(TopmodelREST_pp3, file='./04_outputs/TopmodelREST_pp3.doc')

write.csv(TopmodelREST_pp3, './04_outputs/TopmodelREST_pp3.csv')

r.squaredGLMM(glmmstep_REST.prey2)

car::Anova(glmmstep_REST.prey2)

plot(simres <- simulateResiduals(glmmstep_REST.prey2))

testZeroInflation(simres, plot = FALSE)

TopmodelREST_step <- tidy(glmmstep_REST.prey2)

tab_df(TopmodelREST_step, file='./04_outputs/TopmodelREST_step.doc')

write.csv(TopmodelREST_step, './04_outputs/TopmodelREST_step.csv')

r.squaredGLMM(glmmpp_REPL.windD)

car::Anova(glmmpp_REPL.windD)

plot(simres <- simulateResiduals(glmmpp_REPL.windD))

testZeroInflation(simres, plot = FALSE)

TopmodelREPL_pp1 <- tidy(glmmpp_REPL.windD)

tab_df(TopmodelREPL_pp1, file='./04_outputs/TopmodelREPL_pp1.doc')

write.csv(TopmodelREPL_pp1, './04_outputs/TopmodelREPL_pp1.csv')

r.squaredGLMM(glmmpp_REPL.salC)

car::Anova(glmmpp_REPL.salC)

plot(simres <- simulateResiduals(glmmpp_REPL.salC))

testZeroInflation(simres, plot = FALSE)

TopmodelREPL_pp2 <- tidy(glmmpp_REPL.salC)

tab_df(TopmodelREPL_pp2, file='./04_outputs/TopmodelREPL_pp2.doc')

write.csv(TopmodelREPL_pp2, './04_outputs/TopmodelREPL_pp2.csv')

r.squaredGLMM(glmmstep_REPL.preyC)

car::Anova(glmmstep_REPL.preyC)

plot(simres <- simulateResiduals(glmmstep_REPL.preyC))

testZeroInflation(simres, plot = FALSE)

TopmodelREPL_step <- tidy(glmmstep_REPL.preyC)

tab_df(TopmodelREPL_step, file='./04_outputs/TopmodelREPL_step.doc')

write.csv(TopmodelREPL_step, './04_outputs/TopmodelREPL_step.csv')

new_stepdataREST <- data.frame(avgprey=mean(peckstepmod_REST$avgprey), 
                       prey.c=mean(peckstepmod_REST$prey.c),
                       Site=peckstepmod_REST$Site[1], month=peckstepmod_REST$month[1],
                       Time_sec=mean(peckstepmod_REST$Time_sec))
new_stepdataREST1 <- new_stepdataREST2 <- new_stepdataREST[rep(1,100),] 
new_stepdataREST1$avgprey <- seq(min(peckstepmod_REST$avgprey), max(peckstepmod_REST$avgprey), length.out=100)
new_stepdataREST1$x <- new_stepdataREST1$avgprey
new_stepdataREST1$Variable <- 'Average Prey Density'
new_stepdataREST2$prey.c <- seq(min(peckstepmod_REST$prey.c), max(peckstepmod_REST$prey.c), length.out=100)
new_stepdataREST2$Variable <- 'Standardised Prey Density'
new_stepdataREST2$x <- new_stepdataREST2$prey.c
new_stepdataREST <- rbind(new_stepdataREST1, new_stepdataREST2)

ilink_RESTstep <- family(glmmstep_REST.prey2)$linkinv

pred_RESTstep <- predict(glmmstep_REST.prey2, new_stepdataREST, type = "link", se.fit = TRUE, re.form=~0)
pred_RESTstep <- cbind(pred_RESTstep, new_stepdataREST)

pred_RESTstep <- transform(pred_RESTstep, lwr_ci = ilink_RESTstep(fit - (1.96* se.fit)),
                  upr_ci = ilink_RESTstep(fit + (1.96 * se.fit)),
                  fitted = ilink_RESTstep(fit))

predicted_RESTstep <- ggplot(pred_RESTstep, aes(x, fitted)) + 
  geom_ribbon(aes(ymin=lwr_ci, ymax=upr_ci), fill='blue', alpha=0.2, ) +
  geom_line(colour='blue', size=1) + 
  scale_y_log10() +
  facet_grid(~Variable, scales='free_x', switch='x') +
  ggtitle("A") +
  xlab('') +
  ylab('Estimated Red-necked Stint step rate') + theme_bw() +
  theme(strip.placement='outside',strip.background = element_blank())

predicted_RESTstep

ggsave("./03_plots/predicted_RESTstep.png", plot = predicted_RESTstep, width = 8, height = 5, dpi = 300)

new_stepdataREPL <- data.frame(prey.c=mean(peckstepmod_REPL$prey.c),
                       Site=peckstepmod_REPL$Site[1], month=peckstepmod_REPL$month[1],
                       Time_sec=mean(peckstepmod_REPL$Time_sec))
new_stepdataREPL1 <- new_stepdataREST[rep(1,100),] 
new_stepdataREPL1$prey.c <- seq(min(peckstepmod_REPL$prey.c), max(peckstepmod_REPL$prey.c), length.out=100)
new_stepdataREPL1$Variable <- 'Standardised Prey Density'
new_stepdataREPL1$x <- new_stepdataREPL1$prey.c
new_stepdataREPL <- new_stepdataREPL1

ilink_REPLstep <- family(glmmstep_REPL.preyC)$linkinv

pred_REPLstep <- predict(glmmstep_REPL.preyC, new_stepdataREPL, type = "link", se.fit = TRUE, re.form=~0)
pred_REPLstep <- cbind(pred_REPLstep, new_stepdataREPL)

pred_REPLstep <- transform(pred_REPLstep, lwr_ci = ilink_REPLstep(fit - (1.96* se.fit)),
                  upr_ci = ilink_REPLstep(fit + (1.96 * se.fit)),
                  fitted = ilink_REPLstep(fit))

predicted_REPLstep <- ggplot(pred_REPLstep, aes(x, fitted)) + 
  geom_ribbon(aes(ymin=lwr_ci, ymax=upr_ci), fill='blue', alpha=0.2, ) +
  geom_line(colour='blue', size=1) + 
  scale_y_continuous() +
  ggtitle("B") +
  xlab('Standardised Prey Density') +
  ylab('Estimated Red-capped Plover step rate') + theme_bw() +
  theme(strip.placement='outside',strip.background = element_blank())

predicted_REPLstep

ggsave("./03_plots/predicted_REPLstep.png", plot = predicted_REPLstep, width = 5, height = 5, dpi = 300)
