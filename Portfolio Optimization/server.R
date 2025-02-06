#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#



# Define server logic required to draw a histogram


server <- function(input, output) {
  symbols <- "AAPL"  # You can modify this to include more symbols
  getSymbols(Symbols = symbols, src = 'yahoo', auto.assign = TRUE, warnings = FALSE)
  
  # Assuming you want to work with the first symbol returned
  stock_data <- get(symbols[1])
  
  # Extract the start and end dates
  start_date <- index(stock_data)[1]
  end_date <- index(stock_data)[length(index(stock_data))]
  
} 



#     output$distPlot <- renderPlot({
# 
#         # generate bins based on input$bins from ui.R
#         x    <- faithful[, 2]
#         bins <- seq(min(x), max(x), length.out = input$bins + 1)
# 
#         # draw the histogram with the specified number of bins
#         hist(x, breaks = bins, col = 'darkgray', border = 'white',
#              xlab = 'Waiting time to next eruption (in mins)',
#              main = 'Histogram of waiting times')
# 
#     })
# 
# }
