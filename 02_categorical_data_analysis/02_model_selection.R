# Model selection and separation in logistic regression
# Data: Agresti, Introduction to Categorical Data Analysis (textbook data files, not included)
# Packages: MASS, bestglm

library(MASS)
library(bestglm)

# 1. Horseshoe crabs: likelihood-ratio tests for weight and width
crabs <- read.table("Crabs.dat", header = TRUE)
names(crabs)

m_full <- glm(y ~ weight + width, data = crabs, family = binomial)
m_null <- glm(y ~ 1,              data = crabs, family = binomial)
anova(m_null, m_full, test = "LRT")      # overall test

m_wt <- glm(y ~ weight, data = crabs, family = binomial)
anova(m_wt, m_full, test = "LRT")        # partial effect of width

m_wd <- glm(y ~ width, data = crabs, family = binomial)
anova(m_wd, m_full, test = "LRT")        # partial effect of weight

# Backward elimination with AIC: weight, width, spine, color
m_all <- glm(y ~ weight + width + spine + color, data = crabs, family = binomial)
m_backward <- step(m_all, direction = "backward", trace = TRUE)
summary(m_backward)

# 2. Student survey: building a model for opinion on abortion
students <- read.table("Students.dat", header = TRUE)

# (a) Backward elimination by AIC from four candidate predictors
initial_vars <- c("ideol", "relig", "hsgpa", "gender")
students_a <- students[, c(initial_vars, "abor")]
students_a$abor   <- factor(students_a$abor,   levels = c(0, 1))
students_a$gender <- factor(students_a$gender, levels = c(0, 1))
full_model <- glm(abor ~ ideol + relig + hsgpa + gender,
                  data = students_a, family = binomial)
step_model <- stepAIC(full_model, direction = "backward", trace = TRUE)

# (b) Exhaustive search by BIC over all candidate predictors
X_vars_b <- c("gender", "age", "hsgpa", "cogpa", "dhome", "dres", "tv",
              "sport", "news", "aids", "veg", "affil", "ideol", "relig")
students_b <- students[, c(X_vars_b, "abor")]
students_b$abor <- factor(students_b$abor, levels = c(0, 1))
best_model_b <- bestglm(Xy = students_b, family = binomial,
                        IC = "BIC", method = "exhaustive")
print(best_model_b$BestModels)

# (c) Likelihood-ratio test of all predictors for vegetarianism
X_vars_c <- c("gender", "age", "hsgpa", "cogpa", "dhome", "dres", "tv",
              "sport", "news", "aids", "affil", "ideol", "relig", "abor")
students_c <- students[, c(X_vars_c, "veg")]
students_c$veg <- factor(students_c$veg, levels = c(0, 1))
full_model_c <- glm(veg ~ ., data = students_c, family = binomial)
null_model   <- glm(veg ~ 1, data = students_c, family = binomial)
lr_test <- anova(null_model, full_model_c, test = "LRT")
print(lr_test)

# 3. Complete separation: ML estimates that do not exist
x <- c(0, 10, 20, 30, 70, 80, 90, 100)
y <- c(0, 0, 0, 0, 1, 1, 1, 1)
fit_a <- glm(y ~ x, family = binomial)   # warning: fitted probabilities 0 or 1
summary(fit_a)

# Adding two overlapping observations at x = 50
x_b <- c(0, 10, 20, 30, 70, 80, 90, 100, 50, 50)
y_b <- c(0, 0, 0, 0, 1, 1, 1, 1, 1, 0)
fit_b <- glm(y_b ~ x_b, family = binomial)
summary(fit_b)

# Observations at 49.9 and 50.1 instead
x_c <- c(0, 10, 20, 30, 70, 80, 90, 100, 49.9, 50.1)
y_c <- c(0, 0, 0, 0, 1, 1, 1, 1, 1, 0)
fit_c <- glm(y_c ~ x_c, family = binomial)
summary(fit_c)

# 4. Multicenter clinical trial: quasi-complete separation by center
dat <- data.frame(
  center  = factor(rep(1:5, each = 2)),
  treat   = factor(rep(c("active", "placebo"), times = 5)),
  success = c(0, 0, 1, 0, 0, 0, 6, 2, 5, 2),
  failure = c(5, 9, 12, 10, 7, 5, 3, 6, 9, 12)
)
fit1 <- glm(cbind(success, failure) ~ treat + center,
            family = binomial, data = dat)
summary(fit1)

# No-intercept parameterization: one coefficient per center
fit2 <- glm(cbind(success, failure) ~ treat + center - 1,
            family = binomial, data = dat)
summary(fit2)

# Treatment log odds ratio is unchanged after dropping centers 1 and 3
tab_all <- with(dat, aggregate(cbind(success, failure), by = list(treat = treat), sum))
dat_245 <- subset(dat, !center %in% c(1, 3))
tab_245 <- with(dat_245, aggregate(cbind(success, failure), by = list(treat = treat), sum))
print(tab_all)
print(tab_245)
