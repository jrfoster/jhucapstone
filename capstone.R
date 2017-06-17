library(tm)
library(filehash)

setwd("C:/DevR/Capstone/")

c <- VCorpus(DirSource("c:/DevR/Capstone/Coursera-SwiftKey/final/en_US/"), 
            readerControl = list(reader = readPlain, language = "en_US", load = TRUE),
            dbControl = list(useDb = TRUE, dbName = "nbtdb", dbType = "DB1"))
