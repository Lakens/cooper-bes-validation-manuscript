# Define a list of packages
packages <- c("tidyverse", "scales", 
              "ggplot2", "brms", 
              "vegan", "sjPlot", 
              "ggrepel", "concaveman", 
              "ggforce", "viridis")

# Install and load packages if they are not already installed
for (package in packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)}
  library(package, character.only = TRUE)}

#set theme for ggplot
themes <-  theme(panel.border = element_blank(),
                 panel.grid.major = element_blank(),
                 panel.grid.minor = element_blank(),
                 panel.background = element_blank(),
                 axis.line = element_line(size = 0.5, linetype = "solid",
                                          colour = "black"),
                 axis.text= element_text(size=20),
                 axis.title = element_text(size =20),
                 legend.text=element_text(size=10))

