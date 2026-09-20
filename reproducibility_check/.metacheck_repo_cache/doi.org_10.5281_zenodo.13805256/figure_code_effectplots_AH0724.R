#### FIGURES / Anna Haukka 17.7.2024----

# colors rural = "#FFCC66", urban = "#CC3300")

library(sjPlot)
library(ggplot2)
library(cowplot)

## PLOTS for amount of food over time as in models----
# colors rural = "#FFCC66", urban = "#CC3300"

#sunflower seeds rural vs urban
graph.sunf <- plot_model(msunf, type = "pred", 
                         terms = c("YearC","Habitat"),
                         axis.title = c("Year",
                                        "Kg / feeder"),
                         title = "Sunflower seeds",
                         show.legend = FALSE,
                         dot.size = 1.0,
                         jitter = 0.02,
                         colors = c("#FFCC66", "#CC3300"))

graph.sunf <- graph.sunf + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.x = element_blank())

graph.sunf

# nuts rural vs urban
graph.nuts <- plot_model(mnuts, type = "pred", 
                         terms = c("YearC","Habitat"),
                         axis.title = c("Year",
                                        "Kg / feeder"),
                         legend.title = "Habitat",
                         title = "Nuts",
                         show.legend = FALSE,
                         dot.size = 1.0,
                         jitter = 0.02,
                         colors = c("#FFCC66", "#CC3300"))

graph.nuts <- graph.nuts + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())

graph.nuts

# nuts rural vs urban
graph.cer <- plot_model(mcereal, type = "pred", 
                        terms = c("YearC","Habitat"),
                        axis.title = c("Year",
                                       "Kg / feeder"),
                        legend.title = "Habitat",
                        title = "Cereal",
                        show.legend = FALSE,
                        dot.size = 1.0,
                        jitter = 0.02,
                        colors = c("#FFCC66", "#CC3300"))

graph.cer <- graph.cer + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24))

graph.cer

# fat rural vs urban
graph.fat <- plot_model(mfat, type = "pred", 
                        terms = c("YearC","Habitat"),
                        axis.title = c("Year",
                                       "Kg / feeder"),
                        legend.title = "Habitat",
                        title = "Fat",
                        show.legend = FALSE,
                        dot.size = 1.0,
                        jitter = 0.02,
                        colors = c("#FFCC66", "#CC3300"))

graph.fat <- graph.fat + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.y = element_blank())

graph.fat

# join plots into one layout
plot_grid(graph.sunf, graph.nuts, 
          graph.cer, graph.fat, 
          labels = c('A','B','C','D'),
          label_size = 22,
          ncol = 2,
          align = "v")

# labels for rural and urban areas were added in an image editing software

## PLOT for number of bird feeding sites over time as in model----

graph.feeders <- plot_model(m4, type = "pred", 
                            terms = c("year2st[all]","Habitat"),
                            axis.title = c("Year",
                                           "Feeding sites / 10 km"),
                            legend.title = "Habitat",
                            title = "",
                            show.legend = FALSE,
                            dot.size = 1.0,
                            jitter = 0.02,
                            colors = c("#CC3300", "#FFCC66"))

graph.feeders <- graph.feeders + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24))

graph.feeders

# labels for rural and urban areas were added in an image editing software

#### END / Anna 17.7.2024