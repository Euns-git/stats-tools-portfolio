# Correlated binary responses: GEE (marginal) versus GLMM (subject-specific)
# Data: Agresti, Introduction to Categorical Data Analysis
#   - high school students' use of alcohol, cigarettes and marijuana (matched triplets)
#   - teratology experiment (litters of rats)
# Packages: geepack, aod, lme4

library(geepack)
library(aod)
library(lme4)

# 1. Substance use: marginal model with exchangeable working correlation
# `dat_long`: one row per student x substance, columns id, drug, use.
fit_gee <- geeglm(use ~ drug, id = id, data = dat_long,
                  family = binomial, corstr = "exchangeable")
summary(fit_gee)

# Marginal homogeneity: both drug coefficients equal zero
L <- rbind(c(0, 1, 0),
           c(0, 0, 1))
wald.test(b = coef(fit_gee), Sigma = vcov(fit_gee), L = L)

# Subject-specific model with a random intercept, and LRT against the null model
m_glmm <- glmer(use ~ drug + (1 | id), data = dat_long, family = binomial)
summary(m_glmm)
m_null <- glmer(use ~ 1 + (1 | id), data = dat_long, family = binomial)
anova(m_null, m_glmm, test = "LRT")

# Estimated random-intercept standard deviation
VarCorr(m_glmm)
sigma2_hat <- as.numeric(VarCorr(m_glmm)$id)
sigma_hat  <- sqrt(sigma2_hat)
sigma_hat

# 2. Teratology: ignoring versus accounting for litter clustering
# `tera`: one row per litter, columns group, dead, alive, litter.
fit_glm <- glm(cbind(dead, alive) ~ group, family = binomial, data = tera)
summary(fit_glm)
exp(coef(fit_glm))

fit_gee <- geeglm(cbind(dead, alive) ~ group, family = binomial,
                  id = litter, corstr = "exchangeable", data = tera)
summary(fit_gee)

fit_glmm <- glmer(cbind(dead, alive) ~ group + (1 | litter),
                  family = binomial, data = tera)
summary(fit_glmm)
exp(fixef(fit_glmm))
