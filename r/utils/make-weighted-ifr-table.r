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