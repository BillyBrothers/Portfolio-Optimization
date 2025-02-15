# Portfolio Optimization

##  Motivation
I, like a lot of people, am interested in money and wanted to figure out how to make more and manage it better in a controlled environment. Real estate is too expensive. Stocks are feasible. I desired investigating the stock market. I chose tech stocks because they grow the fastest. I implemented portfolio optimization as a guide and proof.


## Data
- Apple Inc, “AAPL”
- "Microsoft Corp, “MSFT"
-  NVIDIA Corp, "NVDA" 
- Alphabet Inc, "GOOGL" 
- Amazon.com Inc "AMZN" 
- META Platforms Inc "META" 
- Tesla Inc "TSLA" 
- Oracle Corp, "ORCL, 
- Salesforce Inc, "CRM" 
- Adobe Inc "ADBE" 


## Data Info
**Source**: Yahoo Finance - imported via QuantMod API function
**Dates**: February 2007 - February 2025 (only free available data)
*Note**: All Data is historical

**Libraries** (Most important):
Tidy Quant
- QuantMod
- PortfolioAnalytics
- PerformanceAnalytics
- HighCharter
- TidyQuant

## Data Question

**As a risk averse investor, can I discover the the best way to maximize returns and minimize risk with fast growing tech stocks**

## Data Importation

**Initial Step**:
- Import all time series stock data into a single xts object
- Clean
- Keep Adjusted Daily Close stock price (accounts for stock splits, dividends, and corporate initiatives)
- Compute monthly returns (conventional time frame)


## Framework
Mean-Variance Modern Portfolio Theory (MPT) aims to maximize the return of a portfolio for a given level of risk, or equivalently, minimize the risk for a given level of expected return. The formula used to achieve this is based on optimizing the weights of the assets in the portfolio.

## Optimal Weights for a nth-asset portfolio (Minimum Variance)
Our optimization objective is minimization: 

$$
Minimize (\sigma^2 = \vec{w}^\top \Sigma \vec{w})
$$

Full Investment constraint (total proportion of assets in portfolio must sum to 1. Ensures properly diversified and balanced portfolio. No Short selling (negative positions) or leveraging (positions larger than 1) allowed.

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint(limits weights of each assets within specified range between 0 to 1. Prevents overallocation in anyone asset -- ensures diversification:

$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$

Quadratic Problem with Linear Constraints:
* Constraints are linear equations.
* Variance formula is a quadratic function.

Quadratic Programming (QP Solver):
* Since we are minimizing a quadratic function subject to linear constraints, we use a quadratic programming solver.
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.quadprog} $$ to solve quadratic programming problems.


Objective:
* Create a portfolio with the highest possible variance (risk) for a given level of return.
* Add Constraints (Box Constraint, Full Investment)
* Add objective: Maximization
* Optimize: Computes optimal weights for maximal expected return
* Weighted Returns: multiply the previously computed monthly returns by optimal weights
* Outcome: Optimal weights for minimizing risk (global variance portfolio)


## Optimal Weights for a nth-asset portfolio (Maximization Expected Return)
Our optimization objective is maximization: 

$$
Maximize: Maximize (\vec{\mu}^\top \vec{w})
$$

Full Investment constraint

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint
$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$


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


# Opitmal Weights for a nth-asset portfolio (Maximizing Risk Adjusted return)
Our optimization objective is Maximizing our Risk Adjusted Return (Sharpe Ratio): 


$$
\text{Maximize} \quad \frac{\sum_{i=1}^{n} w_i E(R_i) - R_f}{\sqrt{\sum_{i=1}^{n} \sum_{j=1}^{n} w_i w_j \sigma_{ij}}}
$$


Full Investment constraint

$$
\text{subject to:} \quad \sum_{i=1}^{n} w_i = 1
$$

Box Constraint
$$
\text{subject to:} \quad L_i \leq w_i \leq U_i \quad \text{for all } i
$


Both linear and Quadratic components. The Sharpe Ratio itself is a 
* Linear function in the numerator (expected return minus risk-free rate) and a
* Quadratic function in the denominator (standard deviation of the portfolio, which depends on the covariance matrix of asset returns).

NonLinear Programming Solver (NLP Solver):
* Since we are maximizing a linear function and mininmzing 
* $${\color{red} PortfolioAnalytics} $$: package implements $${\color{red} ROI.plugin.nloptr} $$ to solve linear programming problem.


Objective:
* Create a portfolio with the highest possible return for a given level of risk.
* Add Constraints (Box Constraint, Full Investment)
* Add objective: Maximization
* Add Objective: Minization
* Optimize: Computes optimal weights for maximal possible risk adjusted expected return 
* Weighted Returns: multiply the previously computed monthly returns by the optimal weights








