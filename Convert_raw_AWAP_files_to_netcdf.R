library(raster)

#clear R environment
rm(list=ls(all=TRUE))


path <- "/g/data/w35/Shared_data/"



#Variables to process
vars <- c("rad", "rain", "tmax", "tmin", "vph09", "vph15", "windspeed")

units <- c("MJ", "mm",   "C",    "C",    "hpa",   "hpa",   "ms")

longname <- c("incoming shortwave radiation",
              "total precipitation",
              "maximum temperature",
              "minimum temperature",
              "vapour pressure at 9:00",
              "vapour pressure at 15:00",
              "wind speed")



#Collate dates to check that all dates were processed
all_dates <- list()

#Loop through variables
for (v in 1:length(vars)) {
  
  print(paste0("Variable: ", v))
  
  #Initialise
  all_dates[[v]] <- vector()
  
  #Output directory
  outdir <- paste0(path, "/Observations/AWAP_all_variables/daily_temp/", vars[v])
  dir.create(outdir, recursive=TRUE)
  
  
  
  #List directories (2018-2019 in a separate folder)
  dirs <- list.files(paste0(path, "/AWAP_raw_data/"), pattern=paste0("_", vars[v], "_"), 
                     full.names=TRUE)
  
  
  #loop through directories
  for (d in dirs) {
    
    
    #List files
    #need to make sure to only list daily files (and with or without synth)
    #only read 2019 subfolder because 2018 files already in main folder
    
    if (grepl("2018-2019", d)) {
      
      files <- list.files(paste0(d, "/2019/"), full.names=TRUE, 
                          pattern="day-[0-9]{8}-[0-9]{8}.flt|day-[0-9]{8}-[0-9]{8}_synth.flt")
      
    } else {
      files <- list.files(d, full.names=TRUE, pattern="day-[0-9]{8}-[0-9]{8}.flt|day-[0-9]{8}-[0-9]{8}_synth.flt")
    }
    
    
    
    #Loop through files
    for (f in files) {
      
      ### Read data and set projection ###
      
      data <- raster(f)
      
      crs(data) <- crs('+proj=longlat')
      
      
      ### Set time ###
      
      #Get date from file name (pick first instance)
      date <- unlist(regmatches(f, gregexpr("[0-9]{8}", f)))[1]
      
      #Can't remember how to converty yyyymmdd format to date. Do manually...
      tstamp <- as.Date(paste(substr(date, 1, 4), substr(date, 5, 6), substr(date, 7, 8), sep="-"))
      
      #Add to date vector
      all_dates[[v]] <- append(all_dates[[v]], tstamp)
      

      #Set z-axis
      data <- setZ(brick(data), tstamp, name='time')
      
      
      
      ### Write output ###
      
      
      #Output file name
      outfile <- paste0(outdir, "/AWAP_daily_", vars[v], "_", units[v], "_", tstamp, ".nc")
      
      writeRaster(data, outfile, varname=vars[v], varunit=units[v],
                  longname=longname[v], zname="time", zunit=paste0("Days since ", as.character(tstamp)), overwrite=TRUE)
      
      
    }
    
    
    
    #Check that processed all time steps
    if (any(diff(sort(all_dates[[v]])) !=1)) stop(paste0("Missing time steps in ", vars[v]))
    
    
  } #directories
  
  
  
} #variables







# 
# 
# 
# sorted_dates <- sort(all_dates[[v]])
# 
# diffs <- diff(sorted_dates)
# 
# which(diffs !=1)
# 





