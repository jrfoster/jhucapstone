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
  x
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
  qry <- paste("select word, relFreq from", table, "where root =")
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
  ptrn <- paste(gsub("'", "''", tail(tokens[[1]], num)), collapse="_")
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
  qry <- paste(getBaseQueryFor(table), "'", getPatternFor(tokens, num), "' order by relFreq desc limit 3", sep = "")
  qry
}

getTopUnigrams <- function(connection) {
  ##################################################################################
  # Convenience function to return the top 3 unigrams from the database
  #
  # Returns
  #   Character vector containing the most frequent words in the original corpus
  #
  ##################################################################################
  r <- dbGetQuery(conn = connection, "select word, frequency as \"score\" from unigrams order by frequency desc limit 10")
  r
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
    r <- getTopUnigrams(dbConn)
    return(unlist(unname(r[1:3,1])))  
  }
  
  tokens <- tokenizeInput(phrase)
  
  if (length(tokens[[1]]) == 0) {
    r <- getTopUnigrams(dbConn)
    return(unlist(unname(r[1:3,1])))  
  }
  
  # Initialize the power of the backoff factor to zero
  alphaPow <- 0
  
  # Initialize the dataframes the routine will use
  scores <- data.table(word = character(), rank = integer(), score = numeric(), stringsAsFactors = FALSE)
  quintRs <- quadRs <- triRs <- biRs <- uniRs <- data.table(ngram = character(), relFreq = integer(), stringsAsFactors = FALSE)
  
  if (length(tokens[[1]]) >= 4) {
    quintRs <- dbGetQuery(conn = dbConn, buildNgramQuery("quintagrams", tokens, 4))
    r <- quintRs %>%
      mutate(score = (.4 ^ alphaPow) * relFreq, rank = 5) %>%
      select(word, rank, score)
    scores <- bind_rows(scores, r)    
    alphaPow <- alphaPow + 1
  }
  
  if (nrow(scores) < 3 && length(tokens[[1]]) >= 3)  {
    quadRs <- dbGetQuery(conn = dbConn, buildNgramQuery("quadragrams", tokens, 3))
    r <- quadRs %>%
      filter(!word %in% scores$word) %>%
      mutate(score = (.4 ^ alphaPow) * relFreq, rank = 4) %>%
      select(word, rank, score)
    scores <- bind_rows(scores, r)
    alphaPow <- alphaPow + 1
  }
  
  if (nrow(scores) < 3 && length(tokens[[1]]) >= 2)  {
    triRs <- dbGetQuery(conn = dbConn, buildNgramQuery("trigrams", tokens, 2))
    r <- triRs %>%
      filter(!word %in% scores$word) %>%
      mutate(score = (.4 ^ alphaPow) * relFreq, rank = 3) %>%
      select(word, rank, score)
    scores <- bind_rows(scores, r)
    alphaPow <- alphaPow + 1
  }
  
  if (nrow(scores) < 3 && length(tokens[[1]]) >= 1)  {
    biRs <- dbGetQuery(conn = dbConn, buildNgramQuery("bigrams", tokens, 1))
    r <- biRs %>%
      filter(!word %in% scores$word) %>%
      mutate(score = (.4 ^ alphaPow) * relFreq, rank = 2) %>%
      select(word, rank, score)
    scores <- bind_rows(scores, r)
    alphaPow <- alphaPow + 1
  }
  
  # Collapse the scores by word on the maximum score for that word
  scores <- scores %>%
    group_by(word) %>%
    filter(rank == max(rank)) %>%
    arrange(desc(rank), desc(score))
  
  # Final catch-all that fills the scores with top unigrams if there are any missing
  if (nrow(scores) < 3) {
    rs <- getTopUnigrams(dbConn)
    r <- rs %>%
      filter(!(word %in% scores$word))
    scores <- bind_rows(scores, r[1:(3-nrow(scores)),])
  }
  
  # Return the top 3 predictions
  unlist(unname(scores[1:3,1]))
}