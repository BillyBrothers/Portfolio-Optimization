ui <- dashboardPage(
  dashboardHeader(title = 'Portfolio Optimization'),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = 'overview', icon = icon("dashboard")),
      menuItem('Configuration', tabName= 'configuration', icon = icon('chart-line'))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = 'overview',
              fluidRow(
                box(title = 'Introduction', width = 12, status = 'primary',
                    p("Welcome to my Portfolio Optimization Dashboard. My app
                      optimizes your portfolio based on a given list of assets using
                      the Mean Variance optimization approach."),
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
      ),
      
      tabItem(tabName = 'configuration',
              fluidRow(
                box(title = 'Configuration', width = 12, status = 'primary',
                    dateInput('start_date', 'Start Date:', value = start_date),
                    dateInput('end_date', 'End Date:', value = end_date)
                )
              )
        
      )
    )
  )
)