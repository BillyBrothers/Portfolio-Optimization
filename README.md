# Nasdaq_100

# Portfolio-Optimization App

##  Motivation
Like most people, I like money. The majority of us sell our time in exchange for cash. It's good but not great. Selling your labor requires time and energy -- and we have limited supplies of that, unfortunately. But fortunately, 
there are other avenues we can take like investing. Our money grows while we do...nothing? Sounds great! But for most people, investing is confusing. Everyone knows Real estate is great, but it's an extravagant expenditure -- a lot of time and energy just to acquire it. Other more affordable opportunities lie in the stock market -- much more affordable -- but still confusing. We've all heard the trope, **Don't put all your eggs in one basket**. So, we know we need to buy a lot of different kinds of stock. We call that *diversifying*. The other trope: **risk versus reward -- higher the risk higher the reward.** Sounds dandy but risk is scary -- we want to minimize it; Reward is sexy -- we need to maximize it. In finance speak risk is *volatility* or how much the price fluctuates relative to a benchmark like the entire market; and reward is *expected return* or how much your stock price grows. So, now you're at a crossroads. You know you need a basket of unique stock, you want the minimal amount of risk with the maximal amount of reward relative to that risk. You could pay a broker or take a class but that's too much of your time and energy. Where do you even start?

## Purpose
The purpose of my project is to develop an app that allows users to input any quantity of stocks, whether they're all relative to a single sector or not, and receive a fundamental, investigative analysis on those stocks using their historical data via an Yahoo Finance API. The app would display pertinent information for the investor.  

## Analysis and Output
The user will have the answers to the most pertinent information for an investor building a stock portfolio:


1) What are the historical returns of the assets in the financial dataset?
   1) Import financial dataset (entire tech sector)
   2) look at in comparsion to s&p 500
   3) look at in comparsion to major economic indicators 


   start with serverside logic, then userinteractive what can we see, and how can the user interact with it? 

3) What are the volatilites for the assets in the financial dataset?

4) What are the expected returns for assets in the financial dataset?
  * serverside logic:
    1) import Use the U.S. Treasury Bill rate with maturity 1 year or less (risk free rate benchmark (it is the most risk free finanical asset known))
    2) import stock data
    3) Calculate daily returns for each stock
    4) Import beta for each stock (systematic risk) by comparing to market return.
    5) Calculate expected return using CAPM Formula:
       * E(Ri) is the expected return of stock i
       * Rf is the risk free rate
       * Bi is the beta of the stock
       * E(Rm) is the expected return of the market portfolio
       * (E(Rm) - Rf) is the market risk premium
       Formula: $$E(R_i) = R_f + \beta_i (E(R_m) - R_f)$$
  * user interactive
    1) Stock Symbol Input: Allow users to enter the stock symbols they are interested in (or all if they're interested in everything).
    2) Risk-Free Rate Input: Enable users to input the risk-free rate they wish to use in their calculations (have the standard as an option).
    3) Market Return Input: Let users enter the expected return of the market portfolio.
    4) Update Button: Provide a button for users to trigger the calculation.
    5) Results Display: Show the expected returns for the entered stock symbols.
    6) Bar Chart of Expected Returns: A bar chart can visually compare the expected returns for different stocks. This helps users quickly identify which stocks have higher or lower expected returns.
    7) Scatter Plot of Beta vs. Expected Return: A scatter plot can show the relationship between beta and expected return for the tech stocks. This visualization helps users understand how market risk (beta) is related to the expected return.
    8) Table of Expected Returns and Betas:
    9) A data table can display the expected returns alongside their corresponding betas and other key metrics. This provides users with a detailed view of the data.

3) How are the assets correlated with each other?
  * serverside logic:
    1) Gather Data: already completed in the input phase
    2) Calculate the Mean Returns: calculate the mean return for each asset over the given period (Date range set 10 years)
    3) Calculate covariance between each asset
    4) calculate standard deviation between each asset
    5) calculate correlation between each asset
  * user interactive (name a few):
    1) A heatmap displaying the covariance matrix
  * User takeaway:
    1) Provides relationship between assets
    2) Insight into diversification risk
    3) Provides overlap insight (if data is highly correlated you lose diversification benefit)
     

* What constraints should be applied?
* How frequently should the portfolio be rebalanced?
* What is the investor's risk tolerance and investment horizon?
* What benchmarks should be used to evaluate the portfolio's performance?
* How will transaction costs impact the portfolio's performance?
* What optimization method will be used?

## Features

## Packages
The following packages were used:
1) library(tidyverse)
2) library(quantmod)
3) library(PerformanceAnalytics)
4) library(PortfolioAnalytics)
5) library(timetk)
6) library(tibbletime)
7) library(xts)
8) library(zoo)
9) library(tidyquant)


1. Interactive Line Charts
Time Series Analysis: Display interactive line charts for historical price data, showing trends over time.

Moving Averages: Add moving averages (e.g., 50-day, 200-day) to identify trends and potential buy/sell signals.

2. Performance Metrics
Returns: Calculate and display simple returns, CAGR, and annualized returns.

Volatility: Show measures of volatility, such as standard deviation and beta.

3. Sector Analysis
Sector Performance: Break down the index by sectors (e.g., technology, healthcare) and compare their performance.

Top/Bottom Performers: Highlight the top and bottom performing stocks within the index.

4. Fundamental Analysis
Earnings Per Share (EPS): Display EPS data for individual stocks.

Price-to-Earnings (P/E) Ratio: Compare P/E ratios to assess valuation.

Dividend Yield: Show dividend yield for income-focused analysis.

5. Technical Analysis
Relative Strength Index (RSI): Plot RSI to identify overbought or oversold conditions.

Bollinger Bands: Include Bollinger Bands to visualize price volatility and potential price movements.









$${\color{red} Disregard everything below this line, please, for me :D} $$


## Optimal Weights for a nth-asset portfolio (Minimum Variance)
I employed the Markowitz Mean-Variance as a framework for computing optimal weights. Our optimization objective is minimization: 

$$
Minimize (\sigma^2 = \vec{w}^\top \Sigma \vec{w})
$$

Weight constraint (total proportion of assets in portfolio must sum to 1. Ensures properly diversified and balanced portfolio. No underinvesting or overleveraging):

$$
\sum_{i=1}^{n} w_i = 1
$$

Box Constraint(limits weights of each assets within specified range between 0 to 1. Prevents overallocation in anyone asset -- ensures diversification:

$$
0 \leq w_i \leq 1 \quad \text{for all } i
$$

Objective:
* Create a portfolio with the lowest possible variance (risk) for a given level of return. 

Quadratic Problem with Linear Constraints:
* Variance formula is a quadratic function.
* Constraints are linear equations. 

Quadratic Programming (QP Solver):
* Since we are minimizing a quadratic function subject to linear constraints, we use a quadratic programming solver.
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.quadprog} $$ to solve quadratic programming problems.

PortfolioAnalytics Package:
* $${\color{red} optimize.portfolio()} $$: Function used to optimize the portfolio
* By setting the optimize_method = "ROI" a default solver will be selected based on optimization problem.
  *  $${\color{red} glpk} $$: Used for linear programming (LP) and Mixed-integer Linear Programming problems.
  *  $${\color{red} quadprog} $$: used for quadratic progrmaming problems. 

### Algorithm 
 * Assets will be imported from Yahoo Finance. Financial data is most commonly formatted in Time Series.
 * Convert daily prices to monthly return
 * Compute simple returns
 * create portfolio object
 * add constraints
 * add objective function
 * Optimize 

