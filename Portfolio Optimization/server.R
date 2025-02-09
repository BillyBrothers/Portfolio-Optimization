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
  
  observe({
    print(range(index(prices())))
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
  
  observe({
    print(range(index(MonthlyAdjustedReturns())))
  })
  
  
  sp_500_returns <- reactive({
    symbols <- c("^GSPC")
    
    spx <- getSymbols(
      Symbols = symbols,
      src = 'yahoo',
      from = input$start_date_input,
      to = input$end_date_input,
      auto.assign = TRUE,
      warnings = FALSE
    ) |>
      map(.f = ~Ad(get(x = .))) |> 
      reduce(.f = merge) |> 
      `colnames<-` (value=symbols)
    
    spx <- to.monthly(
      x = spx,
      drop.time = TRUE,
      indexAt  = 'lastof',
      OHLC = FALSE
    ) |> 
      Return.calculate(
        method = 'discrete') |> 
      na.omit()
    
  })
  
  
  optimizePortfolio <- eventReactive(input$optimize, {
    data <- prices()
    returns <- MonthlyAdjustedReturns()
    print(range(index(returns)))
    
    portfolio <- portfolio.spec(assets = symbols())
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
  
  monthly_portfolio_returns <- reactive({
    Return.portfolio(R= MonthlyAdjustedReturns(),
                     weights = pluck(optimizePortfolio(), 'weights'),
                     rebalance_on = "months",
                     geometric = FALSE
                     ) |> 
      `colnames<-`('Monthly_portfolio_returns')
  })
  
  observe({
    print(range(index(monthly_portfolio_returns())))
  })
  
  performance_summary <- reactive({
    monthly_adjusted_returns <- MonthlyAdjustedReturns()
    monthly_portfolio_returns <- monthly_portfolio_returns()
    market_returns <- sp_500_returns()
    
    
    aligned_data <- merge(monthly_portfolio_returns, market_returns, join = "inner")
    aligned_data <- na.omit(aligned_data)
    
    portfolio_returns <- as.numeric(aligned_data[, 1])
    sp_returns <- as.numeric(aligned_data[, 2])
    
    
    start_balance <- 5000
    end_balance <- start_balance * prod(1+monthly_portfolio_returns)
    CAGR <- (end_balance/start_balance)^(12/nrow(monthly_portfolio_returns)) -1
    expected_return <- mean(monthly_portfolio_returns)
    standard_deviation <- sd(monthly_portfolio_returns)
    best_year <- max(apply.yearly(monthly_portfolio_returns, Return.cumulative))
    worst_year <- min(apply.yearly(monthly_portfolio_returns, Return.cumulative))
    max_drawdown <- maxDrawdown(monthly_portfolio_returns)
    sharpe_ratio <- SharpeRatio(monthly_portfolio_returns, Rf = 0.05)[1]
    sortino_ratio <- SortinoRatio(monthly_portfolio_returns, MAR = 0.05)[1]
    market_correlation <- cor(portfolio_returns, sp_returns)
    
    tibble(
      Metric = c('Start Balance', 'End Balance', 'CAGR', 'Expected Return', 'Standard Deviation', 'Best Year', 'Worst Year', 'Max Drawdown', 'Sharpe Ratio', 'Sortino Ratio', 'Market Correlation'),
      Value = c(
        paste0("$", format(start_balance, nsmall = 0)), 
        paste0("$", format(end_balance, nsmall = 0)), 
        paste0(format(CAGR * 100, nsmall = 2), "%"), 
        paste0(format(expected_return * 100, nsmall = 2), "%"), 
        paste0(format(standard_deviation * 100, nsmall = 2), "%"), 
        paste0(format(best_year * 100, nsmall = 2), "%"),
        paste0(format(worst_year * 100, nsmall = 2), "%"),
        paste0(format(max_drawdown * 100, nsmall = 2), "%"),
        sharpe_ratio, 
        sortino_ratio, 
        market_correlation)
    )
    
  })
  
  
  output$results <- renderTable({
    tibble(portfolio_weights())
    
  })
  
  
  output$piechart <- renderHighchart({
    data <- portfolio_weights()
      highchart() |>
        hc_chart(type = 'pie') |> 
        hc_title(text = 'Portfolio Allocation') |> 
        hc_tooltip(pointFormat = "<b>{point.name}</b>: {point.percentage:.1f}%") |> 
        hc_plotOptions(pie = list(
          dataLabels = list(
            enabled = TRUE,
            format = "<b>{point.name}<b>: {point.percentage:.1f}%"
          ),
          showInLegend = TRUE
        )) |> 
        hc_legend(
          enabled = TRUE,
          layout = 'vertical',
          align = 'right',
          verticalAlign = 'bottom',
          labelFormatter = JS("function() {
            return this.name + ': ' + this.percentage.toFixed(1) + '%';
          }")
        ) |> 
        hc_add_series(
          name = 'Allocation',
          colorByPoint = TRUE,
          data = lapply(1:nrow(data), function(i) {
            list(name = data$asset[i], y=data$allocation[i])
          })
        )
  })
  
  
  
  
  
  output$performance_summary <- renderTable(
    performance_summary()
  )
  

  portfolio_adjusted_returns_tibble <- reactive({
    monthly_portfolio_returns() |> 
      tk_tbl() |> 
      rename(date = index) |> 
      pivot_longer(
        -date,
        names_to = 'Asset',
        values_to = 'Returns'
      ) |> 
      select(-Asset)
})
  
  observe({
    print(range(portfolio_adjusted_returns_tibble()$date))
  })

  
  output$lineChart <- renderHighchart({
    
    monthly_returns <- portfolio_adjusted_returns_tibble()
    dates <- monthly_returns$date
    start_balance <- 5000
    cumulative_balance <- start_balance * cumprod(1 + as.numeric(monthly_returns$Returns))
    
    print(head(monthly_returns))
    print(head(cumulative_balance))
    
    
    data <- data.frame(
      x = as.numeric(as.POSIXct(dates)) * 1000,
      y = cumulative_balance
    )
    
    print(head(data))
    print(tail(data))
    
    highchart(type = 'stock') |> 
      hc_title(text = 'Portfolio Growth') |> 
      hc_xAxis(type =  'datetime') |>
      hc_add_series(
        name = 'Cumulative Dollar Amount',
        data = list_parse2(data),
        tooltip = list(
          valueDecimals = 2,
          valuePrefix = "$",
          valueSuffix = "",
          xDateFormat = "%b %Y"
        )
      )
    
  })
  
}