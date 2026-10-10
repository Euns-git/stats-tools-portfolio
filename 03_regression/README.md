# Regression Analysis — Selected Coursework

**Department of Statistics, Ewha Womans University**  
**Language:** R  
**Type:** Undergraduate Coursework

## Overview

This repository presents selected R implementations and statistical concepts from an undergraduate Regression Analysis course.

The coursework covered the theoretical foundations of linear regression, statistical inference, regression diagnostics, multiple regression, model extensions, and model selection.

Rather than presenting an independent research project, this repository documents my understanding of regression modeling and its implementation in R through selected assignments.

**Note:** Original assignment datasets are not included. Code snippets and selected outputs are provided to illustrate the analytical procedures practiced during the course. The repository is not intended to be a fully reproducible analysis pipeline.

## 1. Regression Fundamentals

**Topics studied**
- Ordinary least squares (OLS) estimation
- Simple linear regression
- Confidence intervals and hypothesis testing for regression coefficients
- Analysis of variance (ANOVA) and F-tests
- Matrix representation of linear regression

These topics provided the mathematical and inferential foundation for subsequent regression modeling.

## 2. Regression Diagnostics

**Related assignments:** HW3–HW4

**Methods practiced**
- Residual plots and normal Q–Q plots
- Assessment of normality and constant error variance
- Breusch–Pagan tests for heteroscedasticity
- Lack-of-fit tests
- Box–Cox transformations

**R implementation:** `scripts/01_regression_diagnostics.R`

**Focus:** Evaluating model assumptions and identifying situations in which model refinement or transformation may be necessary.

## 3. Multiple Regression and Statistical Inference

**Related assignments:** HW4–HW5

**Methods practiced**
- Multiple linear regression using `lm()`
- Regression ANOVA
- Partial F-tests and extra sums of squares
- Comparisons of nested regression models
- Partial coefficients of determination
- Standardized regression coefficients

**R implementation:** `scripts/02_multiple_regression_inference.R`

**Focus:** Assessing the contribution of individual predictors and groups of predictors while accounting for other variables in a regression model.

## 4. Model Extensions

**Related assignment:** HW6

**Methods practiced**
- Polynomial regression
- Centering of continuous predictors
- Interaction terms
- Comparison of models with different functional forms
- Confidence intervals and prediction intervals

**R implementation:** `scripts/03_model_extensions.R`

**Focus:** Extending linear regression to represent nonlinear relationships and interactions between predictors.

## 5. Model Selection and Validation

**Related lecture:** Chapter 9 — Model Selection and Validation

**Concepts studied**
- Predictor reduction and model refinement
- Model fit versus model complexity
- Variable selection strategies
- Model validation and generalizability
- The distinction between model selection and model assessment

Nested model comparisons were practiced through R assignments. Other concepts are documented as theoretical coursework rather than independent implementations.

**Notes:** `notes/model_selection_validation.md`

## Repository Contents

| File | Description |
|---|---|
| `01_regression_diagnostics.R` | Selected R code for model diagnostics and transformations |
| `02_multiple_regression_inference.R` | Multiple regression, partial F-tests, and nested model comparisons |
| `03_model_extensions.R` | Polynomial regression, interaction terms, and prediction |
| `model_selection_validation.md` | Conceptual notes on model building and validation |

## Scope and Limitations

This repository is a curated record of undergraduate coursework, not an independent research project.

The original datasets and assignment documents are not distributed. Selected R code and corresponding results are included for educational portfolio purposes.

The primary objective is to demonstrate familiarity with regression analysis, statistical reasoning, and the interpretation of R outputs.