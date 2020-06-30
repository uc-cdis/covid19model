# read in soc-ec table
se <- read.csv("../modelInput/SocEc.csv", stringsAsFactors=FALSE)

# select what you want
se <- data.frame(
    fips = se$FIPS,
    state = se$State,
    area_name = se$Area_Name,   
    pop = se$POP_ESTIMATE_2018,
    ## vars ##     
    # income 
    income = se$Median_Household_Income_2018,
    # density
    density = se$Density.per.square.mile.of.land.area...Population,
    # transit
    transit = se$transit_scores...population.weighted.averages.aggregated.from.town.city.level.to.county,
    # nICU beds
    icu_beds = se$ICU.Beds
)

## normalize scores

# density
maxDensity <- max(se$density, na.rm=TRUE)
se$ndensity <- lapply(se$density, function(x) x/maxDensity)

# income
maxIncome <- max(se$income, na.rm=TRUE)
se$nincome <- lapply(se$income, function(x) x/maxIncome)

# transit
maxTransit <- max(se$transit, na.rm=TRUE)
se$ntransit <- lapply(se$transit, function(x) x/maxTransit)

# nICU beds
maxICU <-  max(se$icu_beds, na.rm=TRUE)
se$nicu_beds <- lapply(se$icu_beds, function(x) x/maxICU)

normalScores <- data.frame(
    density=se$ndensity,
    income=se$nincome,
    transit=se$ntransit,
    icu=se$nicu_beds
)

# filter for IL
# il <- se[se$state == "IL", ]

