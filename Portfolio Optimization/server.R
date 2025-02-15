server <- function(input, output) {
  
  symbols <- reactive({
    sapply(1:10, function(i) { input[[paste0('asset_', i)]]})
  })
  
  
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
      Return.calculate(method = 'log') |> 
      na.omit()
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
    
    portfolio <- portfolio.spec(assets = symbols())
    portfolio <- add.constraint(
      portfolio = portfolio,
      type = 'box',
      min = input$box_constraint[1],
      max = input$box_constraint[2]
    )
    portfolio <- add.constraint(portfolio, type = 'long_only')
    
    
    optimize_method <- switch(input$optimization_objective,
                              "Maximize Sharpe Ratio" = 'ROI',
                              "Minimize Volatility" = 'quadprog',
                              "Maximize Return" = 'Rglpk')
    
    if(input$optimization_objective == 'Maximize Sharpe Ratio') {
      portfolio <- add.objective(portfolio = portfolio, type = 'risk', name = 'var')
      portfolio <- add.objective(portfolio = portfolio, type = 'return', name = 'mean')
    } else if(input$optimization_objective == 'Minimize Volatility') {
      portfolio <- add.objective(portfolio = portfolio, type = 'risk', name = 'var')
    } else if(input$optimization_objective == 'Maximize Return') {
      portfolio <- add.objective(portfolio = portfolio, type = 'return', name = 'mean')
    }
    
    if (input$optimization_objective == 'Maximize Sharpe Ratio') {
      optimize_portfolio <- optimize.portfolio(
        R = returns,
        portfolio = portfolio,
        optimize_method = optimize_method,
        maxSR = TRUE,
        trace = TRUE
      )
    } else {
      optimize_portfolio <- optimize.portfolio(
        R = returns,
        portfolio = portfolio,
        optimize_method = optimize_method,
        trace = TRUE
      )
    }
    
    print(print(optimize_portfolio))
    optimize_portfolio
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
                     geometric = TRUE
                     ) |> 
      `colnames<-`('Monthly_portfolio_returns')
  })
  
  
  Portfolio_Expected_Return <- reactive({
    
   optimal_portfolio <- optimizePortfolio()
   returns <- monthly_portfolio_returns()
    
    if(input$optimization_objective == 'Maximize Sharpe Ratio') {
      Expected_Return <- ((1+optimal_portfolio$objective_measures$mean)^12 - 1)
    } else if(input$optimization_objective == 'Minimize Volatility') {
      Expected_Return <- ((1+mean(returns))^12 - 1)
    } else if(input$optimization_objective == 'Maximize Return') {
      Expected_Return <- ((1 + optimal_portfolio$objective_measures$mean)^12 - 1)
   }
   Expected_Return
  })
  
  Portfolio_Standard_Deviation <- reactive({
    
    optimal_portfolio <- optimizePortfolio()
    returns <- monthly_portfolio_returns()
    
    if(input$optimization_objective == 'Maximize Sharpe Ratio') {
      Standard_Deviation <- optimal_portfolio$objective_measures$StdDev * sqrt(12)
    } else if(input$optimization_objective == 'Minimize Volatility') {
      Standard_Deviation <- optimal_portfolio$objective_measures$StdDev *sqrt(12)
    } else if(input$optimization_objective == 'Maximize Return') {
      Standard_Deviation <- StdDev(returns) * sqrt(12)
    }    
    Standard_Deviation
    })
  
  
  Portfolio_Sharpe_Ratio <- reactive ({
    Portfolio_Expected_Return <- Portfolio_Expected_Return()
    Portfolio_Standard_Deviation <- Portfolio_Standard_Deviation()
    risk_free_rate <- 0.05
    
    SharpeRatio <- (Portfolio_Expected_Return - risk_free_rate) / Portfolio_Standard_Deviation
    
  })
  
    
  performance_summary <- reactive({
    monthly_adjusted_returns <- MonthlyAdjustedReturns()
    monthly_portfolio_returns <- monthly_portfolio_returns()
    market_returns <- sp_500_returns()
    Portfolio_Standard_Deviation <- Portfolio_Standard_Deviation()
    Portfolio_Expected_Return <- Portfolio_Expected_Return()
    
    
    aligned_data <- merge(monthly_portfolio_returns, market_returns, join = "inner")
    aligned_data <- na.omit(aligned_data)
    
    portfolio_returns <- as.numeric(aligned_data[, 1])
    sp_returns <- as.numeric(aligned_data[, 2])
    
    rf_monthly <- (1+0.05)^(1/12)-1
    
    start_balance <- 5000
    end_balance <- start_balance * prod(1+monthly_portfolio_returns)
    CAGR <- Return.annualized(monthly_portfolio_returns, geometric = TRUE)
    expected_return <- Portfolio_Expected_Return
    standard_deviation <- Portfolio_Standard_Deviation
    best_year <- max(apply.yearly(monthly_portfolio_returns, Return.cumulative))
    worst_year <- min(apply.yearly(monthly_portfolio_returns, Return.cumulative))
    max_drawdown <- maxDrawdown(monthly_portfolio_returns)
    sharpe_ratio <- SharpeRatio(monthly_portfolio_returns, Rf = rf_monthly)[1] * sqrt(12)
    sortino_ratio <- SortinoRatio(monthly_portfolio_returns, MAR = 0.05)[1]
    market_correlation <- cor(portfolio_returns, sp_returns)
    
    tibble(
      Metric = c('Start Balance', 'End Balance', 'CAGR', 'Expected Return', 'Standard Deviation', 'Best Year', 'Worst Year', 'Max Drawdown', 'Sharpe Ratio', 'Sortino Ratio', 'Market Correlation'),
      Value = c(
        paste0("$", format(start_balance, nsmall = 0)), 
        paste0("$", format(end_balance, nsmall = 0)), 
        paste0(format(round(CAGR * 100)), "%"), 
        paste0(format(round(expected_return * 100)), "%"), 
        paste0(format(round(standard_deviation * 100)), "%"), 
        paste0(format(round(best_year * 100)), "%"),
        paste0(format(round(worst_year * 100)), "%"),
        paste0(format(round(max_drawdown * 100)), "%"),
        sharpe_ratio, 
        sortino_ratio, 
        market_correlation)
    )
    
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
  

  
  output$performance_summary <- renderDataTable({
    datatable(performance_summary(), options = list(pageLength = 11, autoWidth = TRUE))
  })

  

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
  

  
  output$lineChart <- renderHighchart({
    
    monthly_returns <- portfolio_adjusted_returns_tibble()
    dates <- monthly_returns$date
    start_balance <- 5000
    cumulative_balance <- start_balance * cumprod(1 + as.numeric(monthly_returns$Returns))
    
    
    data <- data.frame(
      x = as.numeric(as.POSIXct(dates)) * 1000,
      y = cumulative_balance
    )
    
    
    chart <- highchart(type = 'stock') |> 
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
    
    if (input$log_scale) {
      chart <- chart |> hc_yAxis(type = 'logarithmic')
    } else {
      chart <- chart |> hc_yAxis(type = 'linear')
    }
    
  })
  
  
  annual_returns <- reactive({
    
    monthly_returns <- portfolio_adjusted_returns_tibble()
    annual_returns <- monthly_returns |> 
      group_by(year = year(date)) |> 
      summarize(annual_return = prod(1 + Returns) -1)
    
  })
  
  output$annualreturns <- renderHighchart({
    
    annual_returns_data <- annual_returns()
    
    highchart() |> 
      hc_title(text = 'Annual Portfolio Returns') |> 
      hc_xAxis(categories = annual_returns_data$year) |> 
      hc_yAxis(title = list(text = 'Annual Return (%)')) |> 
      hc_add_series(
        type = 'column',
        name = 'Annual Return',
        data = round(annual_returns_data$annual_return * 100, 2),
        tooltip = list(
          valueSuffix = "%"
        )
      )
    
  })
  
  
  efficient_frontier_assets <- reactive({
  
    returns <- MonthlyAdjustedReturns()
    rf_annualized <- 0.05
    
    assets <- colnames(returns)
    expected_returns <- apply(returns, 2, function(x) Return.annualized(x , geometric = TRUE))
    standard_deviations <- apply(returns, 2, function(x) {sd(x) * sqrt(12)})
    sharpe_ratios <- apply(returns, 2, function(x) {SharpeRatio(x, Rf = rf_annualized)[1]})
    min_weights <- rep(input$box_constraint[1], length(assets))
    max_weights <- rep(input$box_constraint[2], length(assets))
    
    data.frame(
     Asset = assets,
    `Expected Return` = paste0(round(expected_returns * 100), "%"),
    `Standard Deviation` = paste0(round(standard_deviations * 100), "%"),
    `Sharpe Ratio` = sharpe_ratios,
    `Minimum Weight` = min_weights,
    `Maximum Weight` = max_weights
  )
    
  })
  
  output$efficientfrontier_assets_table <- renderDataTable({
    datatable(efficient_frontier_assets())
  })
  
  
  
  correlation_matrix_melted <- reactive({
    returns <- MonthlyAdjustedReturns()
    correlation_matrix <- cor(returns)
    reshape2::melt(correlation_matrix)
  })
  
  output$correlation_heatmap <- renderPlotly({
    
    cor_matrix <- correlation_matrix_melted()

    plot_ly(
      data = cor_matrix,
      x = ~Var1,
      y = ~Var2,
      z = ~value,
      type = "heatmap",
      colorscale = "RdBu",
      zmin = -1,
      zmax = 1,
      hoverinfo = "x+y+z"
    ) |> 
      layout(
        title = 'Asset Correlation Heat Map',
        xaxis = list(title = "Assets"),
        yaxis = list(title = 'Assets')
            )
  })
  
  
  optimize_risk_adjusted_portfolio <- reactive({
    data <- prices()
    returns <- MonthlyAdjustedReturns()
    
    portfolio <- portfolio.spec(assets = symbols())
    portfolio <- add.constraint(
      portfolio = portfolio,
      type = 'box',
      min = input$box_constraint[1],
      max = input$box_constraint[2]
    )
    portfolio <- add.constraint(portfolio, type = 'long_only')
    
    portfolio <- add.objective(portfolio = portfolio, type = 'risk', name = 'var')
    portfolio <- add.objective(portfolio = portfolio, type = 'return', name = 'mean')
    
    optimize_portfolio <- optimize.portfolio(
      R = returns,
      portfolio = portfolio,
      optimize_method = 'ROI',
      maxSR = TRUE,
      trace = TRUE
    )
  })
  
  annualized_risk_adjusted_standard_deviation <- reactive({
    risk_adjusted_optimize_portfolio <- optimize_risk_adjusted_portfolio()
    annualized_risk_adjusted_standard_deviation <- (risk_adjusted_optimize_portfolio$objective_measures$StdDev) * sqrt(12)
    annualized_risk_adjusted_standard_deviation
  })
  
  
  annualized_risk_adjusted_return <- reactive({
    risk_adjusted_optimize_portfolio <- optimize_risk_adjusted_portfolio()
    annualized_risk_adjusted_return <- (1+risk_adjusted_optimize_portfolio$objective_measures$mean)^12 - 1
  })
  
  risk_adjusted_sharpe_ratio <- reactive({
    annualized_risk_adjusted_standard_deviation <- annualized_risk_adjusted_standard_deviation()
    annualized_risk_adjusted_return <- annualized_risk_adjusted_return()
    risk_adjusted_optimize_portfolio <- optimize_risk_adjusted_portfolio()
    risk_free_rate <- 0.05
    risk_adjusted_sharpe_ratio <- (annualized_risk_adjusted_return - risk_free_rate) / annualized_risk_adjusted_standard_deviation
    risk_adjusted_sharpe_ratio
  })
  
  risk_adjusted_weights <- reactive({
    risk_adjusted_portfolio <- optimize_risk_adjusted_portfolio()
    risk_adjusted_weights <- pluck(risk_adjusted_portfolio, 'weights')
    risk_adjusted_weights
  })
 
  
  
  maximal_portfolio <- reactive({
    data <- prices()
    returns <- MonthlyAdjustedReturns()
    
    portfolio <- portfolio.spec(assets = symbols())
    portfolio <- add.constraint(
      portfolio = portfolio,
      type = 'box',
      min = input$box_constraint[1],
      max = input$box_constraint[2]
    )
    portfolio <- add.constraint(portfolio, type = 'long_only')
    
    portfolio <- add.objective(portfolio = portfolio, type = 'return', name = 'mean')
    
    optimize_portfolio <- optimize.portfolio(
      R = returns,
      portfolio = portfolio,
      optimize_method = "Rglpk",
      trace = TRUE
    )
  })
  
  max_return_portfolio_returns <- reactive({
    
    returns <- MonthlyAdjustedReturns()
    maximal_portfolio <- maximal_portfolio()
    
    Return.portfolio(
    returns,
    pluck(maximal_portfolio, 'weights'),
    rebalance_on = "months",
    geometric = TRUE
  ) |> 
    `colnames<-`('max_return_portfolio_returns')
  })
    

  annual_max_expected_return <- reactive({
    maximal_portfolio <- maximal_portfolio()
    annual_max_expected_return <- (1 + maximal_portfolio$objective_measures$mean) ^ 12 - 1
    annual_max_expected_return
    
  })

  
  annual_max_return_StdDev <- reactive({
    maximal_portfolio <- maximal_portfolio()
    max_return_portfolio_returns <- max_return_portfolio_returns()
    annual_max_return_StdDev <- StdDev(max_return_portfolio_returns) * sqrt(12)
  })
  
 
  
  maximal_weights <- reactive({
    maximal_portfolio <- maximal_portfolio()
    maximal_weights <- pluck(maximal_portfolio, "weights")
    
  })
  
  
  
  min_risk_portfolio <- reactive({
    data <- prices()
    returns <- MonthlyAdjustedReturns()
    
    portfolio <- portfolio.spec(assets = symbols())
    portfolio <- add.constraint(
      portfolio = portfolio,
      type = 'box',
      min = input$box_constraint[1],
      max = input$box_constraint[2]
    )
    portfolio <- add.constraint(portfolio, type = 'long_only')
    
    portfolio <- add.objective(portfolio = portfolio, type = 'risk', name = 'var')
    
    optimize_portfolio <- optimize.portfolio(
      R = returns,
      portfolio = portfolio,
      optimize_method = "quadprog",
      trace = TRUE
    )
  })
  
  annualized_min_var_standard_deviation <- reactive({
    min_risk_portfolio <- min_risk_portfolio()
    annualized_min_var_standard_deviation <- (min_risk_optimize_portfolio$objective_measures$StdDev) * sqrt(12)
    annualized_min_var_standard_deviation
  })
  
  min_var_weights <- reactive ({
    min_risk_portfolio <- min_risk_portfolio()
    min_var_weights <- pluck(min_risk_portfolio, "weights")
  })
  
  
  individual_monthly_returns <- reactive({
    prices <- prices()
    
    to.monthly(
      x = prices,
      drop.time = TRUE,
      indexAt = "lastof",
      OHLC = FALSE
    ) |> 
      Return.calculate(method = 'log') |> 
      na.omit() |> 
      as.data.frame()
  })
  
  individual_annualized_mean_returns <- reactive({
    returns <- individual_monthly_returns()
    
    returns |> 
      summarise(across(everything(), mean, na.rm = TRUE)) |> 
      mutate(across(everything(), ~ (. + 1)^12 - 1)) |>
      pivot_longer(cols = everything(), names_to = "Symbols", values_to = "Annualized Return")
  })
  
  individual_annualized_standard_deviations <- reactive({
    returns <- individual_monthly_returns()
    
    returns |> 
      summarise(across(everything(), sd, na.rm = TRUE)) |> 
      mutate(across(everything(), ~ . * sqrt(12))) |> 
      pivot_longer(cols = everything(), names_to = 'Symbols', values_to = 'Annual StdDev')
  })
  
  assets_df <- reactive({
    
    annualized_std_dev <- individual_annualized_standard_deviations()
    annualized_mean_returns <- individual_annualized_mean_returns()
    
    
    std_dev_df <- as.data.frame(annualized_std_dev)
    mean_returns_df <- as.data.frame(annualized_mean_returns)
    
    assets_df <- inner_join(mean_returns_df, std_dev_df, by = "Symbols") |> 
      filter(Symbols != "NVDA")
    
    assets_df
  })
  
  efficient_frontier <- reactive({
    sharpe_portfolio <- optimize_risk_adjusted_portfolio()
    extractEfficientFrontier(
      sharpe_portfolio,
      match.col = "StdDev",
      n.portfolios = 100
    )
  })
  
  output$efficientFrontier <- renderPlotly({
    annualized_risk_adjusted_return <- annualized_risk_adjusted_return()
    annualized_risk_adjusted_standard_deviation <- annualized_risk_adjusted_standard_deviation()
    risk_adjusted_sharpe_ratio <- risk_adjusted_sharpe_ratio()
    risk_adjusted_weights <- risk_adjusted_weights()
    
    
    annual_max_expected_return <- annual_max_expected_return()
    annual_max_return_StdDev <- annual_max_return_StdDev()
    maximal_weights <- maximal_weights()
    
    annualized_min_var_standard_deviation <- annualized_min_var_standard_deviation()
    min_var_weights <- min_var_weights()
    
    assets_df <- assets_df()
    
    
    frontier <- efficient_frontier()
    
    
    cl <- makeCluster(detectCores() - 1)
    
    ef_monthly_mean_return <- frontier$frontier[, 1]
    ef_monthly_std_dev <- frontier$frontier[, 2]
    weights <- frontier$frontier[, 4:13]
    
    
    n.portfolios <- 100
  
    ef_annual_return <- (1 + ef_monthly_mean_return) ^ 12 - 1
    ef_annual_std_dev <- ef_monthly_std_dev * sqrt(12)
    risk_free_rate <- 0.05
    ef_sharpe_ratio <- (ef_annual_return - risk_free_rate) / ef_annual_std_dev
    
    
    weights_str <- apply(weights, 1, function(row) {
      paste(names(row), ":", round(row, 2), collapse = "<br>")
    })
    
    data_list <- sapply(1:length(ef_monthly_mean_return), function(i) {
      list(x = ef_monthly_std_dev[i], y = ef_monthly_mean_return[i], weights = weights_str[i])
      
      
    })
    
    stopCluster(cl)
    
    cml_x <- c(0, max(ef_annual_std_dev))
    cml_y <- risk_free_rate + risk_adjusted_sharpe_ratio * cml_x
    
    
    plot_ly() |> 
      add_trace(
          x = ~ef_annual_std_dev,
          y = ~ef_annual_return,
          type = 'scatter',
          mode = 'lines',
          text = ~paste("Risk (StdDev):", round(ef_annual_std_dev, 2),
                        "<br>Return (Mean):", round(ef_annual_return, 2),
                        "<br>Sharpe Ratio:", round(ef_sharpe_ratio, 2),
                        "<br>Weights:<br>", weights_str),
          hoverinfo = 'text',
          marker = list(color = 'blue'),
          name = 'Efficient Frontier'
        ) |> 
          # Add the optimal portfolio point
          add_trace(
            x = annualized_risk_adjusted_standard_deviation,
            y = annualized_risk_adjusted_return,
            type = 'scatter',
            mode = 'markers',
            marker = list(color = 'red', size = 10),
            name = 'Optimal Portfolio',
            text = paste("Risk (StdDev):", round(annualized_risk_adjusted_standard_deviation, 4), 
                         "<br>Return (Mean):", round(annualized_risk_adjusted_return, 4),
                         "<br>Sharpe Ratio:", round(risk_adjusted_sharpe_ratio, 2),
                         "<br>Optimal Weights:<br>", paste(names(risk_adjusted_weights), ":", round(risk_adjusted_weights, 2), collapse = "<br>")),
            hoverinfo = 'text'
          ) %>%
          # Add the maximal portfolio point
          add_trace(
            x = annual_max_return_StdDev,
            y = annual_max_expected_return,
            type = 'scatter',
            mode = 'markers',
            marker = list(color = 'green', size = 10),
            name = 'Maximal Portfolio',
            text = paste("Risk (StdDev):", round(annual_max_return_StdDev, 2), 
                         "<br>Return (Mean):", round(annual_max_expected_return, 2),
                         "<br>Maximal Weights:<br>", paste(names(maximal_weights), ":", round(maximal_weights, 2), collapse = "<br>")),
            hoverinfo = 'text'
          ) %>%
          # Add the minimum variance portfolio point
          add_trace(
            x = annualized_min_var_standard_deviation,
            y = 0.22,
            type = 'scatter',
            mode = 'markers',
            marker = list(color = 'purple', size = 10),
            name = 'Minimum Variance Portfolio',
            text = paste("Risk (StdDev):", round(annualized_min_var_standard_deviation, 4), 
                         "<br>Return (Mean):", round(0.22, 4),
                         "<br>Minimum Variance Weights:<br>", paste(names(min_var_weights), ":", round(min_var_weights, 2), collapse = "<br>")),
            hoverinfo = 'text'
          )  |> 
          add_trace(
            x = cml_x,
            y = cml_y,
            type = 'scatter',
            mode = 'lines',
            line = list(color = 'green', dash = 'dash'),
            name = 'Capital Market Line',
            text = 'Capital Market Line (CML)',
            hoverinfo = 'text'
          ) |>
      
          add_trace(
            x = assets_df$`Annual StdDev`,
            y = assets_df$`Annualized Return`,
            type = 'scatter',
            mode = 'markers',
            marker = list(size = 8, color = 'orange'),
            name = 'Inferior Portfolios',
            text = ~paste("Asset:", assets_df$Symbols, 
                          "<br>Risk (StdDev):", round(assets_df$`Annual StdDev`, 2), 
                          "<br>Return (Mean):", round(assets_df$`Annualized Return`, 2)),
            hoverinfo = 'text'
          ) |> 
        
          layout(
            title = 'Annualized Efficient Frontier with Portfolios',
            xaxis = list(
              title = 'Risk (Portfolio Standard Deviation)',
              tickformat = ".2%",  # Format as percentage with 2 decimal places
              tickvals = seq(0, 0.8, by = 0.05)  # Custom tick values at intervals of 0.05
            ),
            yaxis = list(
              title = 'Portfolio Expected Return',
              tickformat = ".2%",  # Format as percentage with 2 decimal places
              tickvals = seq(0, 0.6, by = 0.05)  # Custom tick values at intervals of 0.05
            ),
            hoverlabel = list(
              bgcolor = "white",
              bordercolor = "black",
              font = list(color = "black")
            )
          )
      })
}
      