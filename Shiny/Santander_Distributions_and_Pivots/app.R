library(shiny)
library(rpivotTable)
library(dplyr)

samp<-readRDS("data/samp.rds")


# Define UI for random distribution app ----
ui <- fluidPage(
        
        # App title ----
        titlePanel("Visualise the Santander Data Set - Based on 10% of Data"),
        
        # Main panel for displaying outputs ----
                mainPanel(
                        # Output: Tabset w/ plot, summary, and table ----
                        tabsetPanel(type = "tabs",
                                    tabPanel("Pivot Table & Charts", fluidRow( rpivotTableOutput("pivot")))
                                    #,tabPanel("Table", tableOutput("table"))
                        )
                        
                )
        )


server<-shinyServer(
        function(input, output) {
                
                
                
                
                        output$pivot <- renderRpivotTable({
                                rpivotTable(data =   samp   ,  rows = "age",cols="Changed"
                                            ,aggregatorName = "Count as Fraction of Columns"
                                            ,rendererName = "Bar Chart"
                                            , width="100%", height="400px")
                        })
                })
        
# Run the application 
shinyApp(ui = ui, server = server)

