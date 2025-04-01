###############################################################################
#DESCRIPTION: This function uploads graphs from the asws, mss and pgown networks
#
#By: Jeremy K Feb 18, 2025
#Updated April 1, 2025 by Carmen R
###############################################################################

library(stringr)
library(jsonlite)
library(httr)
library(dplyr)

upload_graphs <- function(url, username, password, path_to_graphs, type) {

  #load the function for connecting to AQTS
  #source("./utils/timeseries_client.R")

  #connect to AQTS with provided username and password
  #timeseries$connect(url, username, password)

  
  base_url = 'https://bcmoe-prod.aquaticinformatics.net:443'
  session_url <- paste0(base_url, '/AQUARIUS/Publish/v2/session')
  loc_url <- paste0(base_url, '/AQUARIUS/Publish/v2/GetLocationDescriptionList')
  credentials <- list(Username = username, EncryptedPassword = password)
  session <- POST(session_url, body = credentials, encode='json')
  print(session)
  #loc_url <- paste0(url, 'Publish/v2/GetLocationDescriptionList')
  #get the list of files to upload
  filesToUpload <- list.files(path_to_graphs)
  
  loc_response <- GET(loc_url)
  df_loc <- fromJSON(content(loc_response, as='text'))$LocationDescriptions
  df_loc <- df_loc[c("Identifier", "UniqueId")]
  #Print how many files have been identified for upload to AQTS
  print(paste("Total files to upload:", length(filesToUpload)))

  #loop through all the files and upload one by one
  for (i in seq(1,length(filesToUpload))) {
    print(paste0("Uploading File: ", filesToUpload[i]))
    filePath <- paste0(path_to_graphs, filesToUpload[i])
    
    #for uploading 7-day asws plots
    if (type == "asws") {
      #extract the station number from the file path
      stnNumber <- substring(filesToUpload[i], 13)
      stnNumber <- unlist(str_split(stnNumber, "\\.")[[1]][1])
      #upload the report to the database
      #timeseries$uploadExternalReport(stnNumber, filePath, paste0("Snow.", stnNumber, ".Weekly Report"), TRUE)
	  UniqueId <- filter(df_loc, Identifier == stnNumber)$UniqueId[1]
	  upload_url <- paste0(base_url, "/AQUARIUS/Acquisition/v2/locations/", UniqueId, "/attachments/reports")
	  loc_info <- list(uploadedFile = upload_file(filePath), Title = paste0("Snow.", stnNumber, ".Weekly Report"))
	  POST(upload_url, body=loc_info)
      
    }
    
    #for uploading mss plots
    if (type == "mss") {
      
      stnNumber <- substring(filesToUpload[i], 1)
      stnNumber <- unlist(str_split(stnNumber, "\\.")[[1]][1])
      
      #upload the report to the database
      #timeseries$uploadExternalReport(stnNumber, filePath, paste0("SnowMSS.", stnNumber, ".MSS Report"), TRUE)
	  UniqueId <- filter(df_loc, Identifier == stnNumber)$UniqueId[1]
	  upload_url <- paste0(base_url, "/AQUARIUS/Acquisition/v2/locations/", UniqueId, "/attachments/reports")
	  loc_info <- list(uploadedFile = upload_file(filePath), Title = paste0("SnowMSS.", stnNumber, ".MSS Report"))
	  POST(upload_url, body=loc_info)
      
    }
    
    #for uploading pgown graph all data reports
    if (type == "groundwater") {
      
      stnNumber <- substring(filesToUpload[i], 1)
      stnNumber <- unlist(str_split(stnNumber, "\\.")[[1]][1])
      
      #upload the report to the database
      #timeseries$uploadExternalReport(stnNumber, filePath, paste0("Groundwater.", stnNumber, ".GWGraphAllData"), TRUE)
	  UniqueId <- filter(df_loc, Identifier == stnNumber)$UniqueId[1]
	  upload_url <- paste0(base_url, "/AQUARIUS/Acquisition/v2/locations/", UniqueId, "/attachments/reports")
	  loc_info <- list(uploadedFile = upload_file(filePath), Title = paste0("Groundwater.", stnNumber, ".GWGraphAllData"))
	  POST(upload_url, body=loc_info)
      
    }
  }
  
  #end session to database
  DELETE(session_url)
}