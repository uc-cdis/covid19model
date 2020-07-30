convertCode <- function(code) {
  s <- as.character(code)
  short <- 5 - nchar(s)
  out <- paste(c(rep("0",short),s), collapse="")
  return(out)
}

ages <- read.csv("../../modelInput/AgeDistributions.csv")

ages$countyCode <- sapply(ages$countyCode, convertCode)

dropCols <- list()
k <- 1
for (n in names(ages)){
    if (!grepl("percent", n, ignore.case=TRUE) & (n != "countyCode")) {
        dropCols[k] <- n
        k <- k + 1
    }
}
freq <- ages[,!names(ages) %in% dropCols]

# need to bring in leveled IFR
# match age brackets
# weighted sum to get weighted IFR

# 1. IFR by age, from Imperial College London's Report 9
# https://www.imperial.ac.uk/media/imperial-college/medicine/mrc-gida/2020-03-16-COVID19-Report-9.pdf
# Table 1

ageBrackets <- c(
    "0-9",
    "10-19",
    "20-29",
    "30-39",
    "40-49",
    "50-59",
    "60-69",
    "70-79",
    "80+"
)

ifr <- c(
    .00002,
    .00006,
    .0003,
    .0008,
    .0015,
    .0060,
    .022,
    .051,
    .093
)

ifrByAge <- data.frame(age=ageBrackets, ifr=ifr)

# 2. collapse age brackets of age dist data 
ageByCounty <- as.data.frame(sapply(seq(3,ncol(freq),by=2), function(i) (freq[,i-1] + freq[,i]) / 100))
colnames(ageByCounty) <- ageBrackets
ageByCounty$countyCode <- freq$countyCode
ageByCounty <- ageByCounty[, c("countyCode",colnames(ageByCounty)[1:ncol(ageByCounty)-1])]

# 3. compute weighted fatality by county

computeWeightedIFR <- function(i) {
    weightedIFR <- 0
    for (b in ifrByAge$age) {
        ageIFR <- ifrByAge$ifr[ifrByAge$age == b]
        ageFreq <- ageByCounty[i,colnames(ageByCounty)==b]
        weightedIFR <- weightedIFR + (ageIFR * ageFreq)
    }
    return(weightedIFR)
}

ageByCounty$weighted_fatality <- sapply(seq(1,nrow(ageByCounty)), computeWeightedIFR)

# for reference
nul <- '''
> head(ageByCounty)
  countyCode   0-9 10-19 20-29 30-39 40-49 50-59 60-69 70-79   80+
1      01117 0.116 0.135 0.122 0.120 0.158 0.130 0.119 0.068 0.031
2      01121 0.111 0.131 0.122 0.113 0.134 0.132 0.133 0.084 0.040
3      01125 0.112 0.167 0.176 0.132 0.112 0.111 0.102 0.062 0.025
...
> ifrByAge
    age     ifr
1   0-9 0.00002
2 10-19 0.00006
3 20-29 0.00030
4 30-39 0.00080
5 40-49 0.00150
6 50-59 0.00600
7 60-69 0.02200
8 70-79 0.05100
9   80+ 0.09300
'''

# 4. write table
weightedIFRTable <- subset(ageByCounty, select=c(countyCode, weighted_fatality))
write.table(weightedIFRTable, path="../../modelInput/USAWeightedFatalityV2.csv", sep=",")