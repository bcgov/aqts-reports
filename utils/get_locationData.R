#Function used to get location metadata information from AQTS


library(jsonlite)
library(httr)

get_locationData <- function(mss_id, base_url, username, password) {
  
  session_url <- paste0(base_url, '/AQUARIUS/Publish/v2/session')
  credentials <- list(Username = username, EncryptedPassword = password)
  
  #start session
  session <- POST(session_url, body = credentials, encode='json')
  
  
  response <- GET(paste0(base_url, "/AQUARIUS/Publish/v2/GetLocationData?LocationIdentifier=", mss_id), 
                  body = list(), 
                  encode='json')
  
  locationData <- fromJSON(rawToChar(response$content))
  
  #end session
  DELETE(session_url)
  
  return(locationData)
  
}
