library(opencage)
library(gmapsdistance)
library(zipcodeR)

set.api.key("AIzaSyAIpwnAajCTDB4y0r-NjF7Uew3pD-dFLww")
download_zip_data(force = T)

# respondent 13289536431
multiple_trips <- data.frame(respondent_ID = rep(13289536431, 3),
                             location_attempt = c('02715', '02725', '04548'),
                             home_zip = rep('01510', 3),
                             attempt_lat = NA,
                             attempt_lng = NA,
                             home_lat = NA,
                             home_lng = NA,
                             travel_time_sec = NA,
                             travel_dist_meter = NA)

for(i in 1:nrow(multiple_trips)){
  tmp_attempt <- geocode_zip(multiple_trips[i, 'location_attempt'])
  tmp_home <- geocode_zip(multiple_trips[i, 'home_zip'])
  
  multiple_trips$attempt_lat[i] <- tmp_attempt$lat
  multiple_trips$attempt_lng[i] <- tmp_attempt$lng
  multiple_trips$home_lat[i] <- tmp_home$lat
  multiple_trips$home_lng[i] <- tmp_home$lng
  
  gdis <- gmapsdistance(origin = paste0(multiple_trips$home_lat[i], "+", multiple_trips$home_lng[i]),
                        destination = paste0(multiple_trips$attempt_lat[i], "+", multiple_trips$attempt_lng[i]),
                        mode = 'driving')
  
  multiple_trips$travel_time_sec[i] <- gdis$Time
  multiple_trips$travel_dist_meter[i] <- gdis$Distance
  
}


multiple_trips$prop_dist <- multiple_trips$travel_dist_meter/sum(multiple_trips$travel_dist_meter)


# respondent 13296096851          
multiple_trips <- data.frame(respondent_ID = rep(13296096851, 2),
                             location_attempt = c('Georgetown, Maine, USA', 'Taunton, Massachusetts, USA'),
                             home_zip = rep('01940', 2),
                             attempt_lat = NA,
                             attempt_lng = NA,
                             home_lat = NA,
                             home_lng = NA,
                             travel_time_sec = NA,
                             travel_dist_meter = NA)

for(i in 1:nrow(multiple_trips)){
  
  open <- oc_forward(placename = multiple_trips$location_attempt[i],
                     countrycode = 'us')
  open <- open[[1]][which(open[[1]]$oc_confidence == min(open[[1]]$oc_confidence)),]
  
  #tmp_attempt <- geocode_zip(open$oc_postcode)
  tmp_home <- geocode_zip(multiple_trips[i, 'home_zip'])
  
  multiple_trips$attempt_lat[i] <- open$oc_lat
  multiple_trips$attempt_lng[i] <- open$oc_lng
  multiple_trips$home_lat[i] <- tmp_home$lat
  multiple_trips$home_lng[i] <- tmp_home$lng
  
  gdis <- gmapsdistance(origin = paste0(multiple_trips$home_lat[i], "+", multiple_trips$home_lng[i]),
                        destination = paste0(multiple_trips$attempt_lat[i], "+", multiple_trips$attempt_lng[i]),
                        mode = 'driving')
  
  multiple_trips$travel_time_sec[i] <- gdis$Time
  multiple_trips$travel_dist_meter[i] <- gdis$Distance
  
}

multiple_trips$prop_dist <- multiple_trips$travel_dist_meter/sum(multiple_trips$travel_dist_meter)
