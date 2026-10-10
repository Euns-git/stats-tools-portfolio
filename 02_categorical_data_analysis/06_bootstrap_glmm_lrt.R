# Parametric bootstrap likelihood-ratio test for a random-intercept variance
# H0: sigma^2 = 0  vs  HA: sigma^2 > 0
# The null value lies on the boundary of the parameter space, so the usual
# chi-square reference distribution for the LRT is not appropriate.
# Data: `dat_long` (id, drug, use) from 05_gee_glmm.R
# Packages: lme4

library(lme4)

# Observed LRT statistic: GLMM with random intercept vs GLM without
m_glm  <- glm(use ~ drug, data = dat_long, family = binomial)
m_glmm <- glmer(use ~ drug + (1 | id), data = dat_long, family = binomial)
T_obs <- 2 * (logLik(m_glmm) - logLik(m_glm))
T_obs

# Bootstrap the null distribution: simulate from the fitted null (GLM) model,
# refit both models on each simulated data set, and recompute the LRT
set.seed(2025)
B <- 500
T_boot <- numeric(B)
p_hat <- fitted(m_glm)

for (b in 1:B) {
  y_star <- rbinom(length(p_hat), size = 1, prob = p_hat)
  dat_star <- dat_long
  dat_star$use <- y_star
  m_glm_star  <- glm(use ~ drug,
                     data = dat_star, family = binomial)
  m_glmm_star <- glmer(use ~ drug + (1 | id),
                       data = dat_star, family = binomial)
  T_boot[b] <- 2 * (logLik(m_glmm_star) - logLik(m_glm_star))
}

# Bootstrap p-value
p_boot <- mean(T_boot >= as.numeric(T_obs))
p_boot

summary(T_boot)
any(is.na(T_boot))
