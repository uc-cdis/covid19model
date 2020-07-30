
# read-in
raw <- read.csv("../modelInput/us-age-dist-by-county/data.csv", skip=1)

# keep only desired columns
# (use grepl)
dropCols <- list()
k <- 1
for (n in names(raw)) {
    if (grepl("male", n, ignore.case=TRUE) | 
        grepl("error", n, ignore.case=TRUE) |
        grepl("selected", n, ignore.case=TRUE) |
        grepl("summary", n, ignore.case=TRUE) |
        grepl("geographic", n, ignore.case=TRUE) |
        grepl("allocated", n, ignore.case=TRUE) |
        (n == "Estimate..Percent..Total.population")) {
            dropCols[[k]] <- n
            k <- k + 1
    }
}

data <- raw[, !(names(raw) %in% dropCols)]

# note: last 5 digits of "id" col is the census FIPS county code

colnames(data) <- sub("Estimate..Total..Total.population..AGE..", "total.", colnames(data))
colnames(data) <- sub("Estimate..Percent..Total.population..AGE..", "percent.", colnames(data))
colnames(data) <- sub("Estimate..Total..Total.population", "population", colnames(data))