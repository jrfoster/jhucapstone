#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

source("./predict.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  dbConn <- dbConnect(SQLite(), "./sqlite/ngrams.sqlite")
  
  getPrediction <- reactive({
    rv <- getNextWord(input$inputPhrase)
    rv
  })
  
  output$predictionText <- renderText({
    predList <- getPrediction()
    
    paste("<button id='btn-word1' type='button' class='btn btn-default' onclick='word1Click()'>", predList[1], "</button>
           <button id='btn-word2' type='button' class='btn btn-default' onclick='word2Click()'>", predList[2], "</button>
           <button id='btn-word3' type='button' class='btn btn-default' onclick='word3Click()'>", predList[3], "</button>")
    
  })
  
  
})
