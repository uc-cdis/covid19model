
# load environment from all-IL run, post-simulation
load("./results/run_2/us_base-488236.Rdata")

# to wrangle:
# R_t (a)
# R_0 (a)
# total rCases (a)
# total cases_l (a)
# total cases_0 (a)
# total rDeaths (a)
# total deaths_l (a)
# total deaths_0 (a)
#
# very simple.

exploreNames <- c(
    "County",

    "Rt",
    "R0",
    "Prop_Reduction_in_Rt", # (R0 - Rt) / R0

    "Modeled_Cases",
    "Reported_Cases",

    "Modeled_Deaths",
    "Reported_Deaths"
)

explore <- data.frame(matrix(0, ncol=length(exploreNames)))
colnames(explore) <- exploreNames

for(i in 1:length(countries)){

    N <- length(dates[[i]])

    country <- countries[[i]]

    # check
    Rt <- mean(colMeans(out$Rt[,1:N,i]))
    # check - testing
    R0 <- mean(out$mu[,i])

    total_predicted_cases <- sum(colMeans(prediction[,1:N,i]))
    total_predicted_cases_cf <- sum(colMeans(out$prediction0[,1:N,i]))
    total_reported_cases <- sum(reported_cases[[i]])

    total_estimated_deaths <- sum(colMeans(estimated.deaths[,1:N,i]))
    total_estimated_deaths_cf <- sum(colMeans(estimated.deaths.cf[,1:N,i]))
    total_reported_deaths <- sum(deaths_by_country[[i]])

    # "County",

    # "Rt",
    # "R0",
    # "Prop_Reduction_in_Rt", # (R0 - Rt) / R0

    # "Modeled_Cases",
    # "Reported_Cases",

    # "Modeled_Deaths",
    # "Reported_Deaths"

    countyStats <- c(
        country,
        Rt,
        R0,
        (R0 - Rt) / R0,
        total_predicted_cases,
        total_reported_cases,
        total_estimated_deaths,
        total_reported_deaths
    )

    explore <- rbind(explore, countyStats)
}

# take away initial row which is just a zero vector placeholder
explore <- explore[-1,]

# separate df without cook county
exploreNoCook <- explore[explore$County != "84017031",]


## plots -> save them, name them, easily readable axes

#### distributions of interest

# Rt
# hist(as.numeric(explore$Rt), breaks=8)
# hist(as.numeric(explore$R0), breaks=8)
# hist(as.numeric(explore$Prop_Reduction_in_Rt), breaks=6)
# hist(as.numeric(explore$Diff_Rt), breaks=8)

# Reported Cases
# hist(as.numeric(exploreNoCook$Reported_Cases))
# hist(log(as.numeric(exploreNoCook$Reported_Cases)))

# Reported Deaths
# hist(as.numeric(exploreNoCook$Reported_Deaths))
# hist(log(as.numeric(exploreNoCook$Reported_Deaths)))

# Reported Deaths vs. Reported Cases
# plot(log(as.numeric(exploreNoCook$Reported_Cases)), log(as.numeric(exploreNoCook$Reported_Deaths)))

# Rt vs. Reported Deaths
# plot(exploreNoCook$Rt, log(as.numeric(exploreNoCook$Reported_Deaths)))

# Reduction in Rt vs. Reported Deaths
# plot(exploreNoCook$Prop_Reduction_in_Rt, log(as.numeric(exploreNoCook$Reported_Deaths)))

# R0 vs. Rt
# plot(explore$R0, explore$Rt)

# look at everything - should the raw numbers be logs?
# plot(exploreNoCook)
