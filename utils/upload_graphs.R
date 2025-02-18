###############################################################################
#DESCRIPTION: This function uploads graphs from the asws and mss networks
#
#By: Jeremy Krogh Feb 18, 2025
###############################################################################

upload_graphs <- function(url, username, password, path_to_graphs, type) {
  
  #load the function for connecting to AQTS
  source("./utils/timeseries_client.R")

  #connect to AQTS with provided username and password
  timeseries$connect(url, username, password)
  
  #get the list of files to upload
  filesToUpload <- list.files(path_to_graphs)
  
  #Print how many files have been identified for upload to AQTS
  print(paste("Total files to uplad:", length(filesToUpload)))
  
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
      timeseries$uploadExternalReport(stnNumber, filePath, paste0("Snow.", stnNumber, ".Weekly Report"), TRUE)
    }
    
    #for uploading mss plots
    if (type == "mss") {
      
      stnNumber <- substring(filesToUpload[i], 1)
      stnNumber <- unlist(str_split(stnNumber, "\\.")[[1]][1])
      
      #upload the report to the database
      timeseries$uploadExternalReport(stnNumber, filePath, paste0("Snow.", stnNumber, ".MSS Report"), TRUE)
      
    }
    
  }
  
  #end session to database
  timeseries$disconnect()
}