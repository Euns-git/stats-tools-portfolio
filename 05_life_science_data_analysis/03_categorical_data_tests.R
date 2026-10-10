# 03_categorical_data_tests.R
# 범주형 자료 검정: McNemar, 비율 비교, 카이제곱 독립성/적합도
# Data: estradl (bmi, Ethnic) -- textbook data, not included

# estradl <- read.csv("estradl.csv")

# ---- 1. McNemar test (통계량 직접 계산) ----
# 통계량 = (b - c)^2 / (b + c) = 121/12
pval <- 1 - pchisq(121 / 12, df = 1)
pval   # 0.0015

# ---- 2. 두 비율 비교 ----
n_obs <- 75; x_obs <- 41
n_ear <- 76; x_ear <- 4
prop.test(x = c(x_ear, x_obs), n = c(n_ear, n_obs),
          alternative = "two.sided", correct = FALSE)

# ---- 3. 카이제곱 독립성 검정 (성별 x 체중 상태) ----
tab <- matrix(c(17, 113, 13,
                 7, 115, 21), nrow = 2, byrow = TRUE,
              dimnames = list(Sex    = c("Girls", "Boys"),
                              Status = c("Under", "Normal", "Over")))
chisq.test(tab, correct = FALSE)

# ---- 4. 카이제곱 적합도 검정 (N(21.8, 3.4^2)) ----
obs   <- c(41, 65, 20, 17)
cuts  <- c(-Inf, 20, 23, 26, 29, Inf)
probs <- diff(pnorm(cuts, mean = 21.8, sd = 3.4))
probs4 <- c(probs[1], probs[2], probs[3], probs[4] + probs[5])  # 기대도수 확보를 위해 마지막 두 구간 병합
chisq.test(x = obs, p = probs4, rescale.p = TRUE)

# ---- 5. Estradiol 자료: 인종별 과체중 비율 ----
estradl$over25 <- factor(ifelse(estradl$bmi > 25, 1, 0),
                         levels = c(0, 1), labels = c("NotOver", "Over"))
estradl$Race   <- factor(estradl$Ethnic, levels = c(0, 1),
                         labels = c("Caucasian", "AfricanAmerican"))

tab_over <- table(estradl$Race, estradl$over25)
prop.test(tab_over, alternative = "two.sided", correct = FALSE)

# ---- 6. 인종 x BMI 범주 ----
estradl$BMIcat <- cut(estradl$bmi, breaks = c(-Inf, 25, 30, Inf),
                      labels = c("Normal", "Overweight", "Obese"), right = FALSE)
tab_bmi <- table(estradl$Race, estradl$BMIcat)
chisq.test(tab_bmi, correct = FALSE)
