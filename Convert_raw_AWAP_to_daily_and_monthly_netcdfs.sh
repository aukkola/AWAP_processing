#!/bin/bash

#PBS -P dt6
#PBS -l walltime=15:00:00
#PBS -l mem=50GB
#PBS -l ncpus=1
#PBS -j oe
#PBS -q normal
#PBS -l wd
#PBS -l storage=gdata/w35


#directory
INDIR="/g/data/w35/Shared_data/Observations/AWAP_all_variables"

#Variables to process
vars=`ls $INDIR/daily_temp`


#First run R script to convert from flt to netcdf
#Rscript Convert_raw_AWAP_files_to_netcdf.R



#Loop through variables
for V in $vars
do
  
  
  ##################
  ### Daily data ###
  ##################
  
  #Create output directory
  outdir="$INDIR/daily/$V/"
  
  mkdir -p $outdir
  
  
  #Find all files
  files=`find $INDIR/daily_temp/$V/ -type f`

  
  #Merge time steps
  
  #Temporary file name
  daily_file_temp="$outdir/AWAP_daily_${V}_temp.nc"
  
  cdo -L mergetime $files $daily_file_temp
  
  #Get years and rewrite file name
  years=(`cdo showyear $daily_file_temp`)
  
  start_yr=`echo ${years[0]}`
  end_yr=`echo ${years[${#years[@]} - 1]}`
  
  #New file name with years
  daily_file="${outdir}/AWAP_daily_${V}_${start_yr}_${end_yr}.nc"
  
  
  #If radiation, convert from MJ to W/m2
  if [[ $V == "rad" ]]
  then
    
    #temp file
    temp="${outdir}/temp.nc"
    
    #Convert to W/m2 and change unit
    cdo expr,'rad=rad*1000000/(24*60*60)' -setunit,'W/m2' $daily_file_temp $temp
    
      
    #Rename file
    mv $temp $daily_file
    
    rm $daily_file_temp
  
  
  #Other variables
  else 
    
    #Rename file
    mv $daily_file_temp $daily_file
    
  fi
  
  
  ####################
  ### Monthly data ###
  ####################
  
  
  #Use merged daily file
  outdir_month="$INDIR/monthly/${V}/"
  
  mkdir -p $outdir_month


  #File name
  monthly_file="${outdir_month}/AWAP_monthly_${V}_${start_yr}_${end_yr}.nc"



  #if rain: take the sum
  if [[ $V == "rain" ]]
  then
        
    cdo monsum -setunit,"mm/month" $daily_file $monthly_file
    

  #if tmax, tmin, rad, wind speed, vph09 or vph15: take the mean
  else
  
    cdo monmean $daily_file $monthly_file
  
  fi
  


done



#####################################################
### Calculate mean temperature from tmax and tmin ###
#####################################################

### Daily ###

#Tmin and Tmax files
tmin_file=`find $INDIR/daily/tmin/*.nc`
tmax_file=`find $INDIR/daily/tmax/*.nc`

#Tmean output directory

outdir_daily="${INDIR}/daily/tmean/"
mkdir $outdir_daily

#Tmean output file 

#Get years and rewrite file name
years=(`cdo showyear $tmin_file`)

start_yr=`echo ${years[0]}`
end_yr=`echo ${years[${#years[@]} - 1]}`


tmean_daily_file="${outdir_daily}/AWAP_daily_tmean_${start_yr}_${end_yr}.nc"


#Calculate mean temp and change variable name
cdo chname,tmin,tmean -ensmean $tmin_file $tmax_file $tmean_daily_file



### Monthly ###

#Monthly output directory

outdir_monthly="${INDIR}/monthly/tmean/"
mkdir $outdir_monthly

#Monthly output file
tmean_monthly_file="${outdir_monthly}/AWAP_monthly_tmean_${start_yr}_${end_yr}.nc"


#Calculate monthly mean
cdo monmean $tmean_daily_file $tmean_monthly_file




######################################
### Calculate Priestley-Taylor PET ###
######################################

Rscript Calculate_PriestleyTaylor_PET.R












