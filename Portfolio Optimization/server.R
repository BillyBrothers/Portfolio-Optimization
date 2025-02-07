server <- function(input, output) {
  
  symbols <- reactive({
    sapply(1:10, function(i) input[[paste0('asset_', i)]])
  })
  
  # Reactive data input 
  prices <- reactive({
    getSymbols(symbols(), src = 'yahoo',
                       from = input$start_date_input,
                       to = input$end_date_input,
                       auto.assign = TRUE) |>
      map(.f = ~ Ad(get(x = .))) |> 
      reduce(.f = merge) |> 
      `colnames<-`(value = symbols())
  })
  
  
  MonthlyAdjustedReturns <- reactive({
    to.monthly(
      x = prices(),
      drop.time = TRUE,
      indexAt = 'lastof', 
      OHLC = FALSE
    ) |> 
      Return.calculate(method = 'discrete') |> 
      na.omit()
  })
  
  optimizePortfolio <- eventReactive(input$optimize, {
    data <- prices()
    returns <- MonthlyAdjustedReturns()
    portfolio <- portfolio.spec(assets = symbols())
    
    # Add box constraint
    portfolio <- add.constraint(
      portfolio = portfolio,
      type = 'box',
      min = input$box_constraint[1],
      max = input$box_constraint[2]
    )
    
    optimize_method <- switch(input$optimization_objective,
                              "Maximize Sharpe Ratio" = 'ROI',
                              "Minimize Volatility" = 'quadprog',
                              "Maximize Return" = 'Rglpk')
    
    if(input$optimization_objective == 'Maximize Sharpe Ratio') {
      portfolio <- add.objective(portfolio = portfolio, type = 'risk_adjusted_return', name = 'SharpeRatio')
    } else if(input$optimization_objective == 'Minimize Volatility') {
      portfolio <- add.objective(portfolio = portfolio, type = 'risk', name = 'StdDev')
    } else if(input$optimization_objective == 'Maximize Return') {
      portfolio <- add.objective(portfolio = portfolio, type = 'return', name = 'mean')
    }
    
    optimize.portfolio(
      R = returns,
      portfolio = portfolio,
      optimize_method = optimize_method
    )
    
  })
    
  portfolio_weights <- reactive({
    optimized_weights <- pluck(optimizePortfolio(), 'weights')
    tibble(
      asset = names(optimized_weights),
      allocation = as.numeric(optimized_weights)
    )
  })
  
  
  output$results <- renderTable({
    portfolio_weights()
    
  })
  
  
  output$piechart <- renderHighchart({
    data <- portfolio_weights()
    hchart(data, 'pie', hcaes(name = asset, y = allocation)) |> 
      hc_title(text = 'Portfolio Allocation') |> 
      hc_tooltip(pointFormat = "<b>{point.name}</b>: {point.percentage: .1f}%") |> 
      hc_plotOptions(pie = list(
        dataLabels = list(
          enabled = TRUE,
          format = "<b>{point.name}</b>: {point.percentage:.1f}%"
        )
      ))
  })
  
  
  # portfolio_returns <- Return.portfolio(R = returns, weights = optimized_weights)

}