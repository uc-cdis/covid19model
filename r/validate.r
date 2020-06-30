# save(JOBID,
# fit,
# prediction,
# dates,
# reported_cases,
# deaths_by_country,
# countries,
# estimated.deaths,
# estimated.deaths.cf,
# out,
# lastObs,
# covariate_list_partial_county,
# file=paste0('../modelOutput/results/',StanModel,'-',JOBID,'-stanfit.Rdata'))

args <- commandArgs(trailingOnly = TRUE)
filename2 <- args[1]
load(paste0("../modelOutput/results/", filename2))
print(sprintf("loading: %s",paste0("../modelOutput/results/",filename2)))

obs <- read.csv("../modelInput/ILCaseAndMortalityV1.csv")
obs$date = as.Date(obs$dateRep,format='%m/%d/%y')
obs$countryterritoryCode <- sapply(obs$countryterritoryCode, as.character)
obs$countryterritoryCode <- sub("840", "", obs$countryterritoryCode)

l <- list()

for(i in 1:length(countries)){

    # county index
    county <- countries[[i]]
    N <- length(dates[[i]])
    countyDates <- dates[[i]]

    # last index is county
    countyForecast <- colMeans(estimated.deaths[,(N+1):N2,i])

    countyObs <- obs[obs$countryterritoryCode == county,]
    validationObs <- countyObs[countyObs$date > lastObs, ]

    # number of points for this county
    n <- min(length(countyForecast), nrow(validationObs))

    vdf <- data.frame("date"=validationObs$dateRep[1:n], "obs"=validationObs$deaths[1:n], "pred"=countyForecast[1:n])
    vdf$county <- county

    l[[i]] <- vdf
} 

fullSet <- do.call(rbind, l)

# number of points 
pts <- nrow(fullSet)

# compute the score
correlationScore <- cor(fullSet$pred, fullSet$obs)

print(sprintf("number of dates: %d", n))
print(sprintf("number of counties: %d", length(countries)))
print(sprintf("number of points: %d", pts))
print(sprintf("correlation: %f", correlationScore))

outDir <- file.path("../modelOutput/validation", JOBID)
dir.create(outDir, showWarnings = FALSE)

## fix this writing scheme
# look at it
png(filename=file.path(outDir, "v.png"), width=1600, height=1600, units="px", pointsize=36)
plot(fullSet$obs, fullSet$pred, sub=sprintf("correlation: %f", correlationScore))
dev.off()

png(filename=file.path(outDir, "v_log.png"), width=1600, height=1600, units="px", pointsize=36)
plot(log(fullSet$obs), log(fullSet$pred), sub=sprintf("correlation: %f", correlationScore))
dev.off()