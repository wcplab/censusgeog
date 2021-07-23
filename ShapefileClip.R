
#Summer 2021 - Feeling the Squeeze, FIPS/SDWIS Matching
#Clipping GIS shapefiles to study area
#Data: 2000 Census TIGER/Line Place and CSD Shapefiles
#RA: Katelynn Conedera
#Created: 7.22.2021

#This script imports and and unzips all US County Subdivision and Place shape files from the Census Tiger/Line ftp site.
#Please note that because of the size of the data and number of files downloaded, this takes a while to process.
#If you are running this script for the first time, remove the # symbols behind all "lapply" functions.

#Though this defaults to the 2000 census geography, other years can easily be changed by doing the following:

#For the 2000 Census, shapefiles are located in the TIGER2010 distribution.
#For the 2010 Census, the only change in this script is to change "2000" to "2010" in the two FTP urls.

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
#lapply(csdfls, function(csdfls){curl_download(paste0(csdftp,csdfls),destfile = csdfls,handle = log)})


#--------Place FTP--------
#Get list of file names and urls
placeftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/PLACE/2000/"
placefls <- getURL(placeftp, dirlistonly = TRUE)
placefls <- strsplit(placefls,"\r\n")
placefls <- unlist(placefls)
placefls <- placefls[-c(52:54,56)]

#Loop each file name in to download
#lapply(placefls, function(placefls){curl_download(paste0(placeftp,placefls),destfile = placefls,handle = log)})


#--------Hawaii County FTP--------
#Download Hawaii County shapefile
#curl_download("ftp://ftp2.census.gov/geo/tiger/TIGER2010/COUNTY/2000/tl_2010_15_county00.zip",
#              destfile = "tl_2010_15_county00.zip",handle = log)
rm(csdftp,placeftp,log)


#--------Processing--------
#Unzip files
#Again, these two lines will take a while to process
#lapply(csdfls,function(csdfls){unzip(csdfls)})
#lapply(placefls,function(placefls){unzip(placefls)})
#unzip("tl_2010_15_county00.zip")

#Delete original zip files
#Caution: Deleting the CSD files takes a very long time.
#lapply(csdfls,function(csdfls){unlink(csdfls)})
#lapply(placefls,function(placefls){unlink(placefls)})
#unlink("tl_2010_15_county00.zip")

#Change .zip list to .shp list
csdshp <- sub(".zip",".shp",csdfls)
placeshp <- sub(".zip",".shp",placefls)

rm(csdfls, placefls)

#Read in shape files
csdall <- lapply(csdshp,read_sf)
placeall <- lapply(placeshp,read_sf)
countyhi <- read_sf("tl_2010_15_county00.shp")
rm(csdshp,placeshp)

#Merge shape files
csdmerge <- do.call(rbind, csdall)
placemerge <- do.call(rbind, placeall)
rm(csdall,placeall)


#--------Matching--------
#Load list of cities
cities <- read.csv("G:/Shared drives/Squeeze Project/FIPS SDWIS Matching/Output/Census Match Final.csv",
                   colClasses = c("FIPS" = "character"))
fipsc <- na.omit(ifelse(nchar(cities$FIPS) == 10,cities$FIPS,NA))
fipsp <- na.omit(ifelse(nchar(cities$FIPS) == 7,cities$FIPS,NA))
fipshi <- na.omit(ifelse(nchar(cities$FIPS) == 5,cities$FIPS,NA))
rm(cities)

#Select study cities
csdselect <- subset(csdmerge,csdmerge$COSBIDFP00 %in% fipsc)
plcselect <- subset(placemerge,placemerge$PLCIDFP00 %in% fipsp)
hiselect <- subset(countyhi,countyhi$CNTYIDFP00 %in% fipshi)

#Label correct FIPS column
colnames(csdselect)[4] <- "FIPS"
colnames(plcselect)[3] <- "FIPS"
colnames(hiselect)[3] <- "FIPS"


#--------Finalizing--------
#Export new shapefiles
setwd("../")
write_sf(plcselect,"SelectedGeog","USPlaces2000",driver = "ESRI Shapefile")
write_sf(csdselect,"SelectedGeog","USCSDs2000",driver = "ESRI Shapefile")
write_sf(hiselect,"SelectedGeog","HICounties2000",driver = "ESRI Shapefile")
