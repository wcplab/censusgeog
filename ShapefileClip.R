
#Summer 2021 - Feeling the Squeeze, FIPS/SDWIS Matching
#Clipping GIS shapefiles to study area
#Data: 2000 Census TIGER/Line Place and CSD Shapefiles
#RA: Katelynn Conedera
#Created: 7.22.2021
#Last updated: 7.28.2021

#This script imports and and unzips all US County Subdivision and Place shape files from the Census Tiger/Line ftp site.
#Please note that because of the size of the data and number of files downloaded, this takes a while to process.
#If you already have the full US shapefiles you wish to apply this script to, jump down to the "matching" section.

#Though this defaults to the 2000 census geography, other years can easily be changed by doing the following:

#For the 2000 Census, shapefiles are located in the TIGER2010 distribution.
#For the 2010 Census, the only change in this script is to change "2000" to "2010" in the three FTP urls.

#Other data from the US Census FTP site can easily be added here instead.
#Just access the FTP site and determine the location of the desired files to update the URLs.


#--------Setup--------
#Load libraries, paste path to data folder, find & replace \ with /
library(curl)
library(RCurl)
library(sf)
library(rgdal)
setwd("G:/Shared drives/Squeeze Project/Census Geography Reference/TIGER")


#--------CSD FTP--------
#Get list of file names and urls
csdftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/COUSUB/2000/"
csdfls <- getURL(csdftp, dirlistonly = TRUE)
csdfls <- strsplit(csdfls,"\r\n")
csdfls <- unlist(csdfls)

#Only need state-level shapefiles
csdfls <- na.omit(ifelse(nchar(csdfls) == 23,csdfls,NA))
csdfls <- csdfls[-c(52:54,56)]

#Set login
log <- new_handle(userpwd = "anonymous:anonymous")

#Loop each file name in to download
lapply(csdfls, function(csdfls){curl_download(paste0(csdftp,csdfls),destfile = csdfls,handle = log)})


#--------Place FTP--------
#Get list of file names and urls
placeftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/PLACE/2000/"
placefls <- getURL(placeftp, dirlistonly = TRUE)
placefls <- strsplit(placefls,"\r\n")
placefls <- unlist(placefls)
placefls <- placefls[-c(52:54,56)]

#Loop each file name in to download
lapply(placefls, function(placefls){curl_download(paste0(placeftp,placefls),destfile = placefls,handle = log)})


#--------Hawaii County FTP--------
#Download Hawaii County shapefile
cntyftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/COUNTY/2000/"
cntyfls <- "tl_2010_15_county00.zip"
curl_download(paste0(cntyftp,cntyfls),destfile = cntyfls,handle = log)
rm(csdftp,placeftp,cntyftp,log)


#--------Processing--------
#Unzip files
lapply(csdfls,function(csdfls){unzip(csdfls)})
lapply(placefls,function(placefls){unzip(placefls)})
unzip(cntyfls)

#Delete original zip files
lapply(csdfls,function(csdfls){unlink(csdfls)})
lapply(placefls,function(placefls){unlink(placefls)})
unlink(cntyfls)

#Change .zip list to .shp list
csdshp <- sub(".zip",".shp",csdfls)
placeshp <- sub(".zip",".shp",placefls)
cntyshp <- sub(".zip",".shp",cntyfls)
rm(csdfls,placefls,cntyfls)

#Read in shape files
csdall <- lapply(csdshp,read_sf)
placeall <- lapply(placeshp,read_sf)
countyhi <- read_sf(cntyshp)

#Merge shape files
csdmerge <- do.call(rbind, csdall)
placemerge <- do.call(rbind, placeall)
rm(csdall,placeall)

#Save shape files
write_sf(placemerge,".","USPlaces2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
write_sf(csdmerge,".","USCSDs2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
write_sf(countyhi,".","HICounties2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))

#Remove individual shapefiles
cntyshp <- sub("shp","*",cntyshp)
csdshp <- sub("shp","*",csdshp)
placeshp <- sub("shp","*",placeshp)
lapply(csdshp,function(csdshp){unlink(csdshp)})
lapply(placeshp,function(placeshp){unlink(placeshp)})
unlink(cntyshp)
rm(csdshp,placeshp,cntyshp)


#--------Matching--------
#Uncomment only if you're scripting from this point forward
#csdmerge <- read_sf("USCSDs2000.shp")
#placemerge <- read_sf("USPlaces2000.shp")
#countyhi <- read_sf("HICounties2000.shp")
setwd("G:/Shared drives/Squeeze Project/FIPS SDWIS Matching/Base/SelectedGeog")

#Load list of cities
cities <- read.csv("../../Output/Census Match Base.csv",
                   colClasses = c("FIPS" = "character"))
fipsc <- na.omit(ifelse(nchar(cities$FIPS) == 10,cities$FIPS,NA))
fipsp <- na.omit(ifelse(nchar(cities$FIPS) == 7,cities$FIPS,NA))
fipshi <- na.omit(ifelse(nchar(cities$FIPS) == 5,cities$FIPS,NA))
rm(cities)

#Select study cities
csdselect <- subset(csdmerge,csdmerge$COSBIDFP00 %in% fipsc)
plcselect <- subset(placemerge,placemerge$PLCIDFP00 %in% fipsp)
hiselect <- subset(countyhi,countyhi$CNTYIDFP00 %in% fipshi)
rm(csdmerge,placemerge,countyhi)
rm(fipsc,fipsp,fipshi)


#Label correct FIPS column
colnames(csdselect)[4] <- "FIPS"
colnames(plcselect)[3] <- "FIPS"
colnames(hiselect)[3] <- "FIPS"

#Remove CSD Towns identical to Places
csddupe <- na.omit(match(plcselect$geometry,csdselect$geometry))
csdrm <- csdselect[csddupe,]
csdselect <- csdselect[-csddupe,]
rm(csddupe)

#Save list of removed towns for later comparison
csdexp <- st_drop_geometry(csdrm)
write.csv(csdexp,"../../Lists/Removed Duplicate CSD Towns.csv",row.names = FALSE)
rm(csdexp)


#--------Finalizing--------
#Export new shapefiles
write_sf(csdselect,".","SelectCSDs2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
write_sf(csdrm,".","RemovedCSDs2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
write_sf(plcselect,".","SelectPlaces2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
write_sf(hiselect,".","SelectHICounties2000",driver = "ESRI Shapefile",layer_options = c("Overwrite"))
