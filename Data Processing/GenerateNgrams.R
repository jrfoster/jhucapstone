source("../Shared/Common.R")

assertData <- function() {
  dataDir <- file.path(getwd(), "Coursera-SwiftKey", "final", "en_US")
  if (!file.exists(file.path(dataDir, "en_US.blogs.txt")) ||
      !file.exists(file.path(dataDir, "en_US.news.txt")) ||
      !file.exists(file.path(dataDir, "en_US.twitter.txt"))) {
    if (!file.exists(file.path(getwd(), "Coursera-SwiftKey.zip"))) {
      download.file("https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip", 
        destfile = "Coursera-SwiftKey.zip")
    }
    unzip("Coursera-SwiftKey.zip", exdir = "Coursera-SwiftKey", overwrite = TRUE)
    file.remove("Coursera-SwiftKey.zip")
  }
}

assertOutputDir <- function(folder) {
  if (!dir.exists(folder)) {
    dir.create(folder, recursive=TRUE)
  }
}

readText <- function(filepath) {
  connection <- file(filepath, open = "rb")
  on.exit(close(connection))
  
  # Two notes here, we use "rb" because there is a substitute character in the twitter 
  # file and we skip null because each file has one line that contains null characters
  data <- readLines(con = connection, encoding = "UTF-8", skipNul = TRUE)
  data
}

ngram_map <- function(range, rank) {
  retVal <- data.table(ngram = character(), count = integer())
  for (i in range) {
    sentences <- tokenize(myCorp$documents$texts[i], what="sentence")
    for (j in 1:length(sentences[[1]])) {
      target <- preWash(sentences[[1]][[j]])
      tokens <- tokenize(char_tolower(target), what="word", ngrams=rank,
                         remove_numbers = TRUE, 
                         remove_punct = TRUE, 
                         remove_symbols = TRUE, 
                         remove_separators = TRUE, 
                         remove_twitter = TRUE, 
                         remove_hyphens = TRUE,
                         remove_url = TRUE, simplify=TRUE)
      df <- data.table(ngram = tokens, count = rep(1, length(tokens)), stringsAsFactors = FALSE)
      retVal <- bind_rows(retVal, df)
    }
  }

  retVal <- retVal %>%
    group_by(ngram) %>%
    summarize(count = sum(count))

  retVal
}

load_data <- function(path) { 
  files <- dir(path, pattern = '\\.csv', full.names = TRUE)
  tables <- lapply(files, read.csv, stringsAsFactors=FALSE)
  bind_rows(tables)
}

createNGrams <- function(folder, ngram=1, chunkSize=1000) {
  # This is essentailly the "map" step where we generate ngrams for a chunk of the corpus at a time
  outDir <- file.path(getwd(), folder)
  assertOutputDir(outDir)
  numChunk <- ceiling(nrow(myCorp$documents) / chunkSize) - 1
  pos <- 1
  for (i in 0:numChunk) {
    size <- min(chunkSize, nrow(myCorp$documents) - i * chunkSize)
    r = seq(pos, (pos+size-1))
    n = ngram_map(range=r, rank=ngram)
    print(paste(min(r),":",max(r)))
    fwrite(n, file.path(outDir,paste("chunk_",i,".csv", sep="")))
    pos <- pos + chunkSize
  }
  
  # This is the "reduce" step where all the ngrams get collected into a single set and persisted
  # Note that we are only interested in creating the combined set of ngram csv files, they will
  # be combined by a database step later in the process
  combined <- load_data(outDir)
  fwrite(combined, file.path(outDir, "combined.csv"), buffMB = 13, nThread=13)  
}
###################################################################################################################
assertPackage("quanteda")
assertPackage("data.table")
assertPackage("dplyr")

setwd("c:/devr/capstone")

assertData()

dataDir <- file.path(getwd(), "Coursera-SwiftKey", "final", "en_US")

# Reproducability
set.seed(13031)

# Create a random sample of about 1/4 of the data in each of the sets using rbinom
blog <- readText(file.path(dataDir, "en_US.blogs.txt"))
blogIn <- rbinom(n=length(blog), size=1, prob=.75)
blogSample <- blog[blogIn == 1]

news <- readText(file.path(dataDir, "en_US.news.txt"))
newsIn <- rbinom(n=length(news), size=1, prob=.75)
newsSample <- news[newsIn == 1]

twtr <- readText(file.path(dataDir, "en_US.twitter.txt"))
twtrIn <- rbinom(n=length(twtr), size=1, prob=.25)
twtrSample <- twtr[twtrIn == 1]

# Load the samples into a corpus
myCorp <- corpus(c(blogSample,newsSample,twtrSample))

# Clean up some items from memory 
rm(blog)
rm(blogIn)
rm(blogSample)
rm(news)
rm(newsIn)
rm(newsSample)
rm(twtr)
rm(twtrSample)
rm(twtrIn)
rm(dataDir)

# gc a few times to recapture that memory
for (i in 1:10) {
  ignored <- gc()
}
rm(ignored)
rm(i)

# Create all the ngrams from the corpus. Note that this step will produce files with the combined set
# of ngrams and will therefore contain duplicates. The actual "reduce step will be performed outside
# R in SQL Server because of size and speed considerations in the generation of all these ngrams.
# Note that this process from start to finish took approximately 12 hours to complete
createNGrams(folder = "final/unigrams", ngram = 1, chunkSize = 1000)
createNGrams(folder = "final/bigrams", ngram = 2, chunkSize = 1000)
createNGrams(folder = "final/trigrams", ngram = 3, chunkSize = 1000)
createNGrams(folder = "final/quadragrams", ngram = 4, chunkSize = 1000)
createNGrams(folder = "final/quintagrams", ngram = 5, chunkSize = 1000)

