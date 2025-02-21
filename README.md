# AQTS Reports
This repo contains code used to generate automated reports for snow and groundwater that are posted to the [BC real-time reporting tool](https://www2.gov.bc.ca/gov/content?id=39A675506AE54C4CB240849338B7C8D8). 

Data is derived directly from the database via an API link and via the public data distribution tools including the [BC Data Catalogue](https://catalogue.data.gov.bc.ca/) and the [data_searches](https://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/) web page. 

Scripts in this repo use the timeseries_clinet.R file writtin and maintained by [Aquatic Informatics](https://github.com/AquaticInformatics) and can be found in their repo [here](https://github.com/AquaticInformatics/examples/blob/fa417675042ea1f1d08358f2c42244e7c4baac23/TimeSeries/PublicApis/R/timeseries_client.R). 

## Example reports
  [7-Day Weekly ASWS Report](https://bcmoe-prod.aquaticinformatics.net/Report/Show/Snow.4B18P.Weekly%20Report/)
  
  [Monthly MSS Report](https://bcmoe-prod.aquaticinformatics.net/Report/Show/SnowMSS.1C31.MSS%20Report/)
  
  [Ground Water Levels](https://bcmoe-prod.aquaticinformatics.net/Report/Show/Groundwater.OW118.GWGraphAllData/)
  

## Getting Help or Reporting an Issue

To report bugs/issues/feature requests, please file an issue.

## How to Contribute

If you would like to contribute to the package, please see our CONTRIBUTING guidelines.

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## License

Copyright 2018 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at

https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
