
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
library(raster)
library(sf)
setwd("G:/Shared drives/Squeeze Project/Census Geography Reference/TIGER")


#--------CSD FTP--------
#Get list of file names and urls
csdftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/COUSUB/2000/"
csdfls <- getURL(csdftp, dirlistonly = TRUE)
csdfls <- strsplit(csdfls,"\r\n")
csdfls <- unlist(csdfls)

#Set login
log <- new_handle(userpwd = "anonymous:anonymous")

#Loop each file name in to download
#Caution: There are thousands of shapefiles, download takes a long time
#lapply(csdfls, function(csdfls){curl_download(paste0(csdftp,csdfls),destfile = csdfls,handle = log)})


#--------Place FTP--------
#Get list of file names and urls
placeftp <- "ftp://ftp2.census.gov/geo/tiger/TIGER2010/PLACE/2000/"
placefls <- getURL(placeftp, dirlistonly = TRUE)
placefls <- strsplit(placefls,"\r\n")
placefls <- unlist(placefls)

#Loop each file name in to download
#Caution: Place shapefile download will take a few minutes
#lapply(placefls, function(placefls){curl_download(paste0(placeftp,placefls),destfile = placefls,handle = log)})
rm(csdftp,placeftp,log)

#--------Processing--------
#Unzip files
#Again, these two lines will take a while to process
#lapply(csdfls,function(csdfls){unzip(csdfls)})
#lapply(placefls,function(placefls){unzip(placefls)})

#Delete original zip files
#Caution: Deleting the CSD files takes a very long time.
#lapply(csdfls,function(csdfls){unlink(csdfls)})
#lapply(placefls,function(placefls){unlink(placefls)})

#Change .zip list to .shp list
csdshp <- sub(".zip",".shp",csdfls)
placeshp <- sub(".zip",".shp",placefls)
rm(csdfls, placefls)

#Read in shape files
csdall <- lapply(csdshp,read_sf)
placeall <- lapply(placeshp,read_sf)


#--------Matching--------
#List shapefiles