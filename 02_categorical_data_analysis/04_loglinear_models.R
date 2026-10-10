# Loglinear models for a four-way contingency table
# Data: MBTI personality scales (EI, SN, TF, JP); Agresti textbook data file, not included
# Packages: MASS

library(MASS)

mbti <- read.table("MBTI.dat", header = TRUE)
mbti4 <- mbti[, c("EI", "SN", "TF", "JP", "n")]
tab <- xtabs(n ~ EI + SN + TF + JP, data = mbti4)

# Homogeneous association model versus saturated model
fit_hom <- loglm(~ (EI + SN + TF + JP)^2, data = tab)
fit_sat <- loglm(~ EI * SN * TF * JP,     data = tab)
anova(fit_hom, fit_sat)

# Same model as a Poisson GLM, to read the pairwise association parameters
dat <- as.data.frame(tab)
fit_glm <- glm(Freq ~ (EI + SN + TF + JP)^2, family = poisson, data = dat)
summary(fit_glm)
