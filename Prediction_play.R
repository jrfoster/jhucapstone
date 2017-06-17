require(RSQLite)
require(quanteda)
require(dplyr)
require(data.table)

getConnection <- function() {
  ##################################################################################
  # Creates and returns a new connection to the project database (SQLite)
  #
  # Returns: 
  #   An object that extends DBIConnection representing the connectino to SQLite
  ##################################################################################
  db <- dbConnect(SQLite(), "./sqlite/ngrams.sqlite")
  db
}

preWash <- function(x) {
  ##################################################################################
  # Removes and replaces some unwanted characters in the input string to help ensure
  # that what gets queried for and used in predictions matches the text in the corpus
  #
  # Args:
  #   x: text to be scrubbed
  # 
  # Returns: 
  #   A scrubbed string
  ##################################################################################
  x <- gsub("[,]", " ", x)
  x <- iconv(x, "UTF-8", "ASCII", sub=" ")
  x <- gsub("[_]", "", x)
  x <- gsub("'", "''", x)
  
}

tokenizeInput <- function(phrase) {
  ##################################################################################
  # Uses the Quanteda tokenizer to tokenize an input string. Note that this performs
  # a 'word' tokenization and does not take into account multiple sentences in the
  # input text. The method assumes short phrases will be passed as input and isn't
  # meant to be a general purpose wrapper for the Quanteda tokenizer but rather a
  # convenience method to support the UI.
  #
  # Args:
  #   phrase: text to be tokenized
  # 
  # Returns: 
  #   A list of length 1 of the tokens found in the input text
  ##################################################################################
  phrase <- preWash(phrase)
  tokens <- tokenize(char_tolower(phrase),
                     remove_numbers = TRUE, 
                     remove_punct = TRUE, 
                     remove_symbols = TRUE, 
                     remove_separators = TRUE, 
                     remove_twitter = TRUE, 
                     remove_hyphens = TRUE,
                     remove_url = TRUE)
  tokens
}

getBaseQueryFor <- function(table) {
  ##################################################################################
  # Convenience method to create a base query to locate an ngram from one of the
  # ngram tables in SQLite.
  #
  # Args:
  #   table: table name to use in the from clause of the sql query. no validation
  #          is performed by this method on the table name
  # 
  # Returns: 
  #   A string containing the base select, from and where clause to find an ngram
  ##################################################################################
  qry <- paste("select word, frequency from", table, "where root =")
  qry
}

getPatternFor <- function(tokens, num) {
  ##################################################################################
  # Convenience method to create the ngram 'root' pattern, which is essentially the
  # first n-1 words of an n-gram joined with underscores.
  #
  # Args:
  #   tokens: a list of previously tokenized text, assumed to be of length 1
  #      num: the number of tokens to join together to form the pattern   
  # 
  # Returns: 
  #   A string the joined tokens 
  ##################################################################################
  ptrn <- paste(tail(tokens[[1]], num), collapse="_")
  ptrn
}

buildNgramQuery <- function(table, tokens, num) {
  ##################################################################################
  # Main method for constructing a complete SQL query to extract ngrams from tables
  # in the project SQLite database
  #
  # Args:
  #   table: table name to use in the from clause of the sql query. no validation
  #          is performed by this method on the table name
  #  tokens: a list of previously tokenized text, assumed to be of length 1
  #     num: the number of tokens to join together to form the pattern   
  # 
  # Returns: 
  #   A valid sql query to pull ngrams from the target table 
  ##################################################################################
  stopifnot(is.list(tokens))
  stopifnot(num > 0 && num < 6)
  qry <- paste(getBaseQueryFor(table), "'", getPatternFor(tokens, num), "' order by frequency desc limit 5", sep = "")
  qry
}

getNextWord <- function(phrase) {
  ##################################################################################
  # Predicts the next word based on a string of input characters and returns the top
  # three predictions. This method employes the "Stupid Backoff" method for smoothing
  #
  # Args:
  #    conn: the databse connection to use for queries
  #   phrase: text to be used as the basis of the prediction
  #
  # Returns: 
  #   A dataframe with three rows representing the top three predictions 
  ##################################################################################
  if (!exists("dbConn") || !dbIsValid(dbConn)) {
    dbConn <- getConnection()
  }
  
  if (is.null(phrase) || trimws(phrase) == "") {
    scores <- dbGetQuery(conn = dbConn, "select word, frequency from unigrams order by frequency desc limit 3")
    return(scores[1:3,1])
  }
  
  tokens <- tokenizeInput(phrase)
  
  if (length(tokens[[1]]) == 0) {
    scores <- dbGetQuery(conn = dbConn, "select word, frequency from unigrams order by frequency desc limit 3")
    return(scores[1:3,1])
  }
  
  # Initialize the dataframes the routine will use
  scores <- data.table(word = character(), score = numeric(), stringsAsFactors = FALSE)
  quintRs <- quadRs <- triRs <- biRs <- uniRs <- data.table(ngram = character(), frequency = integer(), stringsAsFactors = FALSE)
  
  # Run queries based on the number of input tokens. This is micro-optimized to prevent
  # unnecessary checks of the length of the tokens
  if (length(tokens[[1]]) > 0) {
    uniRs <- dbGetQuery(conn = dbConn, paste("select word, frequency, 1 from unigrams where word = '", tail(tokens[[1]], 1), "'", sep=""))
    if (length(tokens[[1]]) >= 1) {
      biRs <- dbGetQuery(conn = dbConn, buildNgramQuery("bigrams", tokens, 1))
      r <- biRs %>%
        mutate(score = .064 * frequency / uniRs$frequency) %>%
        select(word, score)
      scores <- bind_rows(scores, r)
      if (length(tokens[[1]]) >= 2) {
        triRs <- dbGetQuery(conn = dbConn, buildNgramQuery("trigrams", tokens, 2))
        r <- triRs %>%
          mutate(score = .16 * frequency / nrow(biRs)) %>%
          select(word, score)
        scores <- bind_rows(scores, r)
        if (length(tokens[[1]]) >= 3) {
          quadRs <- dbGetQuery(conn = dbConn, buildNgramQuery("quadragrams", tokens, 3))
          r <- quadRs %>%
            mutate(score = .4 * frequency / nrow(triRs)) %>%
            select(word, score)
          scores <- bind_rows(scores, r)
          if (length(tokens[[1]]) >= 4) {
            quintRs <- dbGetQuery(conn = dbConn, buildNgramQuery("quintagrams", tokens, 4))
            r <- quintRs %>%
              mutate(score = frequency / nrow(quadRs)) %>%
              select(word, score)
            scores <- bind_rows(scores, r)
          }
        }
      }
    }
  }
  
  # Collapse the scores by word on the maximum score for that word
  scores <- scores %>%
    group_by(word) %>%
    filter(score == max(score)) %>%
    arrange(desc(score))
  
  # Return the top 3 predictions
  unlist(unname(scores[1:3,1]))
}