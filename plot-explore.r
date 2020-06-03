
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
    "Modeled_Cases",
    "Modeled_Cases_cf",
    "Reported_Cases",
    "Modeled_Deaths",
    "Modeled_Deaths_cf",
    "Reported_Deaths"
)

explore <- data.frame(matrix(0, ncol=length(exploreNames)))
colnames(explore) <- exploreNames

for(i in 1:length(countries)){

    print("--- i ---")
    print(i)

    N <- length(dates[[i]])

    # here! careful - country is an integer right here (is it? double check)
    country <- countries[[i]]

    print("--- N ---")
    print(N)

    # check
    Rt <- mean(colMeans(out$Rt[,1:N,i]))
    # check
    R0 <- mean(colMeans(out$mu))

    total_predicted_cases <- sum(colMeans(prediction[,1:N,i]))
    total_predicted_cases_cf <- sum(colMeans(out$prediction0[,1:N,i]))
    total_reported_cases <- sum(reported_cases[[i]])

    total_estimated_deaths <- sum(colMeans(estimated.deaths[,1:N,i]))
    total_estimated_deaths_cf <- sum(colMeans(estimated.deaths.cf[,1:N,i]))
    total_reported_deaths <- sum(deaths_by_country[[i]])

    # "County",
    # "Rt",
    # "R0",

    # "Modeled_Cases",
    # "Modeled_Cases_cf",
    # "Reported_Cases",

    # "Modeled_Deaths",
    # "Modeled_Deaths_cf",
    # "Reported_Deaths"

    countyStats <- c(
        country,
        Rt,
        R0,
        total_predicted_cases,
        total_predicted_cases_cf,
        total_reported_cases,
        total_estimated_deaths,
        total_estimated_deaths_cf,
        total_reported_deaths
    )

    explore <- rbind(explore, countyStats)
}

# take away initial row which is just a zero vector placeholder
explore <- explore[-1,]

print("let's take a look")
print(explore)
