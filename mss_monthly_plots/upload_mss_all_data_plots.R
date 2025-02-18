###############################################################################
#DESCRIPTION: This function uploads graphs made by "mss_graphs.R". The graphs
#are saved in /graphs4Upload as pdf files and are uploaded one by one. The code takes
#about 5 minutes to upload all the graphs.
#
#By: Jeremy Krogh Dec 16, 2020
###############################################################################

upload_mss_all_data_plots <- function() {
  
  rm(list = ls())
  source("./R/timeseries_client.R")
  
  #password <- 'test'
  password <- 'test'
  #password <- 'test'
  username <- 'test'
  #username <- "test"
  
  #url <- 'https://bcmoe-test.aquaticinformatics.net/AQUARIUS'
  url <- 'https://bcmoe-prod.aquaticinformatics.net/AQUARIUS/'
  
  timeseries$connect(url, username, password)
  
  #get the list of files to upload
  filesToUpload <- list.files("./Graphs4Upload/")
  
  #length(filesToUpload)
  
  for (i in seq(1,length(filesToUpload))) {
    print(paste0("Uploading File: ", filesToUpload[i]))
    filePath <- paste0("./Graphs4Upload/", filesToUpload[i])
    
    if (nchar(filePath) == 24) { stnNumber <- substr(filePath, 17, 20) }
    if (nchar(filePath) == 25) { stnNumber <- substr(filePath, 17, 21) }
    #title <- paste0(substr(filePath, 17, 20),"_MSS_Report")
    
    print("start upload")
    timeseries$uploadExternalReport(stnNumber, filePath, paste0("SnowMSS.", stnNumber, ".MSS Report"), TRUE)
    print("finish upload")
  }
  
  timeseries$disconnect()
}
