ui <- dashboardPage(
  dashboardHeader(title = 'Portfolio Optimization'),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = 'overview', icon = icon("dashboard")),
      menuItem('Configuration', tabName = 'configuration', icon = icon('cog')),
      menuItem('Results', tabName = 'results', icon = icon("chart-line")),
      menuItem('Asset Correlations', tabName = 'cor', icon = icon("chart-line")),
      menuItem('Efficient Frontier', tabName = 'efficient_frontier', icon = icon('line-chart'))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = 'overview',
              fluidRow(
                column(12,
                       box(title = 'Introduction', width = 12, status = 'primary',
                           p("Welcome to my Portfolio Optimization Dashboard. My app
                             optimizes your portfolio based on a given list of assets using
                             the Mean Variance optimization approach. I've preloaded 10 popular tech stocks."),
                           tags$ul(
                             tags$li("Mean Variance - Constructs investment portfolio that offers
                                   best possible expected return for a given level of risk -- chosen
                                   from the efficient frontier.")
                           )
                       ),
                       box(title = 'Data reliance', width = 12, status = 'primary',
                           p("My app relies on historical data to perform optimization.
                             You can choose your optimization objective and asset constraints.")
                       )
                )
              )
      ),
      
      tabItem(tabName = 'configuration',
              fluidRow(
                box(title = 'Configuration', width = 12, status = 'primary',
                    dateInput('start_date_input', 'Start Date', value = "2007-02-28"),
                    dateInput('end_date_input', 'End Date', value = "2025-02-28"),
                    selectInput('optimization_objective', 'Optimization Objective:', choices = c("Maximize Sharpe Ratio", "Minimize Volatility", "Maximize Return")),
                    sliderInput('box_constraint', 'Box Constraint:', min = 0, max = 1, value = c(0, 1)),
                    lapply(1:10, function(i){
                      textInput(paste0("asset_", i), label = paste0("Asset Ticker ", i), value = c("AAPL", "MSFT", "NVDA", "GOOGL", "AMZN", "META", "TSLA", "ORCL", "CRM", "ADBE")[i])
                    }),
                    actionButton('optimize', 'Optimize', icon = icon('cogs'), class = 'btn-primary')
                )
              )
      ),
      
      tabItem(tabName = 'results',
              fluidRow(
                box(title = 'Results', width = 12, status = 'primary',
                    highchartOutput('piechart'),
                    tags$h4("Performance Summary"),
                    dataTableOutput('performance_summary'),
                    checkboxInput('log_scale', 'Logarithmic Scale', value = FALSE),
                    highchartOutput('lineChart'),
                    highchartOutput('annualreturns')
                )
              )
      ),
      
      tabItem(tabName = 'cor',
              fluidRow(
                box(title = 'Asset Correlations', width = 12, status = 'primary',
                    dataTableOutput("efficientfrontier_assets_table"),
                    plotlyOutput('correlation_heatmap')
                    
                )
              )
      ),
      
      tabItem(tabName = 'efficient_frontier',
              fluidRow(
                box(title = 'Efficient Frontier', width = 12, status = 'primary',
                    plotlyOutput("efficientFrontier"))
              ))
    )
  )
)
              