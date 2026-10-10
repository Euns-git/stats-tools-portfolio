# Kaplan-Meier estimation and cumulative hazard comparison
# Data: MASS::gehan (6-MP vs. control, leukemia remission times)
# Packages: survival, MASS, survminer
# install.packages(c("MASS", "survminer"))  # run once if not installed

library(survival)
library(MASS)
library(ggplot2)
library(survminer)

data(gehan)

# 1. Survival object and overall Kaplan-Meier estimate
my.surv <- Surv(gehan$time, gehan$cens)
km.fit <- survfit(my.surv ~ 1)
summary(km.fit)
plot(km.fit, main = "Kaplan-Meier estimate with 95% confidence bounds",
     xlab = "Time", ylab = "Survival function")

# 2. Cumulative hazard curve
ggsurvplot(km.fit, data = gehan, fun = "cumhaz")

# 3. Two estimators of the cumulative hazard
# H.hat: -log of the Kaplan-Meier survival estimate
# H.tilde: Nelson-Aalen estimator, cumulative sum of (events / at risk)
H.hat <- -log(km.fit$surv)
H.hat <- c(H.hat, tail(H.hat, 1))   # extend the last step to t = 50
h.step <- km.fit$n.event / km.fit$n.risk
H.tilde <- cumsum(h.step)
H.tilde <- c(H.tilde, tail(H.tilde, 1))
plot(c(km.fit$time, 50), H.hat, type = "s",
     xlab = "Time", ylab = "Cumulative hazard",
     main = "Comparing cumulative hazard estimators",
     ylim = range(c(H.hat, H.tilde)))
points(c(km.fit$time, 50), H.tilde, type = "s", lty = 2)
legend("topleft", legend = c("H.hat (-log KM)", "H.tilde (Nelson-Aalen)"), lty = 1:2)

# 4. Kaplan-Meier curves by treatment group, with log-rank test
fit.2 <- survfit(Surv(time, cens) ~ treat, data = gehan)
summary(fit.2)
ggsurvplot(fit.2, data = gehan, conf.int = TRUE, pval = TRUE, risk.table = TRUE)
