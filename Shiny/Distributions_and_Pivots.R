library(shiny)
library(rpivotTable)
library(tidyverse)
library(dplyr)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/Shiny/Santander_Distributions_and_Pivots")
df<-readRDS("trainchange1.rds")
set.seed(1258)
rand<-sample(1:100,nrow(trainchange1),replace = TRUE )
samp<-trainchange1[rand %in% 20:22,]

#rng<- c("All",unique(as.character(df$Changed)))
rng<- c(unique(df$Changed))

# Define UI for random distribution app ----
ui <- fluidPage(
        
        # App title ----
        titlePanel("Visualise the Santander Data Set"),
        
        # Sidebar layout with input and output definitions ----
        sidebarLayout(
                
                # Sidebar panel for inputs ----
                sidebarPanel(
                        selectInput('Changed', 'Have New Products Been Bought', choices=rng, selected= rng[2],multiple = TRUE)   ),
                
                # Main panel for displaying outputs ----
                mainPanel(
                        # Output: Tabset w/ plot, summary, and table ----
                        tabsetPanel(type = "tabs",
                                    tabPanel("Basic Distributions", fluidRow(splitLayout(cellWidths = c("50%", "50%"), plotOutput("newHist"), plotOutput("newHist3"))                ),
                                             fluidRow(splitLayout(cellWidths = c("50%", "50%"), plotOutput("newHist2"), plotOutput("newHist4")))),
                                    tabPanel("Summary", fluidRow( rpivotTableOutput("pivot")))
                                    #,tabPanel("Table", tableOutput("table"))
                        )
                        
                )
        )
)




var3<-c("age","Num_Changes")
server<-shinyServer(
        function(input, output) {
                
                #this is the part that cause the failure
                
                df2<-reactive({
                        df2<-df %>% filter(Changed %in% input$Changed)
                        
                        # if(input$Changed=="All")
                        #         return()
                        # df
                })
                #observe(print(df2()))
                output$newHist <- renderPlot({
                        hist(df[,var3[1]], xlab=var3[1], 
                             col='lightblue',main='Histogram') })
                output$newHist3 <- renderPlot({
                        hist(df2()[,var3[1]], xlab=var3[1], 
                             col='blue',main='Histogram') })
                output$newHist2 <- renderPlot({
                        hist(df[,var3[2]], xlab=var3[2], 
                             col='red',main='Histogram')})
                output$newHist4 <- renderPlot({
                        hist(df2()[,var3[2]], xlab=var3[2], 
                             col='purple',main='Histogram')
                        output$pivot <- renderRpivotTable({
                                rpivotTable(data =   samp   ,  rows = "Num_Changes",cols="ind_recibo_ult1_change"
                                            
                                            , width="100%", height="400px")
                        })
                })
        }
)

# Run the application 
shinyApp(ui = ui, server = server)

