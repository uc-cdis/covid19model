
# load environment from all-IL run, post-simulation
load("./results/run_2/us_base-488236.Rdata")

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
        log(total_predicted_cases),
        log(total_reported_cases),
        log(total_estimated_deaths),
        log(total_reported_deaths)
    )

    explore <- rbind(explore, countyStats)
}

# take away initial row which is just a zero vector placeholder
explore <- explore[-1,]

# separate df without cook county
exploreNoCook <- explore[explore$County != "84017031",]

# remove county column (it's not a variable)
explore$County <- NULL
exploreNoCook$County <- NULL

## plots -> save them, name them, easily readable axes

# look at everything 
png(filename="./explorePlots/allVars.png", width=1600, height=1600, units="px", pointsize=24)
plot(exploreNoCook)
dev.off()

#### distributions of interest

# Rt
# hist(as.numeric(explore$Rt), breaks=8)
# hist(as.numeric(explore$R0), breaks=8)
# hist(as.numeric(explore$Prop_Reduction_in_Rt), breaks=6)

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


