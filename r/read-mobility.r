library(tidyr)
library(lubridate)
library(stringr)
library(dplyr)
library(data.table)


### VERY important!
# At times google has mobility na for some days in that cae you will need to impute those values
# else code will fail 
# read predictions of future days from foursquare
# if you need predictions from foursquare please run file mobility-regression.r in
# the folder usa/code/utils/mobility-reg

### from: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/read-data-usa.r ###


##########

### https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/base-usa.r#L125-L133

### i) https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/process-covariates.r#L75-L76
### ii) https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/process-covariates.r#L130
### iii) features ... https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/process-covariates.r#L156
### iv) covariates partial state https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/process-covariates.r#L163

# 1. read_google_mobility()
# 2. read in google predicted mobility (imputed)
# 3. some processing, stack predicted mobility below actual report
# 4. process_covariates(mobility, ...)
# 5. pad_mobility
# 6. fit it into stan_data ..

##########

library(rstan)
library(data.table)
library(lubridate)
library(gdata)
library(dplyr)
library(tidyr)
library(EnvStats)
library(scales)
library(stringr)

# good
read_google_mobility <- function(countries, codeToName){

  # read in global report, subset to IL
  GlobalMobilityReport <<- '../modelInput/mobility/Global_Mobility_Report.csv'
  google_mobility <- read.csv(GlobalMobilityReport, stringsAsFactors = FALSE)
  google_mobility <- google_mobility[google_mobility$country_region == "United States", ]
  google_mobility <- google_mobility[google_mobility$sub_region_1 == "Illinois", ]

  # derive "countyName" column
  google_mobility$countyName <- sub(" County", "", google_mobility$sub_region_2)

  # set county code in there -> > names(codeToName) > [1] "countyCode" "countyName"
  # new column -> "countyCode"
  google_mobility <- left_join(google_mobility, codeToName, by = c("countyName"))
  google_mobility <- google_mobility[google_mobility$countyCode %in% countries,]

  # Format the google mobility data
  google_mobility$date = as.Date(google_mobility$date, format = '%Y-%m-%d')

  scoreCols <- c(
    "retail_and_recreation_percent_change_from_baseline",
    "grocery_and_pharmacy_percent_change_from_baseline",
    "parks_percent_change_from_baseline",
    "transit_stations_percent_change_from_baseline", 
    "workplaces_percent_change_from_baseline", 
    "residential_percent_change_from_baseline"
  )

  # transform raw percentage numbers to [0,1] (e.g., -45 -> .45)
  google_mobility[, scoreCols] <- google_mobility[, scoreCols]/100
  google_mobility[, scoreCols] <- google_mobility[, scoreCols] * -1
  
  # drop unnecessary columns - keep "sub_region_1", which is the state
  dropCols <- c("country_region_code", "country_region", "sub_region_2", "iso_3166_2_code", "census_fips_code")
  google_mobility <- google_mobility[, -which(names(google_mobility) %in% dropCols)]

  # rename columns
  renameMap <- c(
    "retail.recreation" = "retail_and_recreation_percent_change_from_baseline",
    "grocery.pharmacy" = "grocery_and_pharmacy_percent_change_from_baseline",
    "parks" = "parks_percent_change_from_baseline",
    "transitstations" = "transit_stations_percent_change_from_baseline",
    "workplace" = "workplaces_percent_change_from_baseline",
    "residential" = "residential_percent_change_from_baseline"
  )

  google_mobility <- rename(google_mobility, all_of(renameMap))

  # reorder cols
  colOrder <- c("date", "sub_region_1", "countyCode", "countyName",
                "retail.recreation", "grocery.pharmacy", "parks", 
                "transitstations", "workplace", "residential")
  google_mobility <- google_mobility[colOrder]                

  return(google_mobility)
}



# fixme - eventually remove this - only here for reference - incorporated into main loop in base.r
# pretty good progress
process_covariates <- function(states, mobility, death_data, formula_partial_state){
    
  covariate_list_partial_state <- list()
  
  k=1 # ? -> just a counter

  for(State in states) {

    # Selects mobility data for each state # COUNTY
    covariates_state <- mobility[which(mobility$code == State),]    
        
    # Find minimum date for the data
    min_date <- min(data_state$date)
    num_pad <- (min(covariates_state$date) - min_date[[1]])[[1]]
    len_mobility <- ncol(covariates_state)
    padded_covariates <- pad_mobility(len_mobility, num_pad, min_date, covariates_state, forecast_length, data_state, State)

    # include transit
    transit_usage <- rep(1, (N + forecast_length))

    # creating features -> only want "partial_state"
    df_features <- create_features(len_mobility, padded_covariates, transit_usage)
    features_partial_state <- model.matrix(formula_partial_state, df_features)    
    covariate_list_partial_state[[k]] <- features_partial_state

    k <- k+1    
  }
  
  stan_data$P_partial_state = dim(features_partial_state)[2]
  stan_data$X_partial_state = array(NA, dim = c(stan_data$M , stan_data$N2 ,stan_data$P_partial_state))
  
  for (i in 1:stan_data$M){
    stan_data$X_partial_state[i,,] = covariate_list_partial_state[[i]]
  }

  stan_data$W <- ceiling(stan_data$N2/7) 
  stan_data$week_index <- matrix(1,stan_data$M,stan_data$N2)
  for(state.i in 1:stan_data$M) {
    stan_data$week_index[state.i,] <- rep(2:(stan_data$W+1),each=7)[1:stan_data$N2]
    last_ar_week = which(dates[[state.i]]==max(death_data$date) - 28)
    stan_data$week_index[state.i,last_ar_week:ncol(stan_data$week_index)] <-  stan_data$week_index[state.i,last_ar_week]
  }

  return(list("stan_data" = stan_data))

}

# fixme
pad_mobility <- function(len_mobility, num_pad, min_date, covariates_state, forecast_length, data_state, State){
  if (num_pad <= 0){
    covariates_state <- covariates_state[covariates_state$date >=min_date, ]
    pad_dates_end <- max(covariates_state$date) + 
      days(1:(forecast_length - (min(data_state$date) - min(covariates_state$date)) + 
                (max(data_state$date) - max(covariates_state$date))))
    for_length <- length(pad_dates_end)
    
    len_covariates <- length(covariates_state$grocery.pharmacy)
    padded_covariates <- data.frame("code" = rep(State, length(covariates_state$date) + for_length),
                                    "date" = c(covariates_state$date, pad_dates_end),
                                    "grocery.pharmacy" = c(covariates_state$grocery.pharmacy, 
                                                           rep(median(covariates_state$grocery.pharmacy[(len_covariates-7):len_covariates],na.rm = TRUE),
                                                               for_length)),
                                    "parks" = c(covariates_state$parks, 
                                                rep(median(covariates_state$parks[(len_covariates-7):len_covariates],na.rm = TRUE), for_length)), 
                                    "residential" = c(covariates_state$residential, 
                                                      rep(median(covariates_state$residential[(len_covariates-7):len_covariates], na.rm = TRUE), for_length)),
                                    "retail.recreation" = c(covariates_state$retail.recreation, 
                                                            rep(median(covariates_state$retail.recreation[(len_covariates-7):len_covariates],na.rm = TRUE), 
                                                                for_length)),
                                    "transitstations" = c(covariates_state$transitstations, 
                                                          rep(median(covariates_state$transitstations[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                              for_length)),
                                    "workplace" = c(covariates_state$workplace, 
                                                    rep(median(covariates_state$workplace[(len_covariates-7):len_covariates], na.rm = TRUE), for_length)))  

  } else {
    pad_dates_front <- min_date + days(1:num_pad-1)
    pad_dates_end <- max(covariates_state$date) + 
      days(1:(forecast_length + (max(data_state$date) - max(covariates_state$date))))
    for_length <- length(pad_dates_end)

    len_covariates <- length(covariates_state$grocery.pharmacy)
    padded_covariates <- data.frame("code" = rep(State, num_pad + length(covariates_state$date) + for_length),
                                    "date" = c(pad_dates_front, covariates_state$date, pad_dates_end),
                                    "grocery.pharmacy" = c(as.integer(rep(0, num_pad)), covariates_state$grocery.pharmacy, 
                                                           rep(median(covariates_state$grocery.pharmacy[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                               for_length)),
                                    "parks" = c(as.integer(rep(0, num_pad)), covariates_state$parks, 
                                                rep(median(covariates_state$parks[(len_covariates-7):len_covariates],na.rm = TRUE), for_length)), 
                                    "residential" = c(as.integer(rep(0, num_pad)), covariates_state$residential, 
                                                      rep(median(covariates_state$residential[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                          for_length)),
                                    "retail.recreation" = c(as.integer(rep(0, num_pad)), covariates_state$retail.recreation,
                                                            rep(median(covariates_state$retail.recreation[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                                for_length)),
                                    "transitstations" = c(as.integer(rep(0, num_pad)), covariates_state$transitstations, 
                                                          rep(median(covariates_state$transitstations[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                              for_length)),
                                    "workplace" = c(as.integer(rep(0, num_pad)), covariates_state$workplace, 
                                                    rep(median(covariates_state$workplace[(len_covariates-7):len_covariates], na.rm = TRUE), 
                                                        for_length)))
      
  }
  return(padded_covariates)
}

# okay
create_features <- function(len_mobility, padded_covariates, transit_usage){
    return (data.frame(
               'transit_use' = transit_usage,
               'residential' = padded_covariates$residential, 
               'transit' = padded_covariates$transitstations, 
               'grocery' = padded_covariates$grocery.pharmacy,
               'parks' = padded_covariates$parks,
               'retail' =padded_covariates$retail.recreation,
               'workplace' = padded_covariates$workplace,
               'averageMobility' = rowMeans(padded_covariates[,c("grocery.pharmacy", "retail.recreation", "workplace")], 
                                            na.rm=TRUE))
            )
}
