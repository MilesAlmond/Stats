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
  titlePanel("Exploratory RMST Simulations with Iterations"),
  
  h5("This app will give the proportion of the differences between RMSTs under a certain value for parameters you input below, as well as several scatter graphs using median and RMST, split by treatment arm. Just press 'Go!' to generate!"),
  
  br(),
  br(),
  br(),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      numericInput("seed",
                   "Set seed:",
                   value=123),
      
      br(),
      
      numericInput("iterations",
                  "Number of Iterations:",
                  min = 1,
                  max = 10000,
                  value = 50),
      
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
      
      numericInput("difference",
                  "Give proportion of differences less than:",
                  min = 0,
                  max = 10000,
                  value = 1),
      
      br(),
      
      actionButton("goButton", "Go!")
      
      
    ),
    
    
    
    # Show a plot of the generated distribution
    mainPanel(
      tableOutput("parameters"),
      br(),
      br(),
      tableOutput("table_proportion"),
      br(),
      br(),
      plotOutput("median_rmst"),
      br(),
      br(),
      plotOutput("diff_individual_rmst"),
      br(),
      br(),
      plotOutput("diff_rmst"),
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
                                  add_header_above(c("",paste("Iterations =",input$iterations),"","","")) %>%  column_spec(1:5,background = "lightcyan") %>% 
                                  column_spec(1,bold=T,background = "lightblue",width="1in") %>% column_spec(2:5,width="2in") %>% 
                                  row_spec(0,bold=T,background = "lightblue")
                              })
  
  output$parameters <- function() {parameters()}
  
  table_proportion <- eventReactive(input$goButton,
                                    
                                    {
                                      
                                      set.seed(input$seed)
                                      
                                      event <- rep(1,input$size_zero+input$size_one)
                                      arm <- c(rep(0,input$size_zero),rep(1,input$size_one))
                                      
                                      diff <- matrix(nrow=input$iterations,ncol=4)
                                      arm0 <- matrix(nrow=input$iterations,ncol=4)
                                      arm1 <- matrix(nrow=input$iterations,ncol=4)
                                      
                                      for (i in 1:input$iterations) {
                                        
                                        Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                                        One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))
                                        
                                        time <- c(Zero,One)
                                        tau <- min(min(max(Zero,One)),input$tau)
                                        dat <- data.frame(time,event,arm)
                                        
                                        result <- rmst2(time,event,arm,tau=tau)
                                        
                                        true_med_arm0 <- median(Zero)
                                        true_med_arm1 <- median(One)
                                        
                                        arm0[i,c(1,2,3,4)] <- c(result[4]$RMST.arm0$rmst[c(1,3,4)],true_med_arm0)
                                        arm1[i,c(1,2,3,4)] <- c(result[3]$RMST.arm1$rmst[c(1,3,4)],true_med_arm1)
                                        diff[i,c(1,2,3,4)] <- c(result[5]$unadjusted.result[c(1,4,7)],true_med_arm1 - true_med_arm0)
                                        
                                      }
                                      
                                      proportion = round(sum(abs(diff[,1])<input$difference)/input$iterations,2)
                                      kbl(proportion,align='c',col.names = NULL) %>% kable_material() %>% add_header_above(c(paste("Proportion of RMST Differences Less Than",input$difference))) %>% column_spec(1, background = "lightcyan",bold=T)
                                      
                                    })
  
  output$table_proportion <- function() {table_proportion()}
  
  median_rmst <- eventReactive(input$goButton,
                               
                        {
                              set.seed(input$seed)     
                          
                               event <- rep(1,input$size_zero+input$size_one)
                               arm <- c(rep(0,input$size_zero),rep(1,input$size_one))

                               arm0 <- matrix(nrow=input$iterations,ncol=3)
                               arm1 <- matrix(nrow=input$iterations,ncol=3)


                               for (i in 1:input$iterations) {

                                 Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                                 One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))

                                 time <- c(Zero,One)
                                 tau <- min(min(max(Zero,One)),input$tau)
                                 dat <- data.frame(time,event,arm)

                                 result <- rmst2(time,event,arm,tau=tau)

                                 true_med_arm0 <- median(Zero)
                                 true_med_arm1 <- median(One)

                                 arm0[i,c(1,2,3)] <- c(result[4]$RMST.arm0$rmst[1],true_med_arm0,0)
                                 arm1[i,c(1,2,3)] <- c(result[3]$RMST.arm1$rmst[1],true_med_arm1,1)
                               }
                               
                               DF_pre <- rbind(arm0,arm1)
                               DF <- as.data.frame(DF_pre)
                               names(DF) <- c("RMST","TrueMed","Arm")
                               DF$Arm <- factor(DF$Arm)
                               
                               ggplot(DF,aes(TrueMed,RMST)) + geom_point(aes(colour = Arm)) + xlab("True Median")
                        })
  
  output$median_rmst <- renderPlot({median_rmst()})
  
  diff_individual_rmst <- eventReactive(input$goButton,
                                        
                                        {
                                          set.seed(input$seed)     
                                          
                                          event <- rep(1,input$size_zero+input$size_one)
                                          arm <- c(rep(0,input$size_zero),rep(1,input$size_one))
                                          
                                          arm0 <- matrix(nrow=input$iterations,ncol=3)
                                          arm1 <- matrix(nrow=input$iterations,ncol=3)
                                          
                                          
                                          for (i in 1:input$iterations) {
                                            
                                            Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                                            One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))
                                            
                                            time <- c(Zero,One)
                                            tau <- min(min(max(Zero,One)),input$tau)
                                            dat <- data.frame(time,event,arm)
                                            
                                            result <- rmst2(time,event,arm,tau=tau)
                                            
                                            true_med_arm0 <- median(Zero)
                                            true_med_arm1 <- median(One)
                                            
                                            diff_rmst_med_arm0 <- sum(result[4]$RMST.arm0$rmst[1],-true_med_arm0)
                                            diff_rmst_med_arm1 <- sum(result[3]$RMST.arm1$rmst[1],-true_med_arm1)
                                            
                                            
                                            arm0[i,c(1,2,3)] <- c(diff_rmst_med_arm0,true_med_arm0,0)
                                            arm1[i,c(1,2,3)] <- c(diff_rmst_med_arm1,true_med_arm1,1)
                                          }
                                          
                                          DF_pre <- rbind(arm0,arm1)
                                          DF <- as.data.frame(DF_pre)
                                          names(DF) <- c("RMST_Med_Diff","TrueMed","Arm")
                                          DF$Arm <- factor(DF$Arm)
                                          
                                          ggplot(DF,aes(TrueMed,RMST_Med_Diff)) + geom_point(aes(colour = Arm)) + xlab("True Median") + ylab("RMST - True Median")
                                          
                                        })
  
  output$diff_individual_rmst <- renderPlot({diff_individual_rmst()})
  
  diff_rmst <- eventReactive(input$goButton,
                               
                               {
                                 set.seed(input$seed)     
                                 
                                 event <- rep(1,input$size_zero+input$size_one)
                                 arm <- c(rep(0,input$size_zero),rep(1,input$size_one))
                                 
                                 diff <- matrix(nrow=input$iterations,ncol=2)
                                 
                                 
                                 for (i in 1:input$iterations) {
                                   
                                   Zero <- rweibull(input$size_zero,shape=input$shape_zero,scale=input$med_zero/(log(2)^(1/input$shape_zero)))
                                   One <- rweibull(input$size_one,shape=input$shape_one,scale=input$med_one/(log(2)^(1/input$shape_one)))
                                   
                                   time <- c(Zero,One)
                                   tau <- min(min(max(Zero,One)),input$tau)
                                   dat <- data.frame(time,event,arm)
                                   
                                   result <- rmst2(time,event,arm,tau=tau)
                                   
                                   true_med_arm0 <- median(Zero)
                                   true_med_arm1 <- median(One)
                                   
                                   diff[i,c(1,2)] <- result[5]$unadjusted.result[1] %>% append(true_med_arm1 - true_med_arm0)
                                   
                                 }
                                 
                                 DF <- as.data.frame(diff)
                                 names(DF) <- c("RMST","TrueMed")
                                 
                                 ggplot(DF,aes(TrueMed,RMST)) + geom_point() + xlab("Difference in True Medians (Arm 1 vs Arm 0)") + ylab("Difference in RMSTs (Arm 1 vs Arm 0)")
                                 
                               })
  
  output$diff_rmst <- renderPlot({diff_rmst()})


}
# Run the application 
shinyApp(ui = ui, server = server)
