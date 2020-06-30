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

# remove all rows with any na
se <- se[complete.cases(se), ]

## normalize scores

# density
maxDensity <- max(se$density, na.rm=TRUE)
se$ndensity <- sapply(se$density, function(x) x/maxDensity)

# income
maxIncome <- max(se$income, na.rm=TRUE)
se$nincome <- sapply(se$income, function(x) x/maxIncome)

# transit
maxTransit <- max(se$transit, na.rm=TRUE)
se$ntransit <- sapply(se$transit, function(x) x/maxTransit)

# nICU beds
maxICU <-  max(se$icu_beds, na.rm=TRUE)
se$nicu_beds <- sapply(se$icu_beds, function(x) x/maxICU)

# normalized scores
ns <- data.frame(
    density=se$ndensity,
    income=se$nincome,
    transit=se$ntransit,
    icu=se$nicu_beds
)

# raw scores
rs <- data.frame(
    density=se$density,
    income=se$income,
    transity=se$transit,
    icu=se$icu_beds
)

# filter for IL
# il <- se[se$state == "IL", ]

