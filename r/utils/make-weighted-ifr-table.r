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

# for reference
print('''
> names(freq)
 [1] "countyCode"                "percent.Under.5.years"    
 [3] "percent.5.to.9.years"      "percent.10.to.14.years"   
 [5] "percent.15.to.19.years"    "percent.20.to.24.years"   
 [7] "percent.25.to.29.years"    "percent.30.to.34.years"   
 [9] "percent.35.to.39.years"    "percent.40.to.44.years"   
[11] "percent.45.to.49.years"    "percent.50.to.54.years"   
[13] "percent.55.to.59.years"    "percent.60.to.64.years"   
[15] "percent.65.to.69.years"    "percent.70.to.74.years"   
[17] "percent.75.to.79.years"    "percent.80.to.84.years"   
[19] "percent.85.years.and.over"
''')