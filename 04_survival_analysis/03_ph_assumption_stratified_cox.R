# Proportional hazards assumption and stratified Cox model
# Data: anderson (autoReg)
# Packages: survival, autoReg, survminer, dplyr

library(survival)
library(autoReg)
library(survminer)
library(dplyr)

data(anderson)

# 1. Log-log (cloglog) plots of Kaplan-Meier curves
#    Parallel curves support proportional hazards.
anderson <- anderson %>%
  mutate(logWBC_cat = factor(case_when(logWBC < 2.3 ~ "Low",
                                       logWBC < 3   ~ "Medium",
                                       TRUE         ~ "High"),
                             levels = c("Low", "Medium", "High")))

km_rx   <- survfit(Surv(time, status) ~ rx,         data = anderson)
km_wbc  <- survfit(Surv(time, status) ~ logWBC_cat, data = anderson)
km_sex  <- survfit(Surv(time, status) ~ sex,        data = anderson)

par(mfrow = c(1, 3))
plot(km_rx,  col = c("black", "red"), fun = "cloglog",
     xlab = "Time", ylab = "Log cumulative hazard", main = "Log-log KM by rx")
plot(km_wbc, col = c("black", "red", "blue"), fun = "cloglog",
     xlab = "Time", ylab = "Log cumulative hazard", main = "Log-log KM by logWBC")
plot(km_sex, col = c("black", "red"), fun = "cloglog",
     xlab = "Time", ylab = "Log cumulative hazard", main = "Log-log KM by sex")
par(mfrow = c(1, 1))

# 2. Observed (KM) versus expected (Cox model) survival curves
cox_rx  <- coxph(Surv(time, status) ~ rx,  data = anderson)
cox_sex <- coxph(Surv(time, status) ~ sex, data = anderson)

par(mfrow = c(1, 2))
plot(km_rx, col = c("black", "red"), main = "Observed (KM): rx")
plot(survfit(cox_rx,  newdata = data.frame(rx  = c(0, 1))),
     col = c("black", "red"), main = "Expected (Cox): rx")
plot(km_sex, col = c("black", "red"), main = "Observed (KM): sex")
plot(survfit(cox_sex, newdata = data.frame(sex = c(0, 1))),
     col = c("black", "red"), main = "Expected (Cox): sex")
par(mfrow = c(1, 1))

# 3. Schoenfeld residual test
cox_full <- coxph(Surv(time, status) ~ logWBC + rx + sex,
                  data = anderson, ties = "breslow")
summary(cox_full)
ph_test <- cox.zph(cox_full)
ph_test
ggcoxzph(ph_test)

# 4. Stratified Cox model: stratify on sex (no-interaction model)
cox_strata <- coxph(Surv(time, status) ~ strata(sex) + logWBC + rx,
                    data = anderson, ties = "breslow")
summary(cox_strata)

# 5. LR test for rx in the stratified model (df = 1)
cox_strata_no_rx <- coxph(Surv(time, status) ~ strata(sex) + logWBC,
                          data = anderson, ties = "breslow")
lr_rx <- -2 * (cox_strata_no_rx$loglik[2] - cox_strata$loglik[2])
lr_rx
pchisq(lr_rx, df = 1, lower.tail = FALSE)

# 6. Stratified model with interaction: does the effect of rx / logWBC differ by sex?
#    LR test of no-interaction vs interaction (df = 2)
cox_strata_int <- coxph(Surv(time, status) ~ strata(sex) + logWBC + rx +
                          rx:sex + logWBC:sex,
                        data = anderson, ties = "breslow")
summary(cox_strata_int)
lr_int <- -2 * (cox_strata$loglik[2] - cox_strata_int$loglik[2])
lr_int
pchisq(lr_int, df = 2, lower.tail = FALSE)

# 7. Separate fits by sex (equivalent to a fully interacted stratified model)
#    Check the coding of sex in your data (?anderson) before labelling groups.
fit_sex0 <- coxph(Surv(time, status) ~ logWBC + rx,
                  data = subset(anderson, sex == 0), ties = "breslow")
fit_sex1 <- coxph(Surv(time, status) ~ logWBC + rx,
                  data = subset(anderson, sex == 1), ties = "breslow")
fit_sex0
fit_sex1
