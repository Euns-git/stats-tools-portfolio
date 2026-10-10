# Regression Analysis | Regression diagnostics and remedial measures
# Course datasets are not included. `dat` is a data frame with columns
# Y, X1, X2, X3 (placeholder names).
# Packages: lmtest, MASS

# 1. Fit a multiple linear regression model
fit <- lm(Y ~ X1 + X2 + X3, data = dat)
summary(fit)
anova(fit)

# 2. Graphical checks: residuals, fitted values, normal Q-Q
par(mfrow = c(2, 2))
plot(fit)  # Residuals vs fitted, Q-Q, scale-location, leverage
par(mfrow = c(1, 1))
plot(residuals(fit), type = "b", xlab = "Observation", ylab = "Residual")
abline(h = 0, lty = 2)
qqnorm(residuals(fit)); qqline(residuals(fit))

# 3. Constant variance: Breusch-Pagan test
# H0: constant error variance
lmtest::bptest(fit)

# 4. Lack-of-fit test (requires replicated values of X)
# linear_fit     <- lm(Y ~ X1, data = dat)
# pure_error_fit <- lm(Y ~ factor(X1), data = dat)
# anova(linear_fit, pure_error_fit)
# A significant result suggests the linear mean function does not fit.

# 5. Response transformation: Box-Cox (requires Y > 0)
# MASS::boxcox(fit, lambda = seq(-2, 2, by = 0.1))
# Refit with the transformation suggested by the profile, e.g. lambda = 0:
# fit_log <- lm(log(Y) ~ X1 + X2 + X3, data = dat)
# plot(fit_log)
