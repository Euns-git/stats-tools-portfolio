# Cox proportional hazards regression
# Data: anderson (autoReg) - leukemia remission times with treatment (rx),
#       log white blood cell count (logWBC) and sex
# Packages: survival, autoReg, survminer, broom, ggplot2
# install.packages(c("autoReg", "survminer", "broom"))  # run once if not installed

library(survival)
library(autoReg)
library(survminer)
library(broom)
library(ggplot2)

data(anderson)
head(anderson)

# 1. Models: treatment only, + logWBC, + interaction (Breslow ties)
cox_rx      <- coxph(Surv(time, status) ~ rx,          data = anderson, ties = "breslow")
cox_rx_wbc  <- coxph(Surv(time, status) ~ rx + logWBC, data = anderson, ties = "breslow")
cox_rx_x_wbc <- coxph(Surv(time, status) ~ rx * logWBC, data = anderson, ties = "breslow")
summary(cox_rx)
summary(cox_rx_wbc)
cox_rx_x_wbc

# 2. Interaction: likelihood ratio test
anova(cox_rx_wbc, cox_rx_x_wbc)

# 3. Hazard ratios with 95% CI
exp(confint(cox_rx_wbc))
tidy(cox_rx_wbc, exponentiate = TRUE, conf.int = TRUE)
ggforest(cox_rx_wbc, data = anderson)

# 4. Log-rank test for treatment
survdiff(Surv(time, status) ~ rx, data = anderson)

# 5. Tie handling: Breslow vs Efron
cox_breslow <- coxph(Surv(time, status) ~ rx + logWBC, data = anderson, ties = "breslow")
cox_efron   <- coxph(Surv(time, status) ~ rx + logWBC, data = anderson, ties = "efron")
cox_breslow
cox_efron

# 6. Estimated baseline survival function (rx = 0, logWBC = 0)
par(mfrow = c(1, 3))
plot(survfit(cox_rx,        newdata = data.frame(rx = 0, logWBC = 0)),
     xlab = "Time", ylab = "S0(t), rx only",
     main = "Baseline survival: rx")
plot(survfit(cox_rx_wbc,    newdata = data.frame(rx = 0, logWBC = 0)),
     xlab = "Time", ylab = "S0(t), rx + logWBC",
     main = "Baseline survival: rx + logWBC")
plot(survfit(cox_rx_x_wbc,  newdata = data.frame(rx = 0, logWBC = 0)),
     xlab = "Time", ylab = "S0(t), rx * logWBC",
     main = "Baseline survival: rx * logWBC")
par(mfrow = c(1, 1))

# 7. Adjusted survival curves by treatment at the mean logWBC (2.93)
new_df <- data.frame(rx = c(0, 1), logWBC = c(2.93, 2.93))
adj_fit <- survfit(cox_rx_wbc, newdata = new_df)
ggsurvplot(adj_fit, data = anderson, surv.median.line = "hv")
