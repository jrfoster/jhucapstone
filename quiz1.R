dataDir <- file.path(getwd(), "Coursera-SwiftKey", "final", "en_US")
blogPath <- file.path(dataDir, "en_US.blogs.txt")
newsPath <- file.path(dataDir, "en_US.news.txt")
twtrPath <- file.path(dataDir, "en_US.twitter.txt")

blog = readLines(file(blogPath, open = "rb"), encoding = "UTF-8", skipNul = TRUE, warn = FALSE)
news = readLines(file(newsPath, open = "rb"), encoding = "UTF-8", skipNul = TRUE, warn = FALSE)
twtr = readLines(file(twtrPath, open = "rb"), encoding = "UTF-8", skipNul = TRUE, warn = FALSE)
