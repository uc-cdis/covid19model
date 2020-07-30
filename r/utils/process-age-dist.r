
# read-in
raw <- read.csv("../modelInput/us-age-dist-by-county/data.csv", skip=1)

# keep only desired columns
# (use grepl)
dropCols <- list()
k <- 1
for (n in names(raw)) {
    if (grepl("male", n, ignore.case=TRUE) or grepl("error", n, ignore.case=TRUE)) {
        dropCols[[k]] <- n
        k <- k + 1
    }
}

data <- subset(raw, select = -dropCols)
