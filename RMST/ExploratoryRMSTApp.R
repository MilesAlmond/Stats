#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(survRM2)
library(survival)
library(tidyverse)
library(ggfortify)
library(kableExtra)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Exploratory RMST Simulations"),
  
  h5("This app will produce a Kaplan-Meier plot and an RMST table for parameters you input below. Just press 'Go!' to generate!"),
  
  br(),
  br(),
  br(),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      numericInput("seed",
                   "Set seed:",
                   value = 123),
      
      br(),
      
      numericInput("size_zero",
                  "Number of Patients in Arm 0:",
                  min = 2,
                  max = 50000,
                  value = 10000),
      
      br(),
      
      numericInput("size_one",
                  "Number of Patients in Arm 1:",
                  min = 2,
                  max = 50000,
                  value = 10000),
      
      br(),
      
      numericInput("shape_zero",
                  "Shape of Weibull in Arm 0:",
                  min = 0.2,
                  max = 10,
                  value = 1),
      
      br(),
      
      numericInput("shape_one",
                  "Shape of Weibull in Arm 1:",
                  min = 0.2,
                  max = 10,
                  value = 1),
      
      br(),
      
      numericInput("med_zero",
                  "Median of Arm 0:",
                  min = 1,
                  max = 5000,
                  value = 50),
      
      br(),
      
      numericInput("med_one",
                  "Median of Arm 1:",
                  min = 1,
                  max = 5000,
                  value = 50),
      
      br(),
      
      numericInput("tau",
                  "Tau:",
                  min = 0,
                  max = 100000,
                  value = 1000),
      
      br(),
      
      actionButton("goButton", "Go!")
      
      
      
    ),
    
    
    
    # Show a plot of the generated distribution
    mainPanel(
      tableOutput("parameters"),
      br(),
      br(),
      plotOutput("plot_rmst"),
      br(),
      br(),
      tableOutput("table_rmst")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  parameters <- eventReactive(input$goButton,
                              
                              {
                                
                                row0 <- c(input$size_zero,input$shape_zero,input$med_zero,input$tau)
                                row1 <- c(input$size_one,input$shape_one,input$med_one,input$tau)
                                
                                parameters <- matrix(c(row0,row1),ncol=4,byrow=T)
                                colnames(parameters) <- c("Population","Weibull Shape","Median","Tau")
                                rownames(parameters) <- c("Arm 0","Arm 1")
                                kbl(parameters,align ='c') %>% kable_material() %>% 
                                  column_spec(1:5,background = "lightcyan") %>% 
                                  column_spec(1,bold=T,background = "lightblue",width="1in") %>% column_spec(2:5,width="2in") %>% 
                                  row_spec(0,bold=T,background = "lightblue")
                              })
  
  output$parameters <- function() {parameters()}
  
  plot_rmst <- eventReactive(input$goButton,
                             
                             {
                               
                               set.seed(input$seed)
                               
                               Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                               One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))
                               
                               time <- c(Zero,One)
                               event <- rep(1,input$size_zero+input$size_one)
                               arm <- c(rep(0,input$size_zero),rep(1,input$size_one))
                               dat <- data.frame(time,event,arm)
                               
                               tau <- min(min(max(Zero,One)),input$tau)
                               
                               result <- rmst2(time,event,arm,tau=tau)
                               
                               sfit <- survfit(Surv(time,event)~arm,data=dat)
                               ggplot2::autoplot(sfit) + labs(x="Time",y="Survival") + geom_vline(xintercept = tau, linetype="dotted", color = "black", size=0.7)
                               
                             })
  
  output$plot_rmst <- renderPlot({plot_rmst()})
  
  table_rmst <- eventReactive(input$goButton,
                              
                              {
                                
                                set.seed(input$seed)
                                
                                Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                                One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))
                                
                                time <- c(Zero,One)
                                event <- rep(1,input$size_zero+input$size_one)
                                arm <- c(rep(0,input$size_zero),rep(1,input$size_one))
                                dat <- data.frame(time,event,arm)
                                
                                tau <- min(min(max(Zero,One)),input$tau)
                                
                                result <- rmst2(time,event,arm,tau=tau)
                                
                                true_med_arm0 <- median(Zero)
                                true_med_arm1 <- median(One)
                                
                                diff <- round(result[5]$unadjusted.result[c(1,7,4)],2) %>% append(round(true_med_arm1 - true_med_arm0,2))
                                arm0 <- round(result[4]$RMST.arm0$rmst[c(1,3,4)],2) %>% append(round(true_med_arm0,2))
                                arm1 <- round(result[3]$RMST.arm1$rmst[c(1,3,4)],2) %>% append(round(true_med_arm1,2))

                                rmst_table <- matrix(c(arm0,arm1,-diff),ncol=4,byrow=T)
                                colnames(rmst_table) <- c("RMST","Lower","Upper","Median")
                                rownames(rmst_table) <- c("Arm 0","Arm 1","Difference")
                                kbl(rmst_table,align='c') %>% kable_material() %>%  column_spec(1:5, background = "lightcyan") %>% column_spec(1,bold=T,background = "lightblue",width="1in") %>% column_spec(2:5,width="2in") %>% row_spec(0,bold=T,background = "lightblue")
                              })
  
  output$table_rmst <- function() {table_rmst()}
  
}

# Run the application 
shinyApp(ui = ui, server = server)
