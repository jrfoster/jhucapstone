require(RSQLite)
setwd("c:/devR/Capstone")
dbDir <- file.path(getwd(), "sqlite", "ngrams.sqlite")
db <- dbConnect(SQLite(), dbDir)
dbSendQuery(conn = db,
            "CREATE TABLE quintagrams (
              root TEXT NOT NULL,
              word TEXT NOT NULL,
              frequency INTEGER NOT NULL,
              PRIMARY KEY(root, word)) 
            WITHOUT ROWID;

            CREATE INDEX quint_idx ON quintagrams(root);

            CREATE TABLE quadragrams (
              root TEXT NOT NULL,
              word TEXT NOT NULL,
              frequency INTEGER NOT NULL,
              PRIMARY KEY(root, word)) 
            WITHOUT ROWID;

            CREATE INDEX quad_idx ON quadragrams(root);

            CREATE TABLE trigrams (
              root TEXT NOT NULL,
              word TEXT NOT NULL,
              frequency INTEGER NOT NULL,
              PRIMARY KEY(root, word)) 
            WITHOUT ROWID;

            CREATE INDEX tri_idx ON trigrams(root);

            CREATE TABLE bigrams (
              root TEXT NOT NULL,
              word TEXT NOT NULL,
              frequency INTEGER NOT NULL,
              PRIMARY KEY(root, word)) 
            WITHOUT ROWID;

            CREATE INDEX bi_idx ON bigrams(root);

            CREATE TABLE unigrams (
              word TEXT NOT NULL,
              frequency INTEGER NOT NULL,
              PRIMARY KEY(word)) 
            WITHOUT ROWID;

            CREATE UNIQUE INDEX uni_idx ON unigrams(word);")

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
dbDisconnect(db)
