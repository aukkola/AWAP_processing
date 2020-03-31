library(raster)

#clear R environment
rm(list=ls(all=TRUE))


path <-   "/srv/ccrc/data04/z3509830/Obs_precip_products/AWAP/"
#"/srv/ccrc/data04/z3509830/Australia_water_cycle_trends/"

#Set years
years <- 1900:2019


#Load data
#precip <- brick(paste0(path, "/monthly_gapfilled_pr_1900_2018.nc"))
precip <- brick(paste0(path, "/Monthly_data_1900_2019/", 
                       "Monthly_total_precipitation_AWAP_masked_1900_2019.nc"))

#Extend with CSIRO data (bom data only currently goes to march 2019)

pr_2019 <- brick(paste0(path, "/Monthly_data_2019/AWAP_monthly_rain_only_2019_CSIRO_regridded_to_bom.nc"))

#Add April-Dec
precip <- addLayer(precip, pr_2019[[4:12]])



#Calculate growing season years Jul-Jun

ind <- seq(7, by=12, length.out=nlayers(precip)/12-1)


annual_precip <- brick(lapply(ind, function(x) sum(precip[[x:(x+11)]])))



#Calculate annual percentiles
ecdf_fun <- function(x) {
  
  if (all(is.na(x))) {
    return(rep(NA, length(x)))
  } else {
    ecdf(x)(x)
  }

}

quantiles <- calc(annual_precip, function(x) ecdf_fun(x))



#Set time axis 
tstamps <- seq.Date(from=as.Date(paste0(years[1], "-07-01")), 
                    to=as.Date(paste0(years[length(years)-1], "-07-01")),
         by="year")

quantiles <- setZ(quantiles, tstamps)


#Output directory
outdir <- paste0(path, "/precip_percentiles/")
dir.create(outdir)

writeRaster(quantiles, paste0(outdir, "/AWAP_annual_rainfall_percentiles_", years[1], "_", 
                              years[length(years)-1], "_jul_jun_years.nc"),
            varname="pr",  zname="time", zunit="Years since 1900-07-01", overwrite=TRUE)







