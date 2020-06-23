library(rstan)
library(data.table)
library(lubridate)
library(gdata)
library(EnvStats)
library(tidyr)
library(stringr)
library(dplyr)

# Rscript base.r us_base 150 4000 
args = commandArgs(trailingOnly=TRUE)
StanModel = args[1]
minimumReportedDeaths = as.integer(args[2])
nStanIterations = as.integer(args[3])
print(sprintf("Running stan model %s",StanModel))
print(sprintf("Only running on counties with at least %d total reported deaths", minimumReportedDeaths))
print(sprintf("Running MCMC routine with %d iterations", nStanIterations))

## smoothing death data: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/read-data-usa.r#L37-L40
## -> https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/usa/code/utils/read-data-usa.r#L24-L27
## -> something to try, for sure

# case-mortality table
d <- read.csv("../modelInput/ILCaseAndMortalityV1.csv", stringsAsFactors = FALSE)

###
# HERE! -> specify a date through which to run the model
# i.e., specify day of last observation
# say it's June 8th, but we only want to run through June 1st, because the model hasn't been adjusted for lifting lockdown yet
# want to easily do this -> can easily do this -> just select columns with date <= target date
# something a la:
# validationObs <- countyObs[as.Date(countyObs$dateRep, format = "%m/%d/%y") > lastObs, ]
# dateCutoff <- "6/1/20"
# dateCutoff <- as.Date(dateCutoff, format = "%m/%d/%y")
# print(sprintf("date cutoff: %s",  dateCutoff))
# d <- d[as.Date(d$dateRep, format = "%m/%d/%y") <= lastObs, ]
###

d$countryterritoryCode <- sapply(d$countryterritoryCode, as.character)
# trim US code prefix
d$countryterritoryCode <- sub("840", "", d$countryterritoryCode)

# drop counties with fewer than cutoff cumulative deaths or cases
cumCaseAndDeath <- aggregate(cbind(d$deaths), by=list(Category=d$countryterritoryCode), FUN=sum)
dropCounties <- subset(cumCaseAndDeath, V1 < minimumReportedDeaths)$Category
d <- subset(d, !(countryterritoryCode %in% dropCounties))

d$date = as.Date(d$dateRep,format='%m/%d/%y')


# print(sprintf("nCounties with more than %d deaths before %s: %d", minimumReportedDeaths, dateCutoff, length(unique(d$countryterritoryCode))))
print(sprintf("nCounties with more than %d deaths: %d", minimumReportedDeaths, length(unique(d$countryterritoryCode))))

codeToName <- unique(data.frame("countyCode" = d$countryterritoryCode, "countyName" = d$countriesAndTerritories))

# write list of counties used in this simulation
CountyCodeList <- unique(d$countryterritoryCode)
write.table(CountyCodeList, "../modelOutput/figures/CountyCodeList.txt", row.names=FALSE, col.names=FALSE)

countries <- unique(d$countryterritoryCode)

# weighted fatality table
cfr.by.country = read.csv("../modelInput/ILWeightedFatalityV1.csv")
cfr.by.country$country = as.character(cfr.by.country[,3])
cfr.by.country$country <-  sub("840", "", cfr.by.country$country) # cutoff US prefix code - note: maybe this should be in the python etl, not here

# serial interval discrete gamma distribution
serial.interval = read.csv("../modelInput/ILSerialIntervalV1.csv") # new table

# interventions table 
# NOTE: "covariate" == "intervention"; 
# e.g., if there are 3 different interventions in the model, then there are 3 covariates here in the code
covariates = read.csv("../modelInput/ILInterventionsV1.csv", stringsAsFactors = FALSE)
covariates$Country <- sapply(covariates$Country, as.character)
covariates$Country <-  sub("840", "", covariates$Country) # cutoff US prefix code - note: maybe this should be in the python etl, not here

p <- ncol(covariates) - 2
forecast = 0

# N2 is Number of time points with data plus forecast
N2 = 0

# >>>>>>>>>>>>>>> MOBILITY >>>>>>>>>>>>>>> #

# Read google mobility
source("./read-mobility.r")
mobility <- read_google_mobility(countries=countries, codeToName=codeToName)

# basic impute values for NA in google mobility
# see: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/base-usa.r#L87-L88
for(i in 1:ncol(mobility)){
  if (is.numeric(mobility[,i])){
    mobility[is.na(mobility[,i]), i] <- mean(mobility[,i], na.rm = TRUE)
  }
}

# Read predicted mobility
google_pred <- read.csv('../modelInput/mobility/google-mobility-forecast.csv', stringsAsFactors = FALSE)
google_pred$date <- as.Date(google_pred$date, format = '%Y-%m-%d') 

# replicate statewide prediction by county -> this can be MUCH more nuanced, but for now - just get something working
stateAndCounty <- codeToName
stateAndCounty$state <- "Illinois"
google_pred <- left_join(stateAndCounty, google_pred, "state" = "state")
colnames(google_pred)[colnames(google_pred) == 'state'] <- 'sub_region_1'

# Append predicted mobility
if (max(google_pred$date) > max(mobility$date)){
  google_pred <- google_pred[google_pred$date > max(mobility$date),]
  mobility <- rbind(as.data.frame(mobility),as.data.frame(google_pred[,colnames(mobility)]))
}

max_date <- max(mobility$date)
d <- d[as.Date(d$dateRep, format = "%m/%d/%y") <= max_date, ]
print(sprintf("MAX DATE : %s", max_date))

## need to take a close look @ this -> looks fine ##
# see: https://stackoverflow.com/questions/8055508/in-r-formulas-why-do-i-have-to-use-the-i-function-on-power-terms-like-y-i
formula_partial_county = as.formula('~ -1 + averageMobility + I(transit * transit_use) + residential')

# <<<<<<<<<<<<<<< MOBILITY <<<<<<<<<<<<<<<<<< #

dates = list()
reported_cases = list()
deaths_by_country = list()

stan_data = list(M=length(countries),
                N=NULL, # Number of time points with data
                p=p,
                y=NULL,
                deaths=NULL,
                f=NULL,
                N0=6, # Number of days in seeding
                cases=NULL,
                LENGTHSCALE=p, # this is the number of covariates (i.e., the number of interventions)
                EpidemicStart = NULL # Date to start epidemic in each county
                )

# N2 is the length of time window to simulate
# adjust N2 before main procesesing routine - i.e., adjust N2 so that it's uniform across all counties
for(Country in countries) {

  tmp=d[d$countryterritoryCode==Country,]
  tmp$date = as.Date(tmp$dateRep,format='%m/%d/%y')
  tmp$t = decimal_date(tmp$date) 
  tmp=tmp[order(tmp$t),]

  index1 = which(cumsum(tmp$deaths)>=10)[1] 
  index2 = index1-30
  
  tmp=tmp[index2:nrow(tmp),]
  
  N = length(tmp$cases)  
  if(N2 - N < 0) {
    print(sprintf("raising N2 from %d to %d", N2, N))
    N2 = N + 7
  }
}

covariate_list_partial_county <- list()

# k is their counter
k <- 1
for(Country in countries) {

  CFR=cfr.by.country$weighted_fatality[cfr.by.country$country == Country]

  d1=d[d$countryterritoryCode==Country,]

  d1$t = decimal_date(d1$date) 
  d1=d1[order(d1$t),]

  index = which(d1$cases>0)[1]
  index1 = which(cumsum(d1$deaths)>=10)[1] 
  index2 = index1-30
  
  print(sprintf("First non-zero cases is on day %d, and 30 days before 10 cumulative deaths is day %d",index,index2))
  d1=d1[index2:nrow(d1),]
  stan_data$EpidemicStart = c(stan_data$EpidemicStart,index1+1-index2)

  # dates[[as.character(Country)]] = d1$date
  dates[[Country]] = d1$date

  # hazard estimation
  N = length(d1$cases)
  print(sprintf("%s has %d days of data",Country,N))
  
  # at least a seven day forecast 
  # testing this
  forecast <- max(N2 - N, 7)

  # fix it at 7 -> uniform forecast across counties..
  # can't do this - breaks routine as of now
  # forecast doesn't even matter at this point
  # forecast <- 7

  # >>>>>>>>>>> mobility >>>>>>>>>>>>> #

  # Selects mobility data for each county
  covariates_county <- mobility[which(mobility$countyCode == Country),]

  # Find minimum date for the data
  min_date <- min(d1$date)
  num_pad <- (min(covariates_county$date) - min_date[[1]])[[1]]
  len_mobility <- ncol(covariates_county)
    
  padded_covariates <- pad_mobility(len_mobility, num_pad, min_date, covariates_county, forecast, d1, Country)

  # include transit
  transit_usage <- rep(1, (N + forecast))

  # creating features -> only want "partial_state"
  df_features <- create_features(len_mobility, padded_covariates, transit_usage)
  features_partial_county <- model.matrix(formula_partial_county, df_features)    
  covariate_list_partial_county[[k]] <- features_partial_county

  # <<<<<<<<<<< mobility <<<<<<<<<<<<< #

  h = rep(0,forecast+N) # discrete hazard rate from time t = 1, ..., 100
  mean1 = 5.1; cv1 = 0.86; # infection to onset
  mean2 = 18.8; cv2 = 0.45 # onset to death

  # td: double check these comments
  # otherwise should be fine
  ## icl: assume that CFR is probability of dying given infection
  x1 = rgammaAlt(5e6,mean1,cv1) # icl: infection-to-onset ----> do all people who are infected get to onset?
  x2 = rgammaAlt(5e6,mean2,cv2) # icl: onset-to-death
  f = ecdf(x1+x2)

  convolution = function(u) (CFR * f(u))
  h[1] = (convolution(1.5) - convolution(0)) 
  for(i in 2:length(h)) {
    h[i] = (convolution(i+.5) - convolution(i-.5)) / (1-convolution(i-.5))
  }
  s = rep(0,N2)
  s[1] = 1 
  for(i in 2:N2) {
    s[i] = s[i-1]*(1-h[i-1])
  }

  f = s * h
  
  y=c(as.vector(as.numeric(d1$cases)),rep(-1,forecast))
  reported_cases[[Country]] = as.vector(as.numeric(d1$cases))
  deaths=c(as.vector(as.numeric(d1$deaths)),rep(-1,forecast))
  cases=c(as.vector(as.numeric(d1$cases)),rep(-1,forecast))
  deaths_by_country[[Country]] = as.vector(as.numeric(d1$deaths))

  ## icl: append data
  stan_data$N = c(stan_data$N,N)
  stan_data$y = c(stan_data$y,y[1]) # icl: just the index case!

  stan_data$x1=poly(1:N2,2)[,1]
  stan_data$x2=poly(1:N2,2)[,2]
  stan_data$SI=serial.interval$fit[1:N2]

  stan_data$f = cbind(stan_data$f,f)

  stan_data$deaths = cbind(stan_data$deaths,deaths)
  stan_data$cases = cbind(stan_data$cases,cases)
  
  stan_data$N2=N2
  stan_data$x=1:N2
  if(length(stan_data$N) == 1) {
    stan_data$N = as.array(stan_data$N)
  }

  k <- k+1
}

# >>>>>>>>>>> mobility >>>>>>>>>>>>> #

# newSTAN - ok
stan_data$P_partial_county = dim(features_partial_county)[2]
# newSTAN - ok
stan_data$X_partial_county = array(NA, dim = c(stan_data$M , stan_data$N2 ,stan_data$P_partial_county))

# NOTE: mapped *_partial_state -> *_partial_county

for (i in 1:stan_data$M){
  stan_data$X_partial_county[i,,] = covariate_list_partial_county[[i]]
}

# newSTAN - ok
stan_data$W <- ceiling(stan_data$N2/7) 
# newSTAN - ok
stan_data$week_index <- matrix(1,stan_data$M,stan_data$N2)
for(j in 1:stan_data$M) {
  stan_data$week_index[j,] <- rep(2:(stan_data$W+1),each=7)[1:stan_data$N2]
  last_ar_week = which(dates[[j]]==max(d$date) - 28)
  stan_data$week_index[j,last_ar_week:ncol(stan_data$week_index)] <-  stan_data$week_index[j,last_ar_week]
}

# <<<<<<<<<<< mobility <<<<<<<<<<<<< #

stan_data$y = t(stan_data$y)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model(paste0('../stan/',StanModel,'.stan'))

# it works!!
fit = sampling(m,data=stan_data,iter=nStanIterations,warmup=nStanIterations/2,chains=8,thin=4,control = list(adapt_delta = 0.90, max_treedepth = 10))

out = rstan::extract(fit)
prediction = out$prediction
estimated.deaths = out$E_deaths
estimated.deaths.cf = out$E_deaths0

JOBID = Sys.getenv("PBS_JOBID")
if(JOBID == "")
  JOBID = as.character(abs(round(rnorm(1) * 1000000)))
print(sprintf("Jobid = %s",JOBID))
save.image(paste0('../modelOutput/results/',StanModel,'-',JOBID,'.Rdata'))
save(fit,prediction,dates,reported_cases,deaths_by_country,countries,estimated.deaths,estimated.deaths.cf,out,covariates,file=paste0('../modelOutput/results/',StanModel,'-',JOBID,'-stanfit.Rdata'))

#### saving of simulation results is finished

#### now -> visualize model results -> ####

# fixme: don't force other scripts to load R data -> unnecessary overhead
# import viz routine, call those functions here -> way, way better
# still save the R data and fit though, for backup, etc.

filename <- paste0(StanModel, '-', JOBID)
system(paste0("Rscript plot-trend.r ", filename,'.Rdata')) 
system(paste0("Rscript plot-forecast.r ", filename,'.Rdata')) ## icl: to run this code you will need to adjust manual values of forecast required

# suppressing for now
# system(paste0("Rscript plot-explore.r ", filename,'.Rdata'))
