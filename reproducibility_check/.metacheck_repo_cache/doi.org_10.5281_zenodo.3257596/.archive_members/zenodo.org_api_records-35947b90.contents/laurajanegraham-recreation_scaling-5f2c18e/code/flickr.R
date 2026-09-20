# adapted code from https://github.com/FrancescaMancini/FlickrAPI_EABhackathon Currently
# loops over 10 day chunks because the month chunks still hit the 4000 photos limit. Also
# have switched from searching by text to searching by tags
photo_by_tag <-
  function(year_range,
           tags,          
           bbox = NULL,
           woe_id =NULL,
           has_geo = TRUE){
    
    library(httr)
    library(XML)
    library(RCurl)
    
    load("flickr_api_key.Rda") # NB this will need to exist for the code to work
    
    if( !(is.null(bbox) | is.null(woe_id))==TRUE) {
      stop('can not provide bbox and woe_id')
    }
    
    tags <- gsub(' ', '+', trimws(tags)) 
    tags <- paste(tags, collapse=",")
    extras <- "date_taken,geo,tags,license,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o"
    baseURL <- paste("https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=",api_key,sep="")   #set base URL
    pics<-NULL
    
    start_date <- as.Date(paste0(min(year_range), "/01/01"))
    end_date <- as.Date(paste0(max(year_range) + 1, "/01/01")) - 1
    
    date_range <- seq(from = start_date, to = end_date, by = 15)
    
    pb <- txtProgressBar(min = 0, max = length(date_range) - 1, style = 3)
    
    
    for (d in 1:(length(date_range) - 1)) {                     
      
      
      mindate <- date_range[d]
      maxdate <- date_range[d + 1]
      
      if(!is.null(bbox)){
        getPhotos <- paste(baseURL,
                           "&tags=", tags,
                           "&min_taken_date=", as.character(mindate),
                           "&max_taken_date=", as.character(maxdate),
                           "&bbox=", paste0(bbox[1],",",bbox[2],",",bbox[3],",",bbox[4]),
                           "&extras=", extras,
                           sep = "")
      } else if(!is.null(woe_id)){
        getPhotos <- paste(baseURL,
                           "&tags=", tags,
                           "&min_taken_date=", as.character(mindate),
                           "&max_taken_date=", as.character(maxdate),
                           "&woe_id=", woe_id,
                           "&extras=", extras,
                           sep = "")     
      } else {
        getPhotos <- paste(baseURL,
                           "&tags=", tags,
                           "&min_taken_date=", as.character(mindate),
                           "&max_taken_date=", as.character(maxdate),
                           ifelse(has_geo, paste0("&has_geo=", has_geo), ''),
                           "&extras=", extras,
                           sep = "")
      }
      
      r <- GET(getPhotos)
      
      count_stat <- 0
      
      while(r$status_code != 200 & count_stat < 3){
        Sys.sleep(0.5)
        r <- GET(getPhotos)
        count_stat <-  count_stat + 1
      }
      
      if(r$status_code != 200){
        warning('Status code:', r$status, ' for year ', y, ' month ', m, ' - message: ', content(r, 'text'))
      }
      
      error <- tryCatch({
        getPhotos_data <- xmlRoot(xmlTreeParse(content(r, 'text')))
        error <- 'success'
      }, error = function(err){
        warning('Year ', y, ' month ', m, ' skipped beacuse: ', err)
        error <- 'error'
      })    
      
      if(error != 'error'){
        
        #results are returned in different pages so it is necessary to loop through pages to collect all the data
        #parse the total number of pages
        pages_data <- data.frame(xmlAttrs(getPhotos_data[["photos"]]))
        pages_data[] <- lapply(pages_data, FUN = function(x) as.integer(as.character(x)))
        total_pages <- pages_data["pages",]
        total <- pages_data["total",]
        
        if(total > 4000) warning("Total number of records greater than limit of 4000, try refining search criteria")
        
        if(total > 0){
          
          pics_tmp <- NULL
          
          # loop thru pages of photos and save the list in a DF
          for(i in c(1:total_pages)){
            
            if(!is.null(bbox)){ 
              
              getPhotos <- paste(baseURL
                                 ,"&tags=",tags,"&min_taken_date=",mindate,
                                 "&max_taken_date=",maxdate,
                                 "&bbox=", paste0(bbox[1],",",bbox[2],",",bbox[3],",",bbox[4]),
                                 "&extras=",extras,"&page="
                                 ,i,sep="")
              
            } else if(!is.null(woe_id)){
              
              getPhotos <- paste(baseURL
                                 ,"&tags=",tags,"&min_taken_date=",mindate,
                                 "&max_taken_date=",maxdate,
                                 "&woe_id=",woe_id,
                                 "&extras=",extras,
                                 "&page=",i,sep="")
              
            } else {
              
              getPhotos <- paste(baseURL
                                 ,"&tags=",tags,"&min_taken_date=",mindate,
                                 "&max_taken_date=",maxdate,
                                 ifelse(has_geo, paste0("&has_geo=", has_geo), ''),
                                 "&extras=",extras,format,"&page="
                                 ,i,sep="")        
              
            }
            
            r <- GET(getPhotos)
            
            count_stat <- 0
            
            while(r$status_code != 200 & count_stat < 3){
              Sys.sleep(0.5)
              r <- GET(getPhotos)
              count_stat <-  count_stat + 1
            }
            
            if(r$status_code != 200){
              warning('Status code:', r$status, ' for year ', y, ' month ', m, ' page ', i, ' - message: ', content(r, 'text'))
            }
            
            error <- tryCatch({
              getPhotos_data <- xmlRoot(xmlTreeParse(content(r, 'text'), useInternalNodes = TRUE))
              error <- 'sucess'
            }, error = function(err){
              warning('Year ', y, ' month ', m, ' page ', i,' skipped beacuse: ', err)
              error <- 'error'
            })
            
            if(error != 'error'){
              getPhotos_data <<- getPhotos_data
              id <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "id"))                 #extract photo id
              owner <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "owner"))           #extract user id
              datetaken <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "datetaken"))   #extract date picture was taken
              photo_tags <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "tags"))             #extract tags
              latitude <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "latitude"))     #extract latitude
              longitude <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "longitude"))   #extract longitude
              accuracy <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "accuracy"))     #extract accuracy
              license <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "license"))       #extract license
              url_s <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "url_s"))           #extract url_s
              url_m <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "url_m"))           #extract url_m
              url_l <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "url_l"))           #extract url_l
              url_o <- listNulltoNA(xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "url_o"))           #extract url_o
              
              if(!all(is.na(c(id,owner,datetaken,tags,latitude,longitude,license,url_s,url_m,url_l,url_o)))){
                
                tmp_df <- data.frame(id, owner, datetaken, photo_tags, accuracy,
                                     latitude = as.numeric(latitude),
                                     longitude = as.numeric(longitude), license,
                                     url_s = unlist(url_s), url_m = unlist(url_m),
                                     url_l = unlist(url_l), url_o = unlist(url_o),
                                     stringsAsFactors = FALSE)
                
                tmp_df$page <- i
                pics_tmp <- rbind(pics_tmp, tmp_df)
                rm(list = 'tmp_df')
                
              }
            }
          }
          
          pics <- rbind(pics, pics_tmp)
          
        }
        
        
      }
      
      setTxtProgressBar(pb, d)
      
    }
    
    
    
    close(pb)
    return(pics)
    
  }

listNulltoNA <- function(x){
  if(length(x) == 0){
    return(NA)
  } else {
    x[sapply(x, is.null)] <- NA
    return(x)
  }
}
