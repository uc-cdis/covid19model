
# load environment from all-IL run, post-simulation
load("./results/run_2/us_base-488236.Rdata")

# to wrangle:
# R_t (okay)
# R_0 (okay)
# total rCases
# total cases_l
# total cases_0
# total rDeaths
# total deaths_l
# total deaths_0
#
# very simple.

# 1. get Rt
dimensions <- dim(out$Rt)
Rt <- (as.matrix(out$Rt[,dimensions[2],]))
meanRt <- as.data.frame.list(colMeans(Rt))
colnames(meanRt) <- countries

# 2. start build main exploratory dataframe
library(reshape2)
explore <- melt(as.matrix(meanRt), varnames=c("", "county"), value.name="Rt")[c("county", "Rt")]

# 3. get R0 (aka mu)
mu = (as.matrix(out$mu))
meanMu <- as.data.frame.list(colMeans(mu))
colnames(meanMu) <- countries
# bind to main df
explore <- cbind(explore,R0=t(meanMu))

# 4. 

