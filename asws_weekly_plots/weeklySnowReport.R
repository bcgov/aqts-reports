###############################################################################
#DESCCRIPTION: This script takes data from the data catalouge and produces a 
#one page report with four plots for the last seven days. 
#
#BY: Jeremy K Jan 18, 2021 

#updated: Mar 14, 2022
#update: Nov 20, 2023 to add Crocker Creek error catch
#update: Nov 19, 2024 to remove Crocker Creek error catch as it's no longer needed
#Update: Feb 18, 2025 moved code to github and fixed some things up
###############################################################################

#set working directory if needed
#setwd("C:/AQUARIUS/WeeklySnowReports")

## Load libraries
library(ggplot2)
library(cowplot)
library(dplyr)
library(lubridate)
library(tidyr)
library(stringr)
source("./utils/timeseries_client.R")

#get the API username and password from your environment file
readRenviron(paste0(getwd(), "./.Renviron"))
username <- Sys.getenv("api_username")
password <- Sys.getenv("api_password")

#url end point for AQTS
url <- 'https://bcmoe-prod.aquaticinformatics.net/AQUARIUS/'

## Download the Current Year Snow Data
SW <- read.csv("http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/SW.csv", stringsAsFactors = F)
SD <- read.csv("http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/SD.csv", stringsAsFactors = F)
TA <- read.csv("http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/TA.csv", stringsAsFactors = F)
PC <- read.csv("http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/PC.csv", stringsAsFactors = F)

#Rename CrockerCreek.Crocker.Creek Nov-20-2023, commented out Nov 2024 as Crocker creek now has an ID
#SW <- rename(SW, 'X.CrockerCreek.Crocker.Creek' =  'CrockerCreek.Crocker.Creek')
#SD <- rename(SD, 'XCrockerCreek.Crocker.Creek' = 'CrockerCreek.Crocker.Creek')
#TA <- rename(TA, 'XCrockerCreek.Crocker.Creek' = 'CrockerCreek.Crocker.Creek')
#PC <- rename(PC, 'XCrockerCreek.Crocker.Creek' = 'CrockerCreek.Crocker.Creek')

## Clean up the data and merge into one data frame
SW <- pivot_longer(SW, cols = starts_with("X")) 
SW$Variable <- "Snow Water Equivalent (mm)"

SD <- pivot_longer(SD, cols = starts_with("X")) 
SD$Variable <- "Snow Depth (cm)"

TA <- pivot_longer(TA, cols = starts_with("X")) 
TA$Variable <- "Air Temperature (C)"

PC <- pivot_longer(PC, cols = starts_with("X")) 
PC$Variable <- "Cumulative Precipitation (mm)"

CurrentYrSnowData <- rbind(SW, SD, TA, PC)

## Fix the Date time
#CurrentYrSnowData$DATE.UTC. <- as.POSIXct(CurrentYrSnowData$DATE.UTC., 
#                                          format = "%Y-%m-%dT%H:%M:%S%z")
CurrentYrSnowData$DATE.UTC. <- as.POSIXct(CurrentYrSnowData$DATE.UTC., 
                                          format = "%Y-%m-%d %H:%M")
#CurrentYrSnowData$DATE.UTC. <- as.POSIXct(CurrentYrSnowData$DATE.UTC.)

#Date format changed 28/09/2021 from "%Y-%m-%d %H:%M" and back 26-10-2021 something changed again 2022-03-14

## Get the Station Name and Station Number
CurrentYrSnowData$StnNumber <- substring(unlist(lapply(strsplit(CurrentYrSnowData$name, "\\."), "[[", 1)),2)
CurrentYrSnowData$StnName <- substring(str_replace_all(CurrentYrSnowData$name, CurrentYrSnowData$StnNumber, ""),3)
CurrentYrSnowData$StnName <- gsub("\\.", " ", CurrentYrSnowData$StnName)
#CurrentYrSnowData$StnName <- trimws(CurrentYrSnowData$StnName, which = "left")

#Handle Crocker Creek
#ix<- CurrentYrSnowData$name == 'X.CrockerCreek.Crocker.Creek'
#CurrentYrSnowData$StnName[ix] = "Crocker Creek"
#CurrentYrSnowData$StnNumber[ix] = "CrockerCreek"

## Get Current Date
Today <- Sys.Date()
OneWeekAgo <- as.POSIXct(Today - 7)

## Extract only the data from the past 7 days
CurrentData <- CurrentYrSnowData %>% filter(DATE.UTC. > OneWeekAgo)

## Get list of stations for which we need to run a report
StationsToReportOn <- unique(CurrentData$name)

## Set the text size of "NO DATA" text that appears on plot where there is no data
NoDataTextSize = 4

## Connect to the database to get station location meta-data
timeseries$connect(url, username, password)

## Loop to generate a plot for each automated station
for (i in seq(1, length(StationsToReportOn))) {
  
  ## Extract data for one station
  OneStationData <- CurrentData %>% filter(name == StationsToReportOn[i])
  
  ## Extract the full station name with the station number in brackets
  FullStnName <- paste0(unique(OneStationData$StnName), " (", unique(OneStationData$StnNumber), ")")
  
  ## Get location data from the database
  locationData <- timeseries$getLocationData(unique(OneStationData$StnNumber))
  
  ## string for location lat long elev
  subtitlestr <- paste0(round(locationData$Latitude, 2), "N ", 
         round(locationData$Longitude, 2)*-1, "W ", 
         locationData$Elevation, "m") 
  
  ## Station responsibility
  responsibility = locationData$ExtendedAttributes$Value[locationData$ExtendedAttributes$Name == "RESPONSIBILITY_SNOW"]
  if(is.na(responsibility)) {responsibility = "BC Gov."}
  
  ## Print out the progress of the loop
  print(paste0("Printing Graph for: ", FullStnName))
  
  ## SWE Plot
  onePar <- OneStationData %>% 
    filter(Variable == "Snow Water Equivalent (mm)")
 
 ## Only make the plot if data is available
 if (nrow(onePar) > 0){
 SWplot <- ggplot(onePar, aes(x = DATE.UTC., y = value)) + 
    geom_point(size = 1, colour = "dodgerblue4") +
    geom_line(alpha = 0.5, size = 0.5) +
    labs(y = unique(onePar$Variable),
         x = "")+
    scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
    theme_bw()
 } else { ## If no data make a blank pane with the text "NO DATA"
    SWplot <- ggplot(data.frame(x=Sys.time() - hours(85),y=1,txt_msg="NO DATA"), aes(x, y, label = txt_msg)) + 
       geom_text(size = NoDataTextSize) +
       labs(y = "Snow Water Equivalent (mm)",
            x = "") +
       scale_y_continuous(labels = NULL) +
       scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
       theme_bw()
 }
 ## SD Plot
 onePar <- OneStationData %>% 
   filter(Variable == "Snow Depth (cm)")

 if (nrow(onePar) > 0){
 SDplot <- ggplot(onePar, aes(x = DATE.UTC., y = value)) + 
   geom_point(size = 1, colour = "dodgerblue4") +
   geom_line(alpha = 0.5, size = 0.5) +
   labs(y = unique(onePar$Variable),
        x = "")+
   scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
   theme_bw()
 
 } else {
    SDplot <- ggplot(data.frame(x=Sys.time() - hours(85),y=1,txt_msg="NO DATA"), aes(x, y, label = txt_msg)) + 
       geom_text(size = NoDataTextSize) +
       labs(y = "Snow Depth (cm)",
            x = "") +
       scale_y_continuous(labels = NULL) +
       scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
       theme_bw()
       #scale_x_date(limits = c(as.Date(OneWeekAgo), Today))
 }
 
 ## TA Plot
 onePar <- OneStationData %>% 
   filter(Variable == "Air Temperature (C)")

 if (nrow(onePar) > 0){
 
  TAplot <- ggplot(onePar, aes(x = DATE.UTC., y = value)) + 
   geom_point(size = 1, colour = "dodgerblue4") +
   geom_line(alpha = 0.5, size = 0.5) +
   labs(y = unique(onePar$Variable),
        x = "")+
     scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
   theme_bw()
  
  } else {
     TAplot <- ggplot(data.frame(x=Sys.time() - hours(85),y=1,txt_msg="NO DATA"), aes(x, y, label = txt_msg)) + 
        geom_text(size = NoDataTextSize) +
        labs(y = "Air Temperature (C)",
             x = "") +
        scale_y_continuous(labels = NULL) +
        scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
        theme_bw()
  }
 
 ## PC Plot
 onePar <- OneStationData %>% #Precipitation Gauge Total (mm)
   filter(Variable == "Cumulative Precipitation (mm)")

if (nrow(onePar)) {
 PCplot <- ggplot(onePar, aes(x = DATE.UTC., y = value)) + 
   geom_point(size = 1, colour = "dodgerblue4") +
   geom_line(alpha = 0.5, size = 0.5) +
   labs(y = unique(onePar$Variable),
        x = "")+
    scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
   theme_bw()
 } else {
    PCplot <- ggplot(data.frame(x=Sys.time() - hours(85),y=1,txt_msg="NO DATA"), aes(x, y, label = txt_msg)) + 
       geom_text(size = NoDataTextSize) +
       labs(y = "Cumulative Precipitation (mm)",
            x = "") +
       scale_y_continuous(labels = NULL) +
       scale_x_datetime(limits = c(OneWeekAgo, Sys.time() + hours(10))) +
       theme_bw()
 }
 
## Using Cowplot make a title for the report
 plotTitle <- ggdraw() + draw_label(
   FullStnName,
   fontface = 'bold',
   x = 0,
   hjust = 0) +
   theme(plot.margin = margin(0, 0, 0, 7))
 
 ## Make a sub-title for the plot, this is currently the date the report was made but could include other info
 plotSubTitle <- ggdraw() + draw_label(
   paste0(subtitlestr, " Report Generated: ", Today),
   fontface = 'plain',
   size = 12,
   x = 0,
   hjust = 0) +
   theme(plot.margin = margin(0, 0, 0, 7))
 
 ## Add disclaimer text to the bottom of the report
 plotDisclaimer <- ggdraw() + draw_label(
   label = "Disclaimer: This report was made by an automated system and has not gone through quality control checks and may be subject to large errors, it is presented as is with 
no guarantee of accuracy or completeness.
   
Not all sites have all sensors. 'NO DATA' indicates a sensor isn't installed at the site or has failed.",
   fontface = 'italic',
   color = "grey50",
   size = 10,
   x = 0,
   hjust = 0) +
   theme(plot.margin = margin(0,0,0,7))

 ## Merge the data plots into one grid
 plots <- plot_grid(SDplot, SWplot, TAplot, PCplot, align = "v")
 
 ## Add the title, subtitle, and disclaimer text
 finalPlot <- cowplot::plot_grid(plotTitle, plotSubTitle, plots, plotDisclaimer, nrow = 4, rel_heights = c(0.07, 0.05, 1, 0.07)) +
   theme(plot.margin = margin(0.15, 0.15, 0.15, 0.15, unit = "in"))
 
 ## Set the logo file based on the responsibility
 logoFile = NA
 if (grepl("BC Gov.", responsibility)) {logoFile = "./utils/logos/bcmark_pos.png"}
 if (grepl("BC Hydro", responsibility, ignore.case = T)) {logoFile = "./utils/logos/BC_Hydro_Logo.jpg"}
 if (grepl("Metro Vancouver", responsibility, ignore.case = T)) {logoFile = "./utils/logos/MV_Logo.png"}
 if (is.na(logoFile)) {logoFile = "./utils/logos/bcmark_pos.png"}
 
 ## Add the BC Gov logo
  finalPlot <- ggdraw(finalPlot) + draw_image(logoFile, scale = 0.15, x = 0.4, y = 0.44)
 
 ## Save the final output
 ggsave2(paste0("./asws_weekly_plots/graphs/weeklyReport", unique(OneStationData$StnNumber), ".pdf"), 
         finalPlot, width = 11, height = 8.5, units = "in", 
         title = paste0("7 Day Snow Report for ", unique(OneStationData$StnNumber)))
 
}

timeseries$disconnect()

#Upload the completed graphs to AQTS
source("./utils/upload_graphs.R")
upload_graphs(url, username, password, "./asws_weekly_plots/graphs/", "asws")




