
# load environment from all-IL run, post-simulation
load("./results/run_2/us_base-488236.Rdata")

# to wrangle:
# R_t (okay)
# R_0
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
explore <- melt(as.matrix(meanRt), varnames=c("", "county"), value.name="Rt")[c("county", "Rt")]

