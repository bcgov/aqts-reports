###############################################################################
#DESCRIPTION: This code generates the "graph all data" ground water plots. Data
#is downloaded from the bc data catalogue, plots are made, and the final figures
#are saved in /graphs folder.
#
#By: Jeremy Krogh Nov 26, 2020
#Updated March 2025
##############################################################################

#packages to install - only need to do this once
# install.packages("bcdata")
# install.packages("readr")
# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("cowplot")
# install.packages("lubridate")
# install.packages("magick")

library(bcdata)
library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(cowplot)
library(lubridate)
library(magick)


## Download the obs well data record from the bc data catalouge
obswells <- bcdc_get_data('57c55f10-cf8e-40bb-aae0-2eff311f1685', 
                          resource = 'caa18e44-c1a3-490f-a467-f2352bd8d382', 
                          col_types = c("Ddc"))

## Check the unique levels of myLocation
ListOfWells <- unique(obswells$myLocation)

## Get just the obs well numbers
ListOfWells <- ListOfWells[c(1,seq(3,length(ListOfWells)))]

## Loop through all of the wells making a graph for each one
for (i in seq(1,length(ListOfWells))){
  
  ## Select data for the i-th well
  sub_obswells <- obswells %>% filter(myLocation == ListOfWells[i])
  
  ## Get the smallest and largest year in the data record
  graph_min_yr <- round(year(min(sub_obswells$QualifiedTime)), -1)
  graph_max_yr <- round(year(max(sub_obswells$QualifiedTime)), -1)
  
  ## If there is more than 30 years of data make x-tick marks every 10 years on Jan 01 of each decade
  if ((graph_max_yr - graph_min_yr) > 30) {
    yr_ticks <- seq(graph_min_yr, graph_max_yr, by = 10)
    yr_ticks <- as.Date(paste0(yr_ticks, "-01-01"))
  
  ## Make the plot using ggplot
  p <- ggplot(data = sub_obswells, mapping = aes(y = Value, x = QualifiedTime)) +
    geom_point(colour = "blue4", size = 0.75) +
    geom_line(colour = "blue4", size = 0.2, alpha = 0.2) +
    scale_y_continuous(trans = "reverse") + 
    scale_x_date(breaks = yr_ticks, date_labels = "%Y") +
    labs(x = "", y= "Water Level Below Ground (m)", 
         title = paste0("OBS WELL ", substr(unique(sub_obswells$myLocation), 3, 6)),
         subtitle = "Water Level Snapshot",
         caption = paste0("Note: True data are marked with a dot, the thin line connecting points is a visual aid only and does not represent true observations. \n",
         "The full data set can be downloaded via the BC Data Catalogue or the BC Real-time Water Data tool.")) +
    theme_bw() +
    theme(plot.margin = margin(0.2, 0.2, 1.1, 0.2, unit = "cm"),
          plot.caption = element_text(hjust = 0, size = 7, face =  "italic", color = "grey50"))
    
  ## Use cowplot to add the BC Gov Mark to the bottom right corner of the plot
  p<-ggdraw(p) + 
    draw_image("./utils/logos/bcmark_pos.png", x = 0.97, y = 0.18, hjust = 1, vjust = 1, width = 0.12, height = 0.2)
  
  ## Save the graph as a pdf
  ggsave2(paste0("./graphs/Groundwater.", ListOfWells[i], ".GWGraphAllData.pdf"),
         width = 10, height = 5, units = "in")
  
  ## If the length of the data record is less than 3 years, let ggplot make it's own x-ticks
  ## and place the tick marks at 01 of each month
  } else if ((graph_max_yr - graph_min_yr) < 3) {
    
    ## Make the plot
    p <- ggplot(data = sub_obswells, mapping = aes(y = Value, x = QualifiedTime)) +
      geom_point(colour = "blue4", size = 0.75) +
      geom_line(colour = "blue4", size = 0.2, alpha = 0.2) +
      scale_y_continuous(trans = "reverse") + 
      scale_x_date(date_labels = "%Y-%m") +
      labs(x = "", y= "Water Level Below Ground (m)", 
           title = paste0("OBS WELL ", substr(unique(sub_obswells$myLocation), 3, 6)),
           subtitle = "Water Level Snapshot",
           caption = paste0("Note: True data are marked with a dot, the thin line connecting points is a visual aid only and does not represent true observations. \n",
                            "The full data set can be downloaded via the BC Data Catalogue or the BC Real-time Water Data tool."))  +
      theme_bw() +
      theme(plot.margin = margin(0.2, 0.2, 1.1, 0.2, unit = "cm"),
            plot.caption = element_text(hjust = 0, size = 7, face =  "italic", color = "grey50"))
    
    ## Use Cowplot to add the BC Government mark to the lower right corner
    p<-ggdraw(p) + 
      draw_image("./utils/logos/bcmark_pos.png", x = 0.97, y = 0.18, hjust = 1, vjust = 1, width = 0.12, height = 0.2)
    
    ## Save the graph as a pdf
    ggsave2(paste0("./graphs/Groundwater.", ListOfWells[i], ".GWGraphAllData.pdf"),
            width = 10, height = 5, units = "in", title = "Graph All Data")
  
    ## Finally, if the record length is greater than 3 years but less than 30 years. Let ggplot
    ## pick the x-tick locations and place them on 01 of each year
    } else {
    
    ## Make the plot
    p <- ggplot(data = sub_obswells, mapping = aes(y = Value, x = QualifiedTime)) +
      geom_point(colour = "blue4", size = 0.75) +
      geom_line(colour = "blue4", size = 0.2, alpha = 0.2) +
      scale_y_continuous(trans = "reverse") + 
      scale_x_date(date_labels = "%Y") +
      labs(x = "", y= "Water Level Below Ground (m)", 
           title = paste0("OBS WELL ", substr(unique(sub_obswells$myLocation), 3, 6)),
           subtitle = "Water Level Snapshot",
           caption = paste0("Note: True data are marked with a dot, the thin line connecting points is a visual aid only and does not represent true observations. \n",
                            "The full data set can be downloaded via the BC Data Catalogue or the BC Real-time Water Data tool.")) +
      theme_bw() +
      theme(plot.margin = margin(0.2, 0.2, 1.1, 0.2, unit = "cm"),
            plot.caption = element_text(hjust = 0, size = 7, face =  "italic", color = "grey50"))
    
    ## Add the BC Gov mark to the lower right corner
    p<-ggdraw(p) + 
      draw_image("./utils/logos/bcmark_pos.png", x = 0.97, y = 0.18, hjust = 1, vjust = 1, width = 0.12, height = 0.2)
    
    ## Save the plot
    ggsave2(paste0("./graphs/Groundwater.", ListOfWells[i], ".GWGraphAllData.pdf"),
            width = 10, height = 5, units = "in", title = "Graph All Data")
    
  }

}

## Load and call the function that uploads all the plots to the NG web server
source("upload_graph_all_data_plots.R")
upload_graph_all_data_plots()