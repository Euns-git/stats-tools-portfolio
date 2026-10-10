# 02_statistical_tests.R
# 일표본 · 대응표본 · 비모수 검정
# Data: hospital (wbc, Service), smoke (Age, Day_abs) -- textbook data, not included

# hospital <- read.csv("hospital.csv")
# smoke    <- read.csv("smoke.csv")

# ---- 1. Wilcoxon rank sum: 내과 vs 외과 WBC ----
medical  <- hospital$wbc[hospital$Service == 1]
surgical <- hospital$wbc[hospital$Service == 2]
wilcox.test(medical, surgical, alternative = "two.sided")

# ---- 2. 대응표본 차이 (diff) ----
diff <- c(2.34, 1.22, -0.27, 2.22, 0.55, 4.44, 2.56, 4.83, -3.55,
          7.05, 4.33, 8.89, 3.67, 4.78, -0.67, 7.77, 0.00)

# paired t-test
t.test(diff, mu = 0, alternative = "two.sided")

# Wilcoxon signed rank (동점/0 존재 -> 정확검정 불가, 정규근사)
wilcox.test(diff, mu = 0, alternative = "two.sided", exact = FALSE)

# ---- 3. Wilcoxon rank sum: 연령군(중앙값 기준)에 따른 금연 일수 ----
median(smoke$Age)   # 41
smoke$AgeGroup <- factor(ifelse(smoke$Age > median(smoke$Age), "Older", "Younger"))
wilcox.test(Day_abs ~ AgeGroup, data = smoke, alternative = "two.sided")
