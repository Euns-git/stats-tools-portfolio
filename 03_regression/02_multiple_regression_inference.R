# Regression Analysis | Multiple regression, extra sums of squares, partial F-tests
# Course datasets are not included. `dat` is a data frame with columns
# Y, X1, X2, X3 (placeholder names).

# 1. Multiple linear regression
full <- lm(Y ~ X1 + X2 + X3, data = dat)
summary(full)
anova(full)  # Sequential (Type I) sums of squares

# 2. Compare nested models using a partial F-test
# Test whether X2 and X3 improve fit after accounting for X1.
reduced <- lm(Y ~ X1, data = dat)
anova(reduced, full)
# H0: beta_X2 = beta_X3 = 0, conditional on X1.

# 3. Extra sum of squares from residual sums of squares
sse_reduced <- deviance(reduced)
sse_full <- deviance(full)
extra_ss <- sse_reduced - sse_full
partial_r2 <- extra_ss / sse_reduced
print(c(extra_sum_of_squares = extra_ss,
        partial_R2 = partial_r2))
# Partial R2: proportion of the reduced model's residual variation
# additionally explained by the added predictors.

# 4. Coefficient intervals and joint hypothesis testing
confint(full)
# anova(reduced, full) is valid only when both models use exactly
# the same observations.

# 5. Standardized regression coefficients
# Standardize numeric predictors and response before refitting.
# Do not apply scale() directly to factors.
standardized <- as.data.frame(scale(dat[c("Y", "X1", "X2", "X3")]))
fit_standardized <- lm(Y ~ X1 + X2 + X3, data = standardized)
coef(fit_standardized)
