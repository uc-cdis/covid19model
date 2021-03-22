#### example calls
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35
args <- commandArgs(trailingOnly = TRUE)

# 1 is "-stateList"
# 2 is <stateList_csv>
stateListFlag <- args[1]
if (stateListFlag != "-stateList") {
  stop("missing -stateList flag")
}
stateList <- as.list(strsplit(args[2], ",")[[1]])

# 3 is "-deathsCutoff"
# 4 is <deathsCutoff>
cutoffFlag <- args[3]
if (cutoffFlag != "-deathsCutoff") {
  stop("missing -deathsCutoff flag")
}
minimumReportedDeaths <- as.integer(args[4])

# 5 is "-maxBatchSize"
# 6 is <maxBatchSize>
maxBatchSizeFlag <- args[5]
if (maxBatchSizeFlag != "-maxBatchSize") {
  stop("missing -maxBatchSize flag")
}
maxBatchSize <- as.integer(args[6])

# 7 is "-outDir"
# 8 is <outDir>
outDirFlag <- args[7]
if (outDirFlag != "-outDir") {
  stop("missing -outDir flag")
}
outDir <- args[8]

# create batches dir
dir.create(outDir, showWarnings = FALSE)
print(sprintf("writing batches to dir: %s", outDir))

print(sprintf("Only running on counties with at least %d total reported deaths", minimumReportedDeaths))
print("Only running on counties in these states:")
print(stateList)
print(sprintf("Running with max batch size: %d", maxBatchSize))

# case-mortality table
d <- read.csv("../modelInput/CaseAndMortalityV2.csv", stringsAsFactors = FALSE)

# a little preprocessing
d$date <- as.Date(d$dateRep, format = "%m/%d/%y")
d$countryterritoryCode <- sapply(d$countryterritoryCode, as.character)
d$countryterritoryCode <- sub("840", "", d$countryterritoryCode)

# create useful mapping tables
codeToName <- unique(data.frame("countyCode" = d$countryterritoryCode, "countyName" = d$countriesAndTerritories))
codeToNameAndState <- unique(data.frame("countyCode" = d$countryterritoryCode, "countyName" = d$countriesAndTerritories, "state" = d$state))

convertCode <- function(code) {
  s <- as.character(code)
  short <- 5 - nchar(s)
  out <- paste(c(rep("0", short), s), collapse = "")
  return(out)
}

if (stateList[1] != "all") {
  d <- subset(d, (gsub(" ", "", state) %in% stateList))
}

# >>>>>>>>>>>>>>> MOBILITY >>>>>>>>>>>>>>> #

# Read google mobility
source("../r/read-mobility.r")
mobility <- read_google_mobility(countries = unique(d$countryterritoryCode), codeToName = codeToName)

# basic impute values for NA in google mobility
# see: https://github.com/ImperialCollegeLondon/covid19model/blob/v6.0/base-usa.r#L87-L88
for (i in 1:ncol(mobility)) {
  if (is.numeric(mobility[, i])) {
    mobility[is.na(mobility[, i]), i] <- mean(mobility[, i], na.rm = TRUE)
  }
}

# Read predicted mobility
google_pred <- read.csv("../modelInput/mobility/google-mobility-forecast.csv", stringsAsFactors = FALSE)
google_pred$date <- as.Date(google_pred$date, format = "%Y-%m-%d")

# replicate statewide prediction by county -> this can be MUCH more nuanced, but for now - just get something working
stateAndCounty <- codeToNameAndState
google_pred <- left_join(stateAndCounty, google_pred, "state" = "state")
colnames(google_pred)[colnames(google_pred) == "state"] <- "sub_region_1"

max_date <- max(mobility$date)
lastObs <- max_date
print(sprintf("MAX DATE : %s", lastObs))

d <- d[as.Date(d$dateRep, format = "%m/%d/%y") <= lastObs, ]

##################

# drop counties with fewer than cutoff cumulative deaths or cases
cumCaseAndDeath <- aggregate(cbind(d$deaths), by = list(Category = d$countryterritoryCode), FUN = sum)
dropCounties <- subset(cumCaseAndDeath, V1 < minimumReportedDeaths)$Category
d <- subset(d, !(countryterritoryCode %in% dropCounties))
print(sprintf("nCounties with more than %d deaths: %d", minimumReportedDeaths, length(unique(d$countryterritoryCode))))

# write list of counties used in this simulation
CountyCodeList <- unique(d$countryterritoryCode)
write.table(CountyCodeList, "../modelOutput/CountyCodeList.txt", row.names = FALSE, col.names = FALSE)

# compute batchSize and nBatches
# balance: aim for a batch size less than but close to maxBatchSize
n <- length(unique(d$countryterritoryCode))
divisors <- seq(1:200)
batchSizes <- n %/% divisors
nBatches <- which(batchSizes <= maxBatchSize)[1]
batchSize <- batchSizes[nBatches]

print(sprintf("computed batchSize: %d", batchSize))
print(sprintf("computed nBatches: %d", nBatches))

# order counties by amount of data (i.e., total number of deaths)
ordered <- cumCaseAndDeath[order(cumCaseAndDeath$V1, decreasing = TRUE), ]

# make batches
batches <- list()
for (i in 1:nBatches) {
  batch <- ordered$Category[seq(i, n, nBatches)]
  batches[[i]] <- paste(batch, collapse = ",") # "id1,id2,...,idj"
}

# print("here are the batches:")
# print(batches)
# print(length(batches))
# print(sapply(batches, length))
# print(setdiff(unlist(batches), ordered$Category))

# write batches
for (i in 1:nBatches) {
  f <- file(file.path(outDir, sprintf("batch%d.txt", i)))
  writeLines(c(batches[[i]]), f)
  close(f)
}

print("wrote these batches:")
print(list.files(outDir))
