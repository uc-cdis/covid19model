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

# should be fine
read_google_mobility <- function(){

  # okay
  GFNAME_states <<- "usa/data/states.csv"
  # ["state", "abbreviation"] -> don't need this : https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/data/states.csv
  states <- read.csv(GFNAME_states, stringsAsFactors = FALSE)
  names(states) <- c("sub_region_1", "code")

  # okay
  # read in IL report
  GFNAME_global_mobility_report <<- 'usa/data/Global_Mobility_Report.csv'
  google_mobility <- read.csv(GFNAME_global_mobility_report, stringsAsFactors = FALSE)
  google_mobility <- google_mobility[which(google_mobility$country_region_code == "US"),]

  # okay
  # Remove county level data # no dog
  # google_mobility <- google_mobility[which(google_mobility$sub_region_2 == ""),]
  # google_mobility <- left_join(google_mobility, states, by = c("sub_region_1"))

  # Format the google mobility data
  google_mobility$date = as.Date(google_mobility$date, format = '%Y-%m-%d')
  google_mobility[, c(6:11)] <- google_mobility[, c(6:11)]/100
  google_mobility[, c(6:10)] <- google_mobility[, c(6:10)] * -1
  names(google_mobility) <- c("country_region_code", "country_region", "sub_region_1", "sub_region_2",
                              "date", "retail.recreation", "grocery.pharmacy", "parks", "transitstations",
                              "workplace", "residential", "code")
  
  return(google_mobility)
}

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


# fixme
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

### <main>
### from: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/base-usa.r#L85-L108 ###

# Read google mobility
mobility <- read_google_mobility()

# At times google has mobility na for some days in that cae you will need to impute those values
# else code will fail 
# read predictions of future days from foursquare
# if you need predictions from foursquare please run file mobility-regression.r in
# the folder usa/code/utils/mobility-reg
google_pred <- read.csv('usa/data/google-mobility-forecast.csv', stringsAsFactors = FALSE)
google_pred$date <- as.Date(google_pred$date, format = '%Y-%m-%d') 
google_pred$country_region <- "United States"
google_pred$country_region_code <- "US"
colnames(google_pred)[colnames(google_pred) == 'state'] <- 'sub_region_1'

if (max(google_pred$date) > max(mobility$date)){

  google_pred <- google_pred[google_pred$date > max(mobility$date),]

  # reading mapping of states of csv
  un <- unique(mobility$sub_region_1)

  states_code = read.csv('usa/data/states.csv', stringsAsFactors = FALSE)
  google_pred$code = "!!"

  # m: replacing state codes with their abbreviations -> not sure we need this for counties? -> may need an analog
  for(i in 1:length(un)){
    google_pred$code[google_pred$sub_region_1==un[i]] = states_code$Abbreviation[states_code$State==un[i]]
  }

  mobility <- rbind(as.data.frame(mobility),as.data.frame(google_pred[,colnames(mobility)]))
}

## --- ##

max_date <- max(mobility$date)
death_data <- death_data[which(death_data$date <= max_date),]

# Maximum number of days to simulate (check - pretty sure this is just N2)
num_days_sim <- (max(death_data$date) - min(death_data$date) + 1)[[1]]

## need to look @ this ##
formula_partial_state = '~ -1 + averageMobility + I(transit * transit_use) + residential'

processed_data <- process_covariates(states = states, 
                                     mobility = mobility,
                                     death_data = death_data, 
                                     formula_partial_state = formula_partial_state
                                     )
stan_data <- processed_data$stan_data

dates <- processed_data$dates
reported_deaths <- processed_data$reported_deaths
reported_cases <- processed_data$reported_cases
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m <- stan_model(paste0('usa/code/stan-models/',StanModel,'.stan'))
JOBID = Sys.getenv("PBS_JOBID")
if(JOBID == "")
  JOBID = as.character(abs(round(rnorm(1) * 1000000)))
print(sprintf("Jobid = %s",JOBID))
if(DEBUG) {
  fit = sampling(m,data=stan_data,iter=40,warmup=20,chains=2)
} else if (FULL) {
  fit = sampling(m,data=stan_data,iter=1800,warmup=1000,chains=5,thin=1,control = list(adapt_delta = 0.95, max_treedepth = 15))
} else { 
  fit = sampling(m,data=stan_data,iter=100,warmup=50,chains=4,thin=1,control = list(adapt_delta = 0.95, max_treedepth = 10))
}

###
