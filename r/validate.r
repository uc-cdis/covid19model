# save(fit,
# prediction,
# dates,
# reported_cases,
# deaths_by_country,
# countries,
# estimated.deaths,
# estimated.deaths.cf,
# out,
# covariates,file=paste0('../modelOutput/results/',StanModel,'-',JOBID,'-stanfit.Rdata'))

# ../modelOutput/results/nine_county_big/us_base-606037-stanfit.Rdata

load("../modelOutput/results/nine_county_big/us_base-606037.Rdata")

# county index
i <- 4

N <- length(dates[[i]])

lastObs <- tail(dates[[i]], 1)

# last index is county
estimated_deaths_forecast <- colMeans(estimated.deaths[,1:N2,i])[N:N2]


# print("estimated deaths for one county:")
# print(dim(estimated_deaths))
# print(head(estimated_deaths))

obs <- read.csv("../modelInput/ILCaseAndMortalityV1.csv")

# print("observations:")
# print(dim(obs))
# print(head(obs))

