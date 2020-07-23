minimumReportedDeaths <- 430

# case-mortality table
d <- read.csv("../modelInput/ILCaseAndMortalityV1.csv", stringsAsFactors = FALSE)

# drop counties with fewer than cutoff cumulative deaths or cases
cumCaseAndDeath <- aggregate(cbind(d$deaths), by=list(Category=d$countryterritoryCode), FUN=sum)
dropCounties <- subset(cumCaseAndDeath, V1 < minimumReportedDeaths)$Category
d <- subset(d, !(countryterritoryCode %in% dropCounties))
# print(sprintf("nCounties with more than %d deaths before %s: %d", minimumReportedDeaths, dateCutoff, length(unique(d$countryterritoryCode))))
print(sprintf("nCounties with more than %d deaths: %d", minimumReportedDeaths, length(unique(d$countryterritoryCode))))

d$date = as.Date(d$dateRep,format='%m/%d/%y')

d$countryterritoryCode <- sapply(d$countryterritoryCode, as.character)
# trim US code prefix
d$countryterritoryCode <- sub("840", "", d$countryterritoryCode)

codeToName <- unique(data.frame("countyCode" = d$countryterritoryCode, "countyName" = d$countriesAndTerritories))

# write list of counties used in this simulation
CountyCodeList <- unique(d$countryterritoryCode)
write.table(CountyCodeList, "../modelOutput/figures/CountyCodeList.txt", row.names=FALSE, col.names=FALSE)

countries <- unique(d$countryterritoryCode)

# Read google mobility
source("./read-mobility.r")
mobility <- read_google_mobility(countries=countries, codeToName=codeToName)

# basic impute values for NA in google mobility
# see: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/base-usa.r#L87-L88
for(i in 1:ncol(mobility)){
  if (is.numeric(mobility[,i])){
    mobility[is.na(mobility[,i]), i] <- mean(mobility[,i], na.rm = TRUE)
  }
}

# un-invert the scores
mobility[5:ncol(mobility)] <- -1 * mobility[5:ncol(mobility)]

# select Cook county
cook <- mobility[mobility$countyName == "Cook", ]

## plot

library(tidyr)
library(dplyr)

df <- cook %>%
  select(date, retail.recreation, grocery.pharmacy, parks, transitstations, workplace, residential) %>%
  gather(key = "variable", value = "value", -date)

# Multiple line plot
ggplot(df, aes(x = date, y = value)) + 
  geom_line(aes(color = variable), size = 1) +
  theme_minimal()