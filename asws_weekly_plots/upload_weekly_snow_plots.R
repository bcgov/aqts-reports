###############################################################################
#DESCRIPTION: This function uploads graphs made by "weeklySnowReport.R". The graphs
#are saved in /graphs/ as pdf files and are uploaded one by one. The code takes
#about 5 minutes to upload all the graphs.
#
#By: Jeremy Krogh Feb 4, 2021
#Nov 22 2023 added catch for new Crocker Creek station
###############################################################################

upload_weely_snow_plots <- function() {
  
  rm(list = ls())
  source("./AI_R/timeseries_client.R")
  
  #password <- 'test'
  password <- 'test'
  #password <- 'test'
  username <- 'test'
  #username <- "test"
  
  #url <- 'https://bcmoe-test.aquaticinformatics.net/AQUARIUS'
  url <- 'https://bcmoe-prod.aquaticinformatics.net/AQUARIUS/'
  
  timeseries$connect(url, username, password)
  
  #get the list of files to upload
  filesToUpload <- list.files("./graphs/")
  
  #length(filesToUpload)
  
  for (i in seq(1,length(filesToUpload))) {
    print(paste0("Uploading File: ", filesToUpload[i]))
    filePath <- paste0("./graphs/", filesToUpload[i])
    
    stnNumber <- substring(filePath, 22)
    stnNumber <- unlist(str_split(stnNumber, "\\.")[[1]][1])
    
    #add catch for Crocker Creek
    if (stnNumber == 'Crock') {stnNumber = "CrockerCreek"}
    
    #title <- paste0(substr(filePath, 17, 20),"_MSS_Report")
    timeseries$uploadExternalReport(stnNumber, filePath, paste0("Snow.", stnNumber, ".Weekly Report"), TRUE)
  }
  
  timeseries$disconnect()
}