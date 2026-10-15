# Python and PyTorch for Statistical Modeling

Coursework in Python (NumPy, PyTorch) from Homework 1-7: array computation, automatic differentiation, gradient descent, and regression models trained by minimizing the negative log-likelihood. Course datasets are not included; Homework 6 uses simulated data and runs as is, while Homework 7 reads CSV files (`Boston.csv`, `warpbreaks.csv`, `Default_data.csv`).

## Topics and Code

| Topic | Methods | Code |
|---|---|---|
| NumPy and tensor basics | Broadcasting, concatenation, stacking and axis swaps, row-wise standardization with NaN, augmented design matrix, loops over tensors, run-length encoding | `01_numpy_and_torch_basics.py` |
| Autograd and gradient descent | Gradient accumulation, chain rule, score function by accumulated gradients, Jacobian, linear regression by gradient descent, `torch.optim.SGD`, `torch.nn.Linear` with and without optimizer, exponential-distribution quantile by `icdf` and by optimization | `02_autograd_and_gradient_descent.py` |
| Likelihood-based regression | Custom `nn.Module` with `forward` and NLL `loss`: Gaussian, Poisson, logistic regression; mini-batch SGD; test MSE and accuracy; comparison with `nn.Linear` | `03_likelihood_based_regression.py` |
| Models on real data | Gaussian regression (Boston housing), Poisson regression with dummy-coded predictors and AIC (warpbreaks), logistic regression with standardized predictors (Default) | `04_regression_models_real_data.py` |

## Example: Recovering known coefficients with custom likelihood models

**Problem.** Can a regression model written as a custom PyTorch module and trained by minimizing the negative log-likelihood recover the coefficients used to generate the data?

**Approach.** Simulated 2,000 observations (1,000 train, 1,000 test) from Gaussian, Poisson and Bernoulli models with known coefficients. Each model is an `nn.Module` with a `forward` method (mean, rate or probability) and a `loss` method (negative log-likelihood), trained with mini-batch SGD.

**Result.**

| Model | True coefficients | Estimated coefficients | Test result |
|---|---|---|---|
| Gaussian (sigma = 2) | 2.0, 0.8, -1.2, 3.0 | 1.86, 0.80, -1.28, 2.99 (sigma 1.79) | MSE 4.13 (4.07 with `nn.Linear`) |
| Poisson | -2.0, 0.4, -1.2, 1.0 | -2.00, 0.37, -1.18, 1.03 | MSE 0.417 |
| Logistic | -2.0, 0.4, -1.2, 1.0 | -2.16, 0.36, -1.20, 1.15 | Accuracy 0.799 |

In the gradient descent exercise (Homework 4-5), the estimates for the 20-observation linear regression (0.4672, 0.3583, -0.5565) matched the least-squares solution, and the 95th quantile of Exponential(rate = 1.3) found by gradient-based optimization (2.304) matched the analytic value -ln(0.05)/1.3 = 2.3044.

## Tools

Python, NumPy, PyTorch, pandas
