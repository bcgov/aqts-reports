###############################################################################
#DESCCRIPTION: This script pulls data from the data cat, merges it with
#meta data from the web portal (via API) and produce box and whisker plots for 
#all MSS sites.
#
#BY: Jeremy K Update: March 14 2022
#Updated Feb 21 2025
###############################################################################

#Load libraries
library(cowplot)
library(dplyr)
library(knitr)
library(readr)
library(ggplot2)
library(lubridate)

#a copy of this function can be downloaded here
#https://github.com/AquaticInformatics/examples/blob/fa417675042ea1f1d08358f2c42244e7c4baac23/TimeSeries/PublicApis/R/timeseries_client.R
source("./utils/timeseries_client.R")

#get the API username and password from your environment file
readRenviron(paste0(getwd(), "./.Renviron"))
username <- Sys.getenv("api_username")
password <- Sys.getenv("api_password")

#url end point for AQTS
url <- 'https://bcmoe-prod.aquaticinformatics.net/AQUARIUS/'

## download the historic mss data
hist_mss <- read.csv('http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/allmss_archive.csv', stringsAsFactors = FALSE)
cur_yr <- read.csv('http://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/allmss_current.csv', stringsAsFactors = FALSE)

## convert the date strings to data type 'date'
hist_mss$Date.of.Survey <- as.Date(hist_mss$Date.of.Survey)
cur_yr$Date.of.Survey <- as.Date(cur_yr$Date.of.Survey)

## add a flag to show current year or not
hist_mss$cur_yr <- "N"

#if the current year file has at least one record
if (nrow(cur_yr) > 0) { 
  cur_yr$cur_yr <- "Y"
}

#bind the two datasets into one that contains all mss data
all_mss <- rbind(hist_mss, cur_yr)

## Connect to the database to get station location meta-data
timeseries$connect(url, username, password)

#make month labels
all_mss$month <- month(as.Date(all_mss$Survey.Period, format = "%d-%b"), label = TRUE)

#get a list of all the mss id numbers, use this to make a plot for ALL mss
#mss_id <- unique(all_mss$Number)

#get a list of the active mss sites, use this to make plots only for active stations
mss_id <- unique(all_mss$Number[all_mss$cur_yr == "Y"])

#loop through each id
for (i in c(1:length(mss_id))) {
  print(paste0("Making Plot For: ", mss_id[i]))
  
  ## Extract location meta data from database
  locationData <- timeseries$getLocationData(mss_id[i])
  responsibility = locationData$ExtendedAttributes$Value[locationData$ExtendedAttributes$Name == "RESPONSIBILITY_SNOW"]
  status <- if("Inactive" %in% locationData$Tags$Name){"Inactive"} else {"Active"}
  location <- paste0(round(locationData$Latitude, 2), "N ", 
                     round(-locationData$Longitude, 2), "W ",
                     locationData$Elevation, "m")
  
  ## Set the logo file default to BC Gov logo
  logoFile = NA
  if (grepl("BC Hydro", responsibility, ignore.case = T)) {logoFile = "./utils/logos/BC_Hydro_Logo.jpg"}
  if (grepl("BC Gov", responsibility, ignore.case = T)) {logoFile = "./utils/logos/bcmark_pos.png"}
  if (grepl("Metro Vancouver", responsibility, ignore.case = T)) {logoFile = "./utils/logos/MV_logo.png"}
  if (is.na(logoFile)) {logoFile = "./utils/logos/bcmark_pos.png"}
  
  one_stn_data <- all_mss %>% filter(Number == mss_id[i])
  cur_yr_one_stn <- one_stn_data %>% filter(cur_yr == 'Y')
  
  #make a data time range string
  data_range = paste0(year(min(one_stn_data$Date.of.Survey)), " - ", year(max(one_stn_data$Date.of.Survey)))
   
  if (nrow(cur_yr_one_stn) > 0) { #if station has current year data
  p1<-ggplot(one_stn_data, aes(month, Water.Equiv..mm, col = "gray")) +
    geom_boxplot() +
    geom_point(data = cur_yr_one_stn, aes(x = month, y = Water.Equiv..mm, col = "orange"), size = 2) +
    labs(title = paste(locationData$LocationName," (",mss_id[i],")", sep=""),
         subtitle = paste0(location, "
Status: ", status, ", Data Range: ", data_range, ", Most Recent Data: ", max(one_stn_data$Date.of.Survey)),
         x = "Month of Survey", 
         y = "Snow Water Equivalent (mm)", 
         color = "",
        caption = paste("Manual snow survey locations are sampled once per month during the snow season, generally between late December and June, 
although some sites are sampled less often. The dark blue dots are from the current snow season (Jan - June yearly) while the white bars 
represent historical data ranges from the station.
        
Full Explanation: The above box and whisker plot shows five statistics, the first and third quantile, the median, and two whiskers. The 
whiskers extend to the largest value or no further than 1.5 x IQR from the third quantile (where IQR is the inter-quartile range, or
distance between the first and third quartiles). The lower whisker extends from the first quantile to the smallest value or at most
1.5 x IQR. Data beyond the end of the whiskers are called `outlying` points and are plotted individually.
        
Disclaimer: This report was made by an automated system and has not gone through quality control checks and may be subject to 
large errors, it is presented as is with no guarantee of accuracy or completeness.

Plot Generated: ", Sys.Date())) +
    
    theme_bw()+
    #theme(plot.margin = margin(1.5, 0.5, 0.5, 0.5, unit = "cm")) +
    theme(plot.margin = margin(1.5, 0.5, 0.5, 0.5, unit = "cm"),
          plot.caption = element_text(hjust = 0, size = 7, face =  "italic", color = "grey50")) +
    scale_color_manual(labels = c("Historical", "Current Year"), values = c("gray", "dodgerblue4"))
 
  p2<- cowplot::ggdraw(p1) +
    cowplot::draw_image(logoFile, x=0.97, y=0.98, hjust = 1, vjust = 1, halign = 1, valign = 1, scale = 0.2)
  
  
  cowplot::ggsave2(paste0("./mss_monthly_plots/graphs/", unique(one_stn_data$Number), ".pdf"), 
                   p2, scale = 1, width=20, height=15, units="cm", dpi = 150, title = "MSS Snow Report")
  
  
  #If the current year data file has no data
  } else {
    p3<-ggplot(one_stn_data, aes(month, Water.Equiv..mm, col = "gray")) +
      geom_boxplot() +
      labs(title = paste(locationData$LocationName," (",mss_id[i],")", sep=""), 
           subtitle = paste0(location, "
Status: ", status, ", Data Range: ", data_range, ", Most Recent Data: ", max(one_stn_data$Date.of.Survey)),
           x = "Month of Survey", 
           y = "Snow Water Equivalent (mm)", 
           color = "",
           caption = paste("Manual snow survey locations are sampled once per month during the snow season, generally between late December and June, 
although some sites are sampled less often. The dark blue dots are from the current snow season (Jan - June yearly) while the white bars 
represent historical data ranges from the station.
           
Full Explanation: The above box and whisker plot shows five statistics, the first and third quantile, the median, and two whiskers. The 
whiskers extend to the largest value or no further than 1.5 x IQR from the third quantile (where IQR is the inter-quartile range, or
distance between the first and third quartiles). The lower whisker extends from the first quantile to the smallest value or at most
1.5 x IQR. Data beyond the end of the whiskers are called `outlying` points and are plotted individually.
           
Disclaimer: This report was made by an automated system and has not gone through quality control checks and may be subject to 
large errors, it is presented as is with no guarantee of accuracy or completeness.

Plot Generated: ", Sys.Date())) +
      theme_bw()+
      theme(plot.margin = margin(1.5, 0.5, 0.5, 0.5, unit = "cm"),
            plot.caption = element_text(hjust = 0, size = 7, face =  "italic", color = "grey50")) +
      scale_color_manual(labels = c("Historical"), values = c("gray"))
    
    p4<- cowplot::ggdraw(p3) + 
      cowplot::draw_image(logoFile, x=0.97, y=0.98, hjust = 1, vjust = 1, halign = 1, valign = 1, scale = 0.2)
    
    
    cowplot::ggsave2(paste0("./mss_monthly_plots/graphs/", unique(one_stn_data$Number), ".pdf"), 
                     p4, scale = 1, width=20, height=15, units="cm", dpi = 150, title = "MSS Snow Report")
  }
    
}

timeseries$disconnect()

#Upload the completed graphs to AQTS
source("./utils/upload_graphs.R")
upload_graphs(url, username, password, "./mss_monthly_plots/graphs/", "mss")



