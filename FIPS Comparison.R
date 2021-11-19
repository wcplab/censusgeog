
#Fall 2021 - Feeling the Squeeze, FIPS/SDWIS Matching
#Identifying Census jurisdictions with changed FIPS codes over the study period
#Data: 2000 Decennial Census, 2014-2018 American Community Survey 5-Year Estimates
#RA: Katelynn Conedera
#Last Updated: 11.19.2021

#The original Census FIPS list was pulled from the 2000 Census because our selection criteria
#was based on the population of the jurisdiction in 2000. However, some jurisdictions either
#merged with others, unincorporated, or changed their names between 2000 and 2018. This has
#led to a minor mismatch between FIPS codes from our matches, financial data, and more recent
#Census estimates. This script aims to identify and fix the inconsistencies.

#-----Setup-----
#Libraries

#Load Census data
c00 <- read.csv("Output/Census_Base_Geog_Corrected_v2.csv")
