########################
### "lollipop chart" ### 
########################

library(unmarked)
library(readxl)
library(writexl)
library(tidyverse)
library(ggplot2)
library(ggthemes)
library(RColorBrewer)
library(raster)
library(rgdal)

# data 
d <- read_xlsx("d_covariate_freq.xlsx")
head(d)
str(d)
d$resolution <- as.factor(d$resolution)
d$group <- as.factor(d$group)
d$Covariat <- factor(d$Covariat, levels = d$Covariat[order(d$value)])

ggplot(d,aes(x=Covariat,y=freq,color = resolution,group=resolution))+
  geom_segment(aes(x=Covariat, xend=Covariat, y=0, yend=freq))+
  geom_point(size=2) +
  xlab("")+
  ylab("")+
  theme_bw()+
  theme(text = element_text(size = 14,face = "bold"))+
  theme(panel.grid.major.x = element_blank(),panel.border = element_blank(),
        axis.ticks.x = element_blank(),panel.grid.minor.y = element_blank())+
  coord_flip()

  

ggsave("frequency.png", width =26 , height = 24, units = "cm")




