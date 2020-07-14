# read in google mobility data
m <- read.csv("../modelInput/mobility/Global_Mobility_Report.csv", stringsAsFactors=FALSE)

# select just Illinois
m <- m[m$sub_region_1 == "Illinois" & m$sub_region_2 != "", ]

# remove unnecessary columns
m <- subset(m, select = -c(country_region_code, country_region, sub_region_2, iso_3166_2_code, census_fips_code))

# must handle NA values before aggregating

# collapse county-level (via mean) to get state-level mobility scores
ilm <- aggregate(m[,3:ncol(m)], by=list(sub_region_1=m$sub_region_1), FUN=mean)
