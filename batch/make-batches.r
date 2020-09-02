# library(data.table)
library(lubridate)
# library(gdata)
# library(EnvStats)
library(tidyr)
library(stringr)
library(dplyr)
library(jsonlite)

#### example calls
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 10 -batchSize 30
# Rscript make-batches.r -stateList "all" -batchSize 30
args = commandArgs(trailingOnly=TRUE)
# nStanIterations = as.integer(args[3])

# 1 is "-stateList"
# 2 is <stateList_csv>
stateListFlag <- args[1]
if (stateListFlag != "-stateList") {stop("missing -stateList flag")}
stateList <- as.list(strsplit(args[2], ",")[[1]])

# 3 is "-deathsCutoff"
# 4 is <deathsCutoff>
cutoffFlag <- args[3]
if (cutoffFlag != "-deathsCutoff") {stop("missing -deathsCutoff flag")}
minimumReportedDeaths <- as.integer(args[4])

# 5 is "-batchSize"
# 6 is <batchSize>
batchSizeFlag <- args[5]
if (batchSizeFlag != "-batchSize") {stop("missing -batchSize flag")}
batchSize <- as.integer(args[6])

print(sprintf("Only running on counties with at least %d total reported deaths", minimumReportedDeaths))
print("Only running on counties in these states:")
print(stateList)
print(sprintf("Running with batch size: %d", batchSize))

# fixme: almost certain this dep can be removed
# library(zoo)

# case-mortality table
d <- read.csv("../modelInput/CaseAndMortalityV2.csv", stringsAsFactors = FALSE)

# a little preprocessing
d$date = as.Date(d$dateRep,format='%m/%d/%y')
d$countryterritoryCode <- sapply(d$countryterritoryCode, as.character)
# trim US code prefix
d$countryterritoryCode <- sub("840", "", d$countryterritoryCode)

if (stateList[1] != "all") {d <- subset(d, (gsub(" ", "", state) %in% stateList))}

# drop counties with fewer than cutoff cumulative deaths or cases
cumCaseAndDeath <- aggregate(cbind(d$deaths), by=list(Category=d$countryterritoryCode), FUN=sum)
dropCounties <- subset(cumCaseAndDeath, V1 < minimumReportedDeaths)$Category
d <- subset(d, !(countryterritoryCode %in% dropCounties))
print(sprintf("nCounties with more than %d deaths: %d", minimumReportedDeaths, length(unique(d$countryterritoryCode))))

#### here! already filtered by state and deaths cutoff
#### now just need to 1. order by deaths 2. make batches 

# write list of counties used in this simulation
# CountyCodeList <- unique(d$countryterritoryCode)
# write.table(CountyCodeList, "../modelOutput/figures/CountyCodeList.txt", row.names=FALSE, col.names=FALSE)
