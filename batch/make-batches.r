#### example calls
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35
args = commandArgs(trailingOnly=TRUE)

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

# 5 is "-maxBatchSize"
# 6 is <maxBatchSize>
maxBatchSizeFlag <- args[5]
if (maxBatchSizeFlag != "-maxBatchSize") {stop("missing -maxBatchSize flag")}
maxBatchSize <- as.integer(args[6])

print(sprintf("Only running on counties with at least %d total reported deaths", minimumReportedDeaths))
print("Only running on counties in these states:")
print(stateList)
print(sprintf("Running with max batch size: %d", maxBatchSize))

# case-mortality table
d <- read.csv("../modelInput/CaseAndMortalityV2.csv", stringsAsFactors = FALSE)

# a little preprocessing
d$date = as.Date(d$dateRep,format='%m/%d/%y')
d$countryterritoryCode <- sapply(d$countryterritoryCode, as.character)
d$countryterritoryCode <- sub("840", "", d$countryterritoryCode)

if (stateList[1] != "all") {d <- subset(d, (gsub(" ", "", state) %in% stateList))}

# drop counties with fewer than cutoff cumulative deaths or cases
cumCaseAndDeath <- aggregate(cbind(d$deaths), by=list(Category=d$countryterritoryCode), FUN=sum)
dropCounties <- subset(cumCaseAndDeath, V1 < minimumReportedDeaths)$Category
d <- subset(d, !(countryterritoryCode %in% dropCounties))
print(sprintf("nCounties with more than %d deaths: %d", minimumReportedDeaths, length(unique(d$countryterritoryCode))))

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
ordered <- cumCaseAndDeath[order(cumCaseAndDeath$V1, decreasing=TRUE),]

# make batches
batches <- list()
for (i in 1:nBatches) {
    batch <- ordered$Category[seq(i,n,nBatches)]
    batches[[i]] <- batch
}

# print("here are the batches:")
# print(batches)
# print(length(batches))
# print(sapply(batches, length))
# print(setdiff(unlist(batches), ordered$Category))

# create batches dir
batchesDir <- "../batches"
dir.create(batchesDir, showWarnings = FALSE)

print(sprintf("writing batches to dir: %s", batchesDir))

# write batches
for (i in 1:nBatches) {
    write.table(batches[[i]], file.path(batchesDir, sprintf("batch%d.txt", i)), row.names=FALSE, col.names=FALSE)
}
