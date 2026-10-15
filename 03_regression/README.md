# Regression Analysis

Coursework in R from an undergraduate regression analysis course (Department of Statistics, Ewha Womans University). Scripts cover the assignments on diagnostics, multiple regression inference, and model extensions. Course datasets are not included, so the scripts use placeholder variable names (`Y`, `X1`, `X2`, `X3`).

## Topics and Code

| Topic | Methods | Code |
|---|---|---|
| Regression diagnostics | Residual and normal Q-Q plots, Breusch-Pagan test, lack-of-fit test, Box-Cox transformation | `01_regression_diagnostics.R` |
| Multiple regression and inference | Regression ANOVA, partial F-tests, extra sums of squares, nested model comparison, partial R-squared, standardized coefficients | `02_multiple_regression_inference.R` |
| Model extensions | Polynomial regression, centering, interaction terms, quantitative-by-qualitative interaction, confidence vs prediction intervals | `03_model_extensions.R` |

Concept notes on model selection and validation (predictor reduction, fit vs complexity, validation) are in `model_selection_validation.md`.

## Example: Checking assumptions and testing added predictors

**Problem.** Are the assumptions of a multiple linear regression model reasonable, and do additional predictors improve the fit beyond a simpler model?

**Approach.** Fit `lm(Y ~ X1 + X2 + X3)`; inspect residual and Q-Q plots; test constant error variance with `bptest`; if the variance is not constant or the mean function does not fit, consider a Box-Cox transformation of `Y`. Then compare the nested models `Y ~ X1` and `Y ~ X1 + X2 + X3` with a partial F-test (`anova(reduced, full)`) and compute the partial R-squared of the added predictors.

## Reference

Kutner MH, Nachtsheim CJ, Neter J, Li W. *Applied Linear Statistical Models*. 5th ed. McGraw-Hill/Irwin; 2004.
