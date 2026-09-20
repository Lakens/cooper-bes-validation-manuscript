#set plot themes
source("Code/1_set_themes.R")

#detach psych package if loaded (conflict)
detach("package:psych", unload=TRUE) 

#load data
data <- read.csv("Data/scaled_data.csv")
data_all <- read.csv("Data/scaled_data&explanatory_vars.csv")

#principal component
results <- prcomp(data[,-1], scale = TRUE)
rotation <- as.data.frame(results$rotation)
biplot(results)
summary(results)
pca_results <- as.data.frame(cbind(data %>% select(ID), results$x))
scores <- results$rotation

#combine with explanatory vars
final <- inner_join(pca_results, data_all)
str(final)

#prepare dataframe for plot (combine all vars)
final$age <- as.factor(final$age)
age_size <- data.frame(age = levels(final$age), age_size = c(1,2,3,4,5,6))
final <- inner_join(final, age_size)
final$natcon <- as.factor(final$natcon)
natcon <- data.frame(natcon = levels(final$natcon), natcon_lab = c("Natural", "Constructed"))
final <- inner_join(final, natcon)

#summary stats
final %>% group_by(sex) %>% summarise(count = n(),
                                      percent = count/154)
final %>% group_by(age) %>% summarise(count = n(),
                                      percent = count/154)
final %>% group_by(natcon) %>% summarise(count = n(),
                                      percent = count/154)

#add labels
rotation$label <- c("Strength of encounter", 
                    "PA (personal)", 
                    "PA (social)", 
                    "PA (care)", 
                    "Theme: coastal places as nexuses of community identity",
                    "Theme: personal fulfillment from coastal visits",
                    "Theme: Encounters with natural coastal environment",
                    "Theme: challenges and changes in coastal environments & how to tackle them")

#set colors
cols <- c("1" = "red", "2" =  "blue")

#make plot
#plot of axis 1 and 2
ae_plot <- ggplot(data = final, aes(x = PC1, y = PC2))+
  geom_mark_ellipse(aes(fill = natcon_lab), expand = unit(0.4, "mm"))+
  scale_fill_manual(values = c("darkgrey", "white"))+
  geom_point(aes(color = age_size, shape = sex),alpha = 0.5, size = 5)+
  scale_color_viridis(option = "H", breaks=c(1,2,3,4,5,6),labels=c("18-24", "25-34", "35-44", "45-54", "55-64", "65+" ),
                       limits=c(1,6))+
  scale_size(range = c(1,5))+
  geom_segment(data = rotation, arrow = arrow(length = unit(0.5, "cm")), aes(x =0, xend=PC1*5, y=0, yend = PC2*5))+
  geom_text_repel(data = rotation, aes(x =PC1*6, y= PC2*6, label = label), size =5)+
  ylim(-5, 5)+
  themes+
  labs(fill = "Most frequently visited place is...", shape="Gender", colour="Age")+
  xlab("Affective engagement PCA axis 1 (32% of variance)")+
  ylab("Affective engagement PCA axis 2 (22% of variance)")
ae_plot

#plot of axis 3 and 4
ae_plot2 <- ggplot(data = final, aes(x = PC3, y = PC4))+
  geom_mark_ellipse(aes(fill = natcon_lab), expand = unit(0.4, "mm"))+
  scale_fill_manual(values = c("darkgrey", "white"))+
  geom_point(aes(color = age_size, shape = sex),alpha = 0.5, size = 5)+
  scale_color_viridis(option = "H", breaks=c(1,2,3,4,5,6),labels=c("18-24", "25-34", "35-44", "45-54", "55-64", "65+" ),
                      limits=c(1,6))+
  scale_size(range = c(1,5))+
  geom_segment(data = rotation, arrow = arrow(length = unit(0.5, "cm")), aes(x =0, xend=PC3*5, y=0, yend = PC4*5))+
  geom_text_repel(data = rotation, aes(x =PC3*6, y= PC4*6, label = label), size =5)+
  ylim(-5, 5)+
  themes+
  labs(fill = "Most frequently visited place is...", shape="Gender", colour="Age")+
  xlab("Affective engagement PCA axis 1 (32% of variance)")+
  ylab("Affective engagement PCA axis 2 (22% of variance)")
ae_plot2


#now run models
#permanova
perm_post <- adonis2(data_all[,c(2:9)] ~ age + sex + natcon, data_all, distance = "euclidean", permutations = 1000)


#supplementary exploration
perm_post1 <- adonis2(data_all[,c(2:9)] ~ sex, data_all, distance = "euclidean", permutations = 999)
perm_post1 
perm_post2 <- adonis2(data_all[,c(2:9)] ~ age , data_all, distance = "euclidean", permutations = 999)
perm_post2 
perm_post3 <- adonis2(data_all[,c(2:9)] ~ natcon, data_all, distance = "euclidean", permutations = 999)
perm_post3 


#brms - confirm permanova
m_pc1= brm(PC1 ~ natcon + age + sex,
                  data = final, family = gaussian(link = "identity"), 
                  iter = 5000, warmup = 1000,chains =2)


m_pc2= brm(PC2 ~ natcon + age + sex,
           data = final, family = gaussian(link = "identity"), 
          iter = 5000, warmup = 1000,chains =2)

#no divergent chains
#check models
plot(m_pc1)
summary(m_pc1)
conditional_effects(m_pc1)
plot(m_pc2)
conditional_effects(m_pc2)
summary(m_pc2)
#no effect


#create supplementary table
tab_model(m_pc1)
tab_model(m_pc2)







