assertPackage <- function(pkg) {
  ##################################################################################
  # Loads and attaches the given package, installing it if not already present.  
  # Note that the implementation uses require.  ?require for more information.
  #
  # Args:
  #   pkg: The package to check given as a name or a character string
  #
  # Side Effects:
  # This method installs dependent packages of the given package.
  # If not able to install what is required, halts termination.
  ##################################################################################
  if (!suppressMessages(require(pkg, character.only = TRUE, quietly = TRUE))) {
    install.packages(pkg, dep=TRUE)
    if (!suppressMessages(require(pkg, character.only = TRUE))) {
      stop("Package not found")
    }
  }
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