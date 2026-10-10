# Logistic regression: interpretation, marginal effects, classification, ROC
# Data: Agresti, Introduction to Categorical Data Analysis (textbook data files, not included)
# Packages: pROC

library(pROC)
invlogit <- function(x) 1 / (1 + exp(-x))

# 1. Cancer remission (y = remission, LI = labeling index)
# `y` and `LI` are the remission data from the textbook table.
fit <- glm(y ~ LI, family = binomial)
beta <- coef(fit)[2]
p_i <- invlogit(coef(fit)[1] + coef(fit)[2] * LI)
AME <- mean(beta * p_i * (1 - p_i))   # average marginal effect of LI
AME

# Grouped-data format (one row per LI value): same estimates, different deviance
tab <- aggregate(y ~ LI, FUN = function(z) c(sum = sum(z), n = length(z)))
tab <- do.call(data.frame, tab)
colnames(tab) <- c("LI", "succ", "n")
fit_grp <- glm(cbind(succ, n - succ) ~ LI, data = tab, family = binomial)
summary(fit_grp)

# 2. Space shuttle O-ring distress and temperature
shuttle_data <- read.table("Shuttle.dat", header = TRUE)
fit <- glm(TD ~ Temp, data = shuttle_data, family = binomial)
summary(fit)
alpha <- coef(fit)["(Intercept)"]
beta  <- coef(fit)["Temp"]
p31 <- invlogit(alpha + beta * 31)   # predicted probability at 31 degrees F
p31

# 3. Kyphosis: linear versus quadratic term in age
kyphosis_data <- read.table("Kyphosis.dat", header = TRUE)
fit1 <- glm(y ~ x, data = kyphosis_data, family = binomial)
summary(fit1)
fit2 <- glm(y ~ x + I(x^2), data = kyphosis_data, family = binomial)
summary(fit2)

x_seq <- seq(min(kyphosis_data$x), max(kyphosis_data$x))
p_fit  <- predict(fit1, newdata = data.frame(x = x_seq), type = "response")
p_fit2 <- predict(fit2, newdata = data.frame(x = x_seq), type = "response")
plot(kyphosis_data$x, kyphosis_data$y)
lines(x_seq, p_fit,  col = "blue")
lines(x_seq, p_fit2, col = "red")

# 4. Horseshoe crabs: weight and satellite presence
crabs <- read.table("Crabs.dat", header = TRUE)
m_wt <- glm(y ~ weight, data = crabs, family = binomial)
summary(m_wt)

# Average marginal effect of a 0.10-kg increase in weight
bl <- coef(m_wt)["weight"]
p_hat_i <- fitted(m_wt)
ame_0p10 <- mean(p_hat_i * (1 - p_hat_i)) * bl * 0.10
ame_0p10

# Classification table with the sample proportion of y = 1 as the cutoff
y  <- crabs$y
wt <- crabs$weight
cutoff <- mean(y, na.rm = TRUE)
y_hat <- as.integer(fitted(m_wt) >= cutoff)
TP <- sum(y_hat == 1 & y == 1)
TN <- sum(y_hat == 0 & y == 0)
FP <- sum(y_hat == 1 & y == 0)
FN <- sum(y_hat == 0 & y == 1)
sensitivity <- TP / (TP + FN)
specificity <- TN / (TN + FP)
class_tbl <- matrix(c(TP, FP, FN, TN), nrow = 2, byrow = TRUE,
                    dimnames = list("Pred 1/0" = c("1", "0"),
                                    "True 1/0" = c("1", "0")))
class_tbl

# ROC curve and AUC
roc_wt <- roc(response = y, predictor = fitted(m_wt), quiet = TRUE)
auc_wt <- as.numeric(auc(roc_wt))
roc_wt
plot(roc_wt)
abline(a = 0, b = 1)

# Color as a factor versus a numeric score, and standardized coefficients
m_col_fac <- glm(y ~ factor(color), data = crabs, family = binomial)
summary(m_col_fac)
OR_4_vs_1 <- exp(coef(m_col_fac)["factor(color)4"])
OR_4_vs_1

crabs$color_num <- as.numeric(crabs$color)
m_col_num <- glm(y ~ color_num, data = crabs, family = binomial)
summary(m_col_num)

m_both <- glm(y ~ weight + color_num, data = crabs, family = binomial)
summary(m_both)
sd_w <- sd(crabs$weight, na.rm = TRUE)
sd_c <- sd(crabs$color_num, na.rm = TRUE)
beta_std_w <- coef(m_both)["weight"] * sd_w
beta_std_c <- coef(m_both)["color_num"] * sd_c

# 5. MBTI personality scales and drinking: grouped binomial data
MBTI <- read.table("MBTI.dat", header = TRUE)
MBTI$E <- ifelse(MBTI$EI == "e", 1, 0)
MBTI$S <- ifelse(MBTI$SN == "s", 1, 0)
MBTI$T <- ifelse(MBTI$TF == "t", 1, 0)
MBTI$J <- ifelse(MBTI$JP == "j", 1, 0)
fit_drink <- glm(cbind(drink, n - drink) ~ E + S + T + J,
                 data = MBTI, family = binomial)
summary(fit_drink)

# Classification table with the sample proportion as cutoff (grouped data)
MBTI$phat_drink <- fitted(fit_drink)
cutoff_drink <- 0.092
I1 <- which(MBTI$phat_drink >= cutoff_drink)
I0 <- which(MBTI$phat_drink <  cutoff_drink)
y <- MBTI$drink
n <- MBTI$n
TP <- sum(y[I1]);       FP <- sum((n - y)[I1])
FN <- sum(y[I0]);       TN <- sum((n - y)[I0])
matrix(c(TP, FP, FN, TN), nrow = 2, byrow = TRUE)
TP / (TP + FN)               # sensitivity
TN / (TN + FP)               # specificity
acc <- (TP + TN) / sum(n)    # overall accuracy
acc

# Smoking: ROC from grouped data expanded to individual rows
fit_smoke <- glm(cbind(smoke, n - smoke) ~ E + S + T + J,
                 data = MBTI, family = binomial)
MBTI$phat_smoke <- fitted(fit_smoke)
y_smoke <- unlist(mapply(function(s, n) c(rep(1, s), rep(0, n - s)),
                         MBTI$smoke, MBTI$n, SIMPLIFY = FALSE))
pred_rep <- rep(MBTI$phat_smoke, MBTI$n)
roc_smoke <- roc(response = y_smoke, predictor = pred_rep)
plot(roc_smoke); abline(a = 0, b = 1)
auc(roc_smoke)

# 6. Sore throat after surgery: interaction between duration (D) and device (T)
sore_data <- read.table("SoreThroat.dat", header = TRUE)
fit_inter <- glm(Y ~ D * T, data = sore_data, family = binomial)
summary(fit_inter)
fit_non <- glm(Y ~ D + T, data = sore_data, family = binomial)
summary(fit_non)

# Predictive power: correlation between observed and fitted values
R_inter <- cor(sore_data$Y, fitted(fit_inter))
R_non   <- cor(sore_data$Y, fitted(fit_non))
R_inter
R_non
