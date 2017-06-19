require(RSQLite)
setwd("c:/devR/Capstone")
dbDir <- file.path(getwd(), "sqlite", "ngrams.sqlite")
db <- dbConnect(SQLite(), dbDir)

ngrams <- read.csv("quintagrams.csv", stringsAsFactors = FALSE)
dbWriteTable(conn = db, name = "quintagrams", value = ngrams, row.names = FALSE, append = TRUE)

ngrams <- read.csv("quadragrams.csv", stringsAsFactors = FALSE)
dbWriteTable(conn = db, name = "quadragrams", value = ngrams, row.names = FALSE, append = TRUE)

ngrams <- read.csv("trigrams.csv", stringsAsFactors = FALSE)
dbWriteTable(conn = db, name = "trigrams", value = ngrams, row.names = FALSE, append = TRUE)

ngrams <- read.csv("bigrams.csv", stringsAsFactors = FALSE)
dbWriteTable(conn = db, name = "bigrams", value = ngrams, row.names = FALSE, append = TRUE)

ngrams <- read.csv("unigrams.csv", stringsAsFactors = FALSE)
dbWriteTable(conn = db, name = "unigrams", value = ngrams, row.names = FALSE, append = TRUE)

rm(ngrams)

rs <- dbSendQuery(conn = db, "CREATE INDEX quint_idx ON quintagrams(root)")
dbClearResult(rs)

rs <- dbSendQuery(conn = db, "CREATE INDEX quad_idx ON quadragrams(root)")
dbClearResult(rs)

rs <- dbSendQuery(conn = db, "CREATE INDEX tri_idx ON trigrams(root)")
dbClearResult(rs)

rs <- dbSendQuery(conn = db, "CREATE INDEX bi_idx ON bigrams(root)")
dbClearResult(rs)

rs <- dbSendQuery(conn = db, "CREATE INDEX uni_idx ON unigrams(word)")
dbClearResult(rs)

dbDisconnect(db)
