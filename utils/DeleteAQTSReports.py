# -*- coding: utf-8 -*-
"""
@author: criddel

Created on 02-18-2025

This script deletes any reports from the Reports section of WebPortal. 
Be careful with this script! There is no reversing this action!

"""

import pandas as pd
import win32com.client
import requests
from api_auth import aq_api_client
import os
import json

#Create Session
session = aq_api_client("prod")
session.connect()


#Optional step - create dataframe of locations to filter by if you are only wanting to delete certain reports.
#Here, I am creating a dataframe of MSS Locations to filter by later
response_loc = session.publish.get("/GetLocationDescriptionList")
json_loc = response_loc.json()

filtered_list_loc = [
    dictionary for dictionary in json_loc['LocationDescriptions']
    if dictionary['PrimaryFolder'] == "Locations.SNOW.Manual Snow Sites"
]
df_mss = pd.DataFrame.from_dict(filtered_list_loc)

#Get total list of reports - this includes everything created with the R scripts and Recurring Reports in AQTS. 
response_reports = session.publish.get("/GetReportList")
json_reports = response_reports.json()
filtered_list_rep = [
    dictionary for dictionary in json_reports['Reports']
]
df_reports = pd.DataFrame.from_dict(filtered_list_rep)

#Customize this section to filter df_reports to just the ones you want to delete. 
#Be careful how you filter this and make sure you are only deleting reports you would like to! 
#Maybe print out a CSV to double check before you delete
df_reports = df_reports[(df_reports.Title.str.contains("Snow.")) & (df_reports.Title.str.contains(".Weekly Report"))]
df_reports = df_reports[df_reports['LocationUniqueId'].isin(df_mss['UniqueId'])]

#Loop to delete each report in df_reports
for index, row in df_reports.iterrows():
    uid = row['ReportUniqueId']
    session.acquisition.delete("/attachments/reports/" + uid)

#Disconnect Session
session.disconnect()