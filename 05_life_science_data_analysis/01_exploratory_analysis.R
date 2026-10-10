# 01_exploratory_analysis.R
# 기술통계 · 탐색적 자료분석 (FEV 데이터), 확률 계산
# Data: fev (columns: fev, Age, Hgt, Sex, Smoke) -- textbook data, not included

library(ggplot2)

# fev <- read.csv("fev.csv")   # 파일명은 본인 환경에 맞게 수정

# ---- 1. 변수 간 상관 ----
cor(fev$fev, fev$Age)   # 0.756
cor(fev$fev, fev$Hgt)   # 0.868

# ---- 2. 집단별 평균 ----
tapply(fev$fev, fev$Sex,   mean)
tapply(fev$fev, fev$Smoke, mean)

# ---- 3. 요약통계 ----
summary(fev$Age);  sd(fev$Age)
summary(fev$fev);  sd(fev$fev)
summary(fev$Hgt);  sd(fev$Hgt)

table(fev$Sex)     # 318 / 336
table(fev$Smoke)   # 589 / 65

# ---- 4. 그래프 ----
plot(fev$Age, fev$fev)
plot(fev$Hgt, fev$fev)
boxplot(fev$fev ~ fev$Sex)
boxplot(fev$fev ~ fev$Smoke)
hist(fev$fev)

# ---- 5. 연령군 x 성별 평균 FEV ----
fev$AgeGroup <- cut(fev$Age,
                    breaks = c(3, 5, 10, 15, 20),
                    labels = c("3-4", "5-9", "10-14", "15-19"),
                    right  = FALSE)

aggregate(fev ~ AgeGroup + Sex, data = fev, FUN = mean)

ggplot(fev, aes(x = AgeGroup, y = fev, group = Sex, color = factor(Sex))) +
  stat_summary(fun = mean, geom = "line") +
  stat_summary(fun = mean, geom = "point")

# ---- 6. 이항분포 합의 확률 (convolution) ----
# X ~ Bin(10, 0.4), Y ~ Bin(10, 0.55) 독립일 때 P(X + Y = k), k = 0..3
pmf0to3 <- sapply(0:3, function(k) sum(dbinom(0:k, 10, 0.4) * dbinom(k:0, 10, 0.55)))
1 - sum(pmf0to3)   # P(X + Y >= 4)
