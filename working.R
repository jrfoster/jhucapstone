setwd("c:/devR/Capstone/")
source("./Prediction.R")
dbDir <- file.path(getwd(), "sqlite", "ngrams.sqlite")
dbConn <- dbConnect(SQLite(), dbDir)
setwd(file.path(getwd(), "dsci-benchmark-master"))
source("./Benchmark.R")

