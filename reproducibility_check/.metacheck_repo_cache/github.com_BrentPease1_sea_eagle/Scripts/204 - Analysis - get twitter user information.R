library(academictwitteR)
library(here)
library(tidyverse)

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #

if(!(dir.exists(here("Data/twitter/test3")))){
  
  twitter <-   get_all_tweets(
    query = c("Steller's Sea Eagle", "stellers sea eagle", "#StellersSeaEagle"),
    start_tweets = "2021-12-01T00:00:00Z",
    end_tweets = "2022-01-31T00:00:00Z",
    n = 10000,
    bind_tweets = FALSE,
    file = here("Data/twitter/test"),
    data_path = here("Data/twitter/test3"),
    is_retweet = F,
    is_reply = F,
    is_quote = F
    # bbox = c(-72.476807,41.087632,-66.511230,45.537137)
  )
} else{
  twitter <- bind_tweets(data_path = here("Data/twitter/test3"), user = TRUE, output_format = 'tidy')
  
}




# 1. create a monk vector
these <- c("we", "chase", "chased", "saw", "seeing", "see", "finding", "find",
           'drive', 'travel*')

# 2. create a `|` separate pattern of your vector as Tim Biegleisen already did
pattern_search<- paste(these, collapse = "|")

# Now 

# grepl returns a logical vector TRUE/FALSE
twit_table <- table(grepl(pattern_search, twitter$text))

