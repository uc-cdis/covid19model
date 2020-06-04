
# load environment from all-IL run, post-simulation
# load("./results/run_2/us_base-488236.Rdata") # -> prev - 4000 iterations
load("./results/big_sim/us_base-2225348.Rdata") # 8000 iterations ("big sim")

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
## todo: work out size/resolution issues

# look at everything 
png(filename="./explorePlots/allVars.png", width=1600, height=1600, units="px", pointsize=24)
plot(exploreNoCook)
dev.off()

#### distributions of interest

# NOTE: make it clear in each diagram if cook county is included or not
# assume cook county is included
# if exluded - explicitly state this in the title
# NOTE: I haven't done this yet

# Rt
hist(as.numeric(explore$Rt), breaks=8, main="Rt", xlab="Rt")
hist(as.numeric(explore$R0), breaks=8, main="R0", xlab="R0")
hist(as.numeric(explore$Prop_Reduction_in_Rt), main="Reduction in Rt", xlab="Reduction in Rt")

# Reported Cases
hist(as.numeric(exploreNoCook$Reported_Cases), main="log(Reported Cases)", xlab="log(Reported Cases)")
hist(exp(as.numeric(exploreNoCook$Reported_Cases)), main="Reported Cases", xlab="Reported Cases")

# Reported Deaths
hist(as.numeric(exploreNoCook$Reported_Deaths), main="log(Reported Deaths)", xlab="log(Reported Deaths)")
hist(exp(as.numeric(exploreNoCook$Reported_Deaths)), main="Reported Deaths", xlab="Reported Deaths")

# Reported Deaths vs. Reported Cases
# y is reported deaths -> "x vs. y"
plot(exploreNoCook$Reported_Cases, exploreNoCook$Reported_Deaths, 
    main="Reported Deaths vs. Reported Cases",
    xlab="log(Reported Cases)", ylab="log(Reported Deaths)")

# Rt vs. Reported Deaths
plot(exploreNoCook$Rt, exploreNoCook$Reported_Deaths,
    main="Reported Deaths vs. Rt",
    xlab="Rt", ylab="log(Reported Deaths)")

# R0 vs. Rt
plot(explore$R0, explore$Rt, main="Rt vs. R0", xlab="R0", ylab="Rt")


