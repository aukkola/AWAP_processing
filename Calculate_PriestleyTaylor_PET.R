library(raster)
library(rstash)


### Calculates mean monthly PET !!! ###

#clear R environment
rm(list=ls(all=TRUE))



#Need SW radiation and temperature as inputs

path <- "/g/data/w35/Shared_data/Observations/AWAP_all_variables/monthly/"


start_yr <- 1990 #radiation starts in 1990
end_yr   <- 2019


#Dummy variable
#Read elevation (use gswp3 elevation for all datasets)
elev <- raster("/g/data/w35/amu561/CABLE_inputs/GSWP3_elevation_slope_mean_stddev.nc", 
               varname="elevation")




### Load raster layers ###

#Required inputs: Tair (deg C), SW rad
tmean_file <- list.files(paste0(path, "/tmean/"), pattern=paste0("AWAP_monthly_tmean_"), 
                        full.names=TRUE)

#open data
tair <- brick(tmean_file)

#Extract years
tstamps <- names(tair)

#get years
tair <- tair[[which(grepl(paste0("X", start_yr, ".01.1"), tstamps)):
              which(grepl(paste0("X", end_yr, ".12.1"), tstamps)) ]]



#Solar radiation (W m-2)
swrad_file <- list.files(paste0(path, "/rad/"), pattern=paste0("AWAP_monthly_rad_"), 
                         full.names=TRUE)

swrad <- brick(swrad_file)

#get years
tstamps <- names(swrad)

swrad <- swrad[[which(grepl(paste0("X", start_yr, ".01.1"), tstamps)):
                which(grepl(paste0("X", end_yr, ".12.1"), tstamps)) ]]




#Initialise bricks to hold all years
all_pet <- brick()


#Get coordinates
coords <- coordinates(tair)


#Resample elevation
elev <- resample(elev, tair[[1]])



### Calculate PET ###

#Loop through years
for(y in 1:(nlayers(tair)/12))
{
  
  #Convert to matrix [lon,lat,data]
  tair_mat  <- cbind(coords, values(tair[[(y*12-11):(y*12)]]))
  
  #Set rainfall data as temperature data... Not used for PET calculation so doesn't matter
  rain_mat <- tair_mat 
  
  
  #Convert to matrix [lon,lat,data]
  swrad_mat <- cbind(coords, values(swrad[[(y*12-11):(y*12)]]))
  
  
  #Convert swrad from W m-2 to mJ/m2/month
  for(m in 1:12) swrad_mat[,m+2] <- swrad_mat[,m+2] * 86400 / 10**6 #* days[m]  
  
  #Convert SW rad to sun hours
  sun_hrs <- sunshine(swrad_mat)
  sun_hrs <- sun_hrs$Sun.Hrs
  

  
  #Set initial conditions (field cap and soil water depth set randomly, won't affect PET)
  grid_info <- cbind(coords, values(elev), rep(150, times=nrow(coords)), 
                     rep(0, times=nrow(coords))) #coords, elev, fieldcap, soil water depth 
  
  
  #Run stash model  
  outs <- grid.stash(temp.air=tair_mat, precip=rain_mat, sun.hours=sun_hrs, grid.chars=grid_info)
  pet <- outs$pot.evap
  
  
  #Convert PET to raster
  pet_brick <- brick()
  
  for(m in 1:12)
  {
    data_raster <- raster(nrow=nrow(tair), ncol=ncol(tair))
    extent(data_raster) <- extent(tair)
    Cells <- cellFromXY(data_raster, coordinates(tair))
    data_raster[Cells] <- pet[,m+2]
    
    pet_brick <- addLayer(pet_brick, data_raster)
  }
  
  
  #Add annual data to all_pet
  all_pet <- addLayer(all_pet, pet_brick)
  
  
  #Clear
  rm(sun_hrs)
  rm(outs)
  rm(pet)
  rm(pet_brick)
  
  
  
  
  
  
  
} #years


  
#Set time unit

#time stamps
tstamps <- seq.Date(from=as.Date(paste0(start_yr, "-01-01")), to=as.Date(paste0(end_yr, "-12-01")),
                    by="month")

all_pet <- setZ(all_pet, tstamps)





#Write PET to file
outpath <- paste0(path, "/pet/")
dir.create(outpath, recursive=TRUE)

filename <- paste(outpath, "/AWAP_monthly_PriestleyTaylor_PET_", 
                  start_yr, "_", end_yr, ".nc", sep="")


writeRaster(all_pet, filename, format="CDF", varname="PET", varunit="mm/month", 
            zunit=paste0("Months since ", start_yr, "-01-01"), 
            overwrite=TRUE)


rm(all_pet)







