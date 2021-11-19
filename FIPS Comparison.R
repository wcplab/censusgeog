
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
library(stringr)

#Load Census data
c00 <- read.csv("Output/Census_Base_Geog_Corrected_v2.csv")
c18 <- read.csv("Output/Census_Base_Geog_Corrected_2018_v1.csv")

#-----Prep-----
#Merge the two datasets by FIPS
colnames(c00)
colnames(c18)
all <- merge(c00,c18,by = "FIPS", suffixes = c("_00","_18"), all = TRUE)
rm(c00,c18)

#Subset those without matches
all$check <- ifelse(is.na(all$Name_00) | is.na(all$Name_18), "CHECK","")
miss <- subset(all, check == "CHECK")

#Collapse columns and differentiate by year
miss$yr <- ifelse(is.na(miss$Name_00),"2018","2000")
colnames(miss) <- sub("_00","",colnames(miss))
colnames(miss)
for(i in 1:7) {
  miss[,i+1] <- ifelse(miss$yr == "2018",miss[,i+8],miss[,i+1])
  rm(i)
}
cols <- str_subset(colnames(miss),"_18",negate = TRUE)
miss <- subset(miss, select = cols)
rm(cols)

#Extract municipality name
#head(miss)
#iss$Match <- str_remove(miss$Name,paste0(" ",miss$Type))

#Remove municipalities with fewer than 10,000 people
miss <- subset(miss, !(Pop < 10000))

#Separate by place and CSD
pl <- subset(miss, Geog == "Place")
csd <- subset(miss, Geog == "CSD")
