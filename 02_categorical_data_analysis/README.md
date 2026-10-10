Categorical Data Analysis

Coursework in R from an undergraduate categorical data analysis course (Department of Statistics, Ewha Womans University), working through exercises in Agresti, An Introduction to Categorical Data Analysis. Textbook data files are not included.

Topics and Code
Topic	Methods	Code
Logistic regression	Odds ratios, average marginal effects, grouped vs ungrouped data, quadratic terms, classification table, ROC/AUC, interaction models	01_logistic_regression.R
Model selection and separation	Likelihood-ratio tests, backward elimination (AIC), exhaustive search (BIC), complete and quasi-complete separation	02_model_selection.R
Ordinal outcomes	Cumulative logit (proportional odds) model, interaction test by deviance difference	03_ordinal_logit.R
Loglinear models	Homogeneous association vs saturated model, Poisson GLM	04_loglinear_models.R
Correlated binary data	GEE (exchangeable), Wald test of marginal homogeneity, random-intercept GLMM, GEE vs GLMM comparison	05_gee_glmm.R
Bootstrap inference	Parametric bootstrap LRT for a random-intercept variance	06_bootstrap_glmm_lrt.R
Example: Testing a random-effect variance with a parametric bootstrap

Problem. Does a model for repeated binary responses need a subject-level random intercept (H0: σ² = 0)? Under H0 the variance sits on the boundary of the parameter space, so the χ² reference distribution for the LRT does not apply.

Approach. Simulated 500 data sets from the fitted GLM (the null model), refit the GLM and the random-intercept GLMM on each, and used the 500 LRT statistics as the null distribution.

Result. The observed LRT statistic was 1116.8, while the largest of the 500 bootstrap statistics was 6.65, giving a bootstrap p-value below 0.002 (0 of 500). The estimated random-intercept standard deviation was 3.02.

Application in Research

The ordinal regression methods studied in this course provided a foundation for my KNHANES-based research on glycemic status, in which I applied a partial proportional odds model.

I am also exploring a follow-up research project on post-stroke outcomes, including prognosis, recurrence, and mortality, among ischemic stroke patients with and without metabolic conditions.

Reference

Agresti A. An Introduction to Categorical Data Analysis. Wiley.