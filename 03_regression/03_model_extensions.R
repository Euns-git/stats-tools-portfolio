# Regression Analysis | Polynomial regression, interactions, prediction
# Course datasets are not included. `dat` is a data frame with columns
# Y, X1, X2 (placeholder names).

# 1. Linear versus quadratic regression
linear <- lm(Y ~ X1, data = dat)
quadratic <- lm(Y ~ X1 + I(X1^2), data = dat)
summary(quadratic)
anova(linear, quadratic)  # H0: quadratic coefficient = 0

# 2. Centering before polynomial modeling
dat$x1_centered <- dat$X1 - mean(dat$X1, na.rm = TRUE)
centered_quadratic <- lm(Y ~ x1_centered + I(x1_centered^2), data = dat)
summary(centered_quadratic)

# 3. Interaction between continuous predictors
additive <- lm(Y ~ X1 + X2, data = dat)
interaction <- lm(Y ~ X1 * X2, data = dat)
summary(interaction)
anova(additive, interaction)  # Test of the interaction term

# 4. Quantitative and qualitative predictors
# Requires a factor variable `group` in dat.
# dat$group <- factor(dat$group)
# group_interaction <- lm(Y ~ X1 * group, data = dat)

# 5. Confidence interval for mean response vs prediction interval
new_cases <- data.frame(X1 = c(1, 2, 3))
predict(linear, newdata = new_cases, interval = "confidence", level = 0.95)
predict(linear, newdata = new_cases, interval = "prediction", level = 0.95)
# The prediction interval includes observation-level variability,
# so it is wider than the confidence interval for the mean.

# 6. Visualize the fitted polynomial relationship
plot(dat$X1, dat$Y, xlab = "X1", ylab = "Y")
ord <- order(dat$X1)
lines(dat$X1[ord], fitted(quadratic)[ord], lwd = 2)
