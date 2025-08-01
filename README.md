# Portfolio Optimization with Modern Portfolio Theory (R)

This project, implemented in the R programming language, explores the application of Modern Portfolio Theory (MPT) to a selection of big tech stocks. By using mean-variance optimization, I demonstrate how to construct portfolios that aim to maximize returns, minimize risk, and optimize for risk-adjusted return (Sharpe Ratio).

## Shiny App Link: https://williambrothers.shinyapps.io/Portfolio_Optimization/

##  Project Overview
Interested in leveraging the stock market, I aimed to understand and apply quantitative methods for building and managing a stock portfolio. This project serves as a guide and proof-of-concept for implementing portfolio optimization, using a diverse set of tech stocks known for their high growth potential.


## Methodology
### Data Acquisition and Preprocessing
* Data Source: Historical daily stock data for the following tech companies was obtained from Yahoo Finance using the quantmod API in R:

  * Apple Inc. (AAPL)
  
  * Microsoft Corp. (MSFT)
  
  * NVIDIA Corp. (NVDA)
  
  * Alphabet Inc. (GOOGL)
  
  * Amazon.com Inc. (AMZN)
  
  * META Platforms Inc. (META)
  
  * Tesla Inc. (TSLA)
  
  * Oracle Corp. (ORCL)
  
  * Salesforce Inc. (CRM)
  
  * Adobe Inc. (ADBE)

* Period: The analysis covers the period from February 2007 to February 2025. (Period subject to change on the app due to api restrictions)

* Data Cleaning:

  * The **Adjusted Daily Close** price was used to account for stock splits, dividends, and other corporate actions.
  
  * The daily prices were converted into **monthly returns**, which is a conventional and stable time frame for portfolio analysis.

* Libraries: The following R packages were integral to the analysis: **TidyQuant**, **quantmod**, **PortfolioAnalytics**, **PerformanceAnalytics**, and **HighCharter**.

## Framework: Modern Portfolio Theory (MPT)

MPT provides a framework for assembling a portfolio of assets in such a way that the expected return is maximized for a given level of risk. This is achieved by carefully selecting the weights of each asset. The core of this project focuses on solving three distinct optimization problems, each requiring a different type of mathematical solver.

# Optimal Weights for a nth-asset portfolio (Minimum Variance)
Our optimization objective is Minimization: 

$$
Minimize (\sigma^2 = \vec{w}^\top \Sigma \vec{w})
$$

Full Investment constraint (total proportion of assets in portfolio must sum to 1. No Short selling (negative positions) or leveraging (positions larger than 1) allowed.

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint(limits weights of each assets within specified range between 0 to 1. Prevents overallocation in anyone asset.

$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$$

Quadratic Problem with Linear Constraints:
* Constraints are linear equations.
* Variance formula is a quadratic function.

Quadratic Programming (QP Solver):
* Since we are minimizing a quadratic function subject to linear constraints, we use a quadratic programming solver.
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.quadprog} $$ to solve quadratic programming problems.


Objective:
* Create a portfolio with the lowest possible variance (risk) for a given level of return.
* Add Constraints (Box Constraint, Full Investment)
* Add objective: Minimization
* Optimize: Computes optimal weights for minimal possible variance
* Weighted Returns: multiply the previously computed monthly returns by optimal weights
* Outcome: Optimal weights for minimizing risk given a level of return (global variance portfolio)

# Optimal Weights for a nth-asset portfolio (Maximization Expected Return)
Our optimization objective is Maximization: 

$$
Maximize: Maximize (\vec{\mu}^\top \vec{w})
$$

Full Investment Constraint:

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint:

$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$$


 Linear Problem with Linear Constraints:
* Expected Return formula is a linear function.
* Constraints are linear functions.

Linear Programming Solver (LP Solver):
* Since we are maximizing a linear function subject to linear constraints, we use a linear programming solver.
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.Rglpk} $$ to solve linear programming problem.


Objective:
* Create a portfolio with the highest possible return for a given level of risk.
* Add Constraints (Box Constraint, Full Investment)
* Add objective: Maximization
* Optimize: Computes optimal weights for maximal possible expected return
* Weighted Returns: multiply the previously computed monthly returns by the optimal weights
* Outcome: Optimal weights for maximizing expected return given a level of risk (global variance portfolio)



# Optimal Weights for a nth-asset portfolio (Maximizing Risk Adjusted return)
Our optimization objective is Maximizing our Risk Adjusted Return (Sharpe Ratio): 


$$
\text{Maximize} \quad \frac{\sum_{i=1}^{n} w_i E(R_i) - R_f}{\sqrt{\sum_{i=1}^{n} \sum_{j=1}^{n} w_i w_j \sigma_{ij}}}
$$


Full Investment Constraint:

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint:

$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$$


Both linear and Quadratic components.
* Linear function in the numerator (expected return minus risk-free rate)
* Quadratic function in the denominator (standard deviation of the portfolio, which depends on the covariance matrix of asset returns).

NonLinear Programming Solver (NLP Solver):
* Since we are Maximizing a linear function and Minimizing a quadratic function 
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.nloptr} $$ to solve linear programming problem.


Objective:
* Create a portfolio with the maximal Risk Adjusted Return
* Add Constraints (Box Constraint, Full Investment)
* Add Objective: Maximization
* Add Objective: Minimization
* Optimize: Computes optimal weights for maximal possible Risk Adjusted Expected Return 
* Weighted Returns: multiply the previously computed monthly returns by the optimal weights
* Outcome: Optimal weights for maximizing Risk Adjusted Return


# Results

The optimization process yielded three distinct portfolios, each optimized for a different objective. The performance metrics below were generated using a starting balance of $5,000 over the analysis period.

### 1. Minimum Volatility Portfolio
This portfolio was optimized to minimize risk (standard deviation) above all else.

#### Weights:

<img width="161" height="294" alt="Screenshot 2025-08-01 125725" src="https://github.com/user-attachments/assets/86c08f88-5b87-4b3a-9ddf-4f2d99b1dead" />

#### Metrics:

* Date Range: June 2012 - Present

* Start Balance: $5,000

* End Balance: $494,610.73

* CAGR: 20%

* Expected Return: 21%

* Standard Deviation (Risk): 17%

* Max Drawdown: 35%

* Sharpe Ratio: 0.85

Key Takeaway: This portfolio delivered the most stable performance with the lowest volatility and maximum drawdown. It sacrifices some return for a much smoother, less stressful investment journey, aligning best with a highly risk-averse strategy.


### 2. Maximum Return Portfolio
This portfolio was optimized to maximize expected return, resulting in a highly aggressive asset allocation.

#### Weights:
<img width="166" height="296" alt="Screenshot 2025-08-01 125700" src="https://github.com/user-attachments/assets/ecb4edbb-6bb6-45b8-b032-7ab88d9b2888" />

#### Metrics:

* Date Range: June 2012 - Present

* Start Balance: $5,000

* End Balance: $6,412,400.93

* CAGR: 46%

* Expected Return: 59%

* Standard Deviation (Risk): 42%

* Max Drawdown: 70%

* Sharpe Ratio: 1.02

Key Takeaway: While this portfolio delivered the highest growth, its extremely high volatility and significant maximum drawdown of 70% make it unsuitable for risk-averse investors.


### 3. Maximum Risk-Adjusted Return Portfolio (Sharpe Ratio)
This portfolio was designed to find the optimal balance between risk and return, maximizing the Sharpe Ratio.

#### Weights:

<img width="162" height="300" alt="Screenshot 2025-08-01 125746" src="https://github.com/user-attachments/assets/c2eb267c-3c1a-415f-9de0-7a6abda1f78e" />

#### Metrics:

  * Date Range: June 2012 - Present

  * Start Balance: $5,000
  
  * End Balance: $1,670,133.33
  
  * CAGR: 32%
  
  * Expected Return: 35%
  
  * Standard Deviation (Risk): 24%
  
  * Max Drawdown: 49%
  
  * Sharpe Ratio: 1.09

Key Takeaway: This portfolio provided a superior risk-adjusted return compared to the other two. It achieved strong growth with a significantly lower maximum drawdown and volatility than the maximum return portfolio, making it a well-balanced choice.

# Conclusion

### How did the optimized portfolios perform in terms of risk, return, and risk-adjusted return?

* **Minimum Volatility Portfolio**: This was the most conservative portfolio, focusing on assets that contributed least to overall variance. It successfully minimized risk, with the lowest Standard Deviation (17%) and Max Drawdown (35%). Its returns were the most modest, with a 20% CAGR and a 21% Expected Return. The Sharpe Ratio of 0.85 was the lowest of the three, reflecting its primary objective of risk reduction over efficiency. The portfolio's key holdings were in MSFT (34.1%), ORCL (29.4%), and GOOGL (22.9%), which were likely identified as having stable returns and/or low correlations with each other.

* **Maximum Return Portfolio** (100% NVDA): This portfolio was the most aggressive and highly concentrated, betting entirely on the best-performing asset. It achieved the highest absolute returns with a staggering 46% Compound Annual Growth Rate (CAGR) and a 59% Expected Return. However, this came with the highest risk, as shown by a 42% Standard Deviation and a severe 70% Max Drawdown. Its Sharpe Ratio of 1.02 was positive but not the highest, indicating that this portfolio, despite its massive gains, did not provide the best return for the amount of risk taken.

* **Maximum Risk-Adjusted Return Portfolio (Sharpe Ratio)**: This portfolio found the optimal balance between risk and return, maximizing the Sharpe Ratio. It delivered a strong 32% CAGR and a 35% Expected Return, which were lower than the Maximum Return portfolio but achieved with substantially less risk (24% Standard Deviation and 49% Max Drawdown). Its Sharpe Ratio of 1.09 was the highest of the three, confirming that it provided the best risk-adjusted return. This portfolio's key holdings were in MSFT (47.8%) and NVDA (29.4%), showing that the optimizer combined a high-growth asset with a more stable one to achieve a superior balance.

### Did the weights shift significantly between the different optimization objectives?

* Maximum Return vs. Others: The most striking shift is the move from a completely concentrated portfolio (100% NVDA) to more diversified ones. The Maximum Return portfolio's allocation is a pure momentum bet, disregarding diversification completely in its single-minded pursuit of the highest historical return.

* Minimum Volatility vs. Maximum Sharpe Ratio: There is a clear and intentional reallocation of weights between these two objectives.

   * The Minimum Volatility portfolio is heavily weighted toward stable, less-correlated assets like MSFT (34.1%), ORCL (29.4%), and GOOGL (22.9%), while completely excluding the highly volatile NVDA and TSLA.

   * The Maximum Sharpe Ratio portfolio, in contrast, strategically introduces a significant 29.4% allocation to NVDA and a small 6.1% to TSLA. It does this by drastically increasing its MSFT holding to 47.8% and completely eliminating ORCL. This demonstrates the optimizer's finding that the high returns of NVDA and TSLA could be included in a way that, when combined with a large allocation to a stable asset like MSFT, results in a more efficient portfolio overall.
 

### What were the key takeaways about applying MPT to this specific set of tech stocks?

 * MPT's "Maximum Return" objective is a warning, not a strategy: When applied to a set of stocks with a single clear outperformer (like NVDA), the optimization for maximum return allocates all capital to that one asset. This shows that the objective function, in its pure form, completely disregards diversification and simply identifies the single best historical performer. This is a crucial lesson that optimization for raw return is highly risky and often leads to an undiversified portfolio.
 
 * Diversification is key to managing risk, even within a sector: The Minimum Volatility portfolio successfully reduced risk by diversifying across less volatile assets like MSFT, ORCL, and GOOGL, and entirely avoiding high-beta stocks like NVDA and TSLA. This shows that even within a highly correlated sector like tech, MPT can still find diversification benefits.
 
 * The Sharpe Ratio provides the most balanced portfolio: The Maximum Sharpe Ratio portfolio found the "sweet spot" by combining the high-growth potential of NVDA and TSLA with the stability of MSFT and META. This is the most practical and useful outcome of MPT, confirming that for most investors, optimizing for risk-adjusted return is a more prudent and well-rounded strategy than simply chasing the highest possible return.

### Acknowledge the limitations of MPT
* Reliance on Historical Data
* Assumption of a Normal Distribution
* Focus on Variance as a Measure of Risk
* Single-Period Model

