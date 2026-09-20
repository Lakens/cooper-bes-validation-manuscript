source("header.R")

sbf_set_sub("clean")
sbf_load_datas()

data <- inner_join(event, encounter, by = "HuntingEventNumber")

sbf_set_sub("deer")

data %<>% 
    mutate(Year = dtt_year(DateTimeEncounter))

gp<- ggplot(filter(data, Year == 2017), aes(DateTimeEncounter)) +
    geom_histogram(aes(fill=Method), binwidth=1*3600*24*7)+
    scale_x_datetime("2017 Operations", breaks=date_breaks("1 month"), labels = date_format("%b")) +
    ylab("Deer Killed") +
    labs(fill="Hunting Method") +
    NULL

sbf_open_window()
sbf_print(gp)

sbf_save_plot(x_name='huntingtypethrutime2017', caption="Plot of number of deer killed by hunting method through time for 2017 operations.", report = FALSE)

gp<- ggplot(filter(data, Year == 2017), aes(DateTimeEncounter)) +
    facet_wrap(~IslandHaida) +
    geom_histogram(aes(fill=Method), binwidth=1*3600*24*7)+
    scale_x_datetime("2017 Operations", 
                     breaks=date_breaks("1 month"), labels = date_format("%b")) +
    ylab("Deer Killed") +
    labs(fill="Hunting Method") +
    theme (legend.position = "bottom") +
    NULL

sbf_open_window()
sbf_print(gp)

sbf_save_plot(x_name='huntypetimebyisl2017', caption="Plot of number of deer killed by hunting method through time by island for 2017 operations.", report = FALSE)

gp<- ggplot(filter(data, Year == 2018), aes(DateTimeEncounter)) +
    facet_wrap(~IslandHaida) +
    geom_histogram(aes(fill=Method), binwidth=1*3600*24*3) +
    scale_x_datetime("2018 Operations", breaks=date_breaks("1 week"), labels = date_format("%b-%d")) +
    ylab("Deer Killed") + 
    labs(fill="Hunting Method") +
    NULL

sbf_open_window()
sbf_print(gp)

sbf_save_plot(x_name='huntingtypetimebyis2018', caption="Plot of number of deer killed by hunting method through time for 2018 operations.", report = FALSE)

# gp<- ggplot(data, aes(Method))+
#   geom_bar(aes(fill=Status))
# sbf_open_window()
# sbf_print(gp)
# sbf_save_plot(x_name='agethrutime', caption="Plot of age of deer through time during operations.")

#scatterplot to determine which effort metric to use (are they predictive on the 1:1 line and what is the bias)
# gp<-ggplot (data=event, aes(Hours,TrackTime, colour=Method))+
#   geom_point()
# sbf_open_window()
# sbf_print(gp)

#sex ratio by age for deer that were sexed which is most (%?)
# gp <- ggplot(data, aes(Age)) + 
#   geom_bar(aes(fill = Sex))+  NULL
# sbf_open_window()
# sbf_print(gp)
# sbf_save_plot(x_name='sexage', caption="Count of animals grouped by age and sex.")

