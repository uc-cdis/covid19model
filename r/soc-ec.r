# read in soc-ec table
se <- read.csv("../modelInput/SocEc.csv", stringsAsFactors=FALSE)

# select what you want
se <- data.frame(
    fips = se$FIPS,
    state = se$State,
    area_name = se$Area_Name,    
    income = se$Median_Household_Income_2018,
    density = se$Density.per.square.mile.of.land.area...Population,
    pop = se$POP_ESTIMATE_2018,
    transit = se$transit_scores...population.weighted.averages.aggregated.from.town.city.level.to.county,
    icu_beds = se$ICU.Beds
)

# filter for IL
il <- se[se$state == "IL", ]

