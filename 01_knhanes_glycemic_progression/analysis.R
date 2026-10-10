# ============================================================
# 성인의 당뇨 진행 단계별 위험요인의 차별적 효과
# : 국민건강영양조사(2024) 기반 부분 비례오즈 모형(PPO) 적용
#
# 분석 집단: KNHANES 9기 3차년도(2024) 20-59세 성인
# Outcome: dm_status / 혈당상태 (Normal < Prediabetes < Diabetes, ordinal)
# Model: PO -> 비례오즈 가정 검토(Wald F검정) -> PPO
#        -> 결합 Wald 검정 + 5-fold 교차검증 기반 순열 중요도
#
# 주의: 원시자료(HN24_ALL.sav)는 재배포 불가.
#       질병관리청 국민건강영양조사(https://knhanes.kdca.go.kr)에서
#       직접 신청 후 다운로드해야 합니다.
# ============================================================

# ============================================================
# 0. 패키지
# ============================================================
library(dplyr)
library(haven)
library(tableone)
library(svyVGAM)   # svy_vglm() - 복합표본 ordinal/PPO
library(survey)    # svydesign(), svyglm()
library(VGAM)      # vglm(), lrtest()
library(aod)       # wald.test() - Joint Wald Test
library(openxlsx)  # 엑셀 저장
library(ggplot2)   # forest plot

# ============================================================
# 1. 데이터 로딩
# ============================================================
raw <- read_sav("HN24_ALL.sav")

# ============================================================
# 2. 전처리
# ============================================================
dat <- raw %>%
  select(ID, age, sex, HE_DM_HbA1c, LW_ms, HE_wc,
         HE_DMfh1:HE_DMfh3,
         BS1_1, BS3_1, BP1,
         BP16_11, BP16_12, BP16_13, BP16_14,
         BP16_21, BP16_22, BP16_23, BP16_24,
         BE3_31, DI1_dg, DI2_dg,
         wt_itvex, psu, kstrata) %>%
  mutate(across(-c(psu, kstrata), as.numeric)) %>%
  filter(
    age >= 20 & age <= 59,
    LW_ms != 3 | is.na(LW_ms),  # 임신 제외
    !is.na(HE_DM_HbA1c)
  ) %>%
  mutate(
    # ── Outcome: 혈당상태 ──────────────────────────────────
    # HE_DM_HbA1c: 1=정상, 2=전당뇨, 3=당뇨
    dm_status = factor(HE_DM_HbA1c, levels = 1:3,
                       labels = c("Normal", "Prediabetes", "Diabetes"),
                       ordered = TRUE),

    # ── 인구학적 및 신체계측 특성 ────────────────────────────
    sex_f = factor(sex, levels = c(1, 2), labels = c("Male", "Female")),
    wc    = na_if(HE_wc, 999),  # 999 -> NA

    # ── 당뇨 가족력 ──────────────────────────────────────────
    # HE_DMfh1~3: 1=예, 8·9=비해당·모름. 3개 중 하나라도 1이면 양성
    fam_dm = factor(
      if_else(rowSums(across(HE_DMfh1:HE_DMfh3) == 1, na.rm = TRUE) > 0, 1, 0),
      levels = c(0, 1), labels = c("No", "Yes")
    ),

    # ── 흡연상태 ─────────────────────────────────────────────
    # BS1_1: 평생 흡연 여부(3=비흡연), BS3_1: 현재 상태(1=매일,2=가끔,3=과거)
    smoke_f = factor(case_when(
      BS1_1 == 3         ~ "Never",
      BS3_1 %in% c(1, 2) ~ "Current",
      BS3_1 == 3         ~ "Former",
      TRUE               ~ NA_character_
    ), levels = c("Never", "Former", "Current")),

    # ── 스트레스 인지 정도 ───────────────────────────────────
    # BP1: 1=대단히많이~4=거의안느낌, 8·9->NA. 5-BP1: 높을수록 스트레스 많음
    stress_f = factor(
      if_else(BP1 %in% c(8, 9), NA_real_, as.numeric(5 - BP1)),
      levels = 1:4, labels = c("Low", "Mod-Low", "Mod-High", "High"),
      ordered = FALSE
    ),

    # ── 주중 수면시간 / 주중-주말 수면시간 차이 ─────────────
    BP16_11_c = na_if(BP16_11, 99), BP16_12_c = na_if(BP16_12, 99),
    BP16_13_c = na_if(BP16_13, 99), BP16_14_c = na_if(BP16_14, 99),
    BP16_21_c = na_if(BP16_21, 99), BP16_22_c = na_if(BP16_22, 99),
    BP16_23_c = na_if(BP16_23, 99), BP16_24_c = na_if(BP16_24, 99),
    sleep_start_wd = BP16_11_c * 60 + BP16_12_c,
    sleep_end_wd   = BP16_13_c * 60 + BP16_14_c,
    sleep_start_we = BP16_21_c * 60 + BP16_22_c,
    sleep_end_we   = BP16_23_c * 60 + BP16_24_c,
    sleep_wd = if_else(
      sleep_end_wd >= sleep_start_wd,
      (sleep_end_wd - sleep_start_wd) / 60,
      (sleep_end_wd - sleep_start_wd + 1440) / 60
    ),
    sleep_we = if_else(
      sleep_end_we >= sleep_start_we,
      (sleep_end_we - sleep_start_we) / 60,
      (sleep_end_we - sleep_start_we + 1440) / 60
    ),
    # 주중-주말 수면시간 차이(social jetlag): 절댓값
    social_jetlag = abs(sleep_we - sleep_wd),
    # 주중 수면시간 범주: Short(<6h) / Adequate(6-9h) / Long(>=9h)
    sleep_cat = cut(sleep_wd,
                    breaks = c(-Inf, 6, 9, Inf),
                    labels = c("Short", "Adequate", "Long"),
                    right = FALSE, ordered_result = FALSE),

    # ── 주간 걷기 빈도 ───────────────────────────────────────
    # BE3_31: 1=0일~8=7일, 9=모름->NA, 코드-1=실제 일수
    walk_days = if_else(BE3_31 == 9, NA_real_, as.numeric(BE3_31) - 1),
    walk_f    = cut(walk_days, breaks = c(-1, 0, 3, 7),
                    labels = c("Inactive", "Low", "Active"),
                    ordered_result = FALSE),

    # ── 대사성 동반질환 ──────────────────────────────────────
    # DI1_dg, DI2_dg: 0=아니오, 1=예, 8·9->NA
    htn = factor(case_when(
      DI1_dg == 1 ~ "Yes", DI1_dg == 0 ~ "No", TRUE ~ NA_character_
    ), levels = c("No", "Yes")),
    dyslip = factor(case_when(
      DI2_dg == 1 ~ "Yes", DI2_dg == 0 ~ "No", TRUE ~ NA_character_
    ), levels = c("No", "Yes")),

    # ── 비례오즈 가정 검토용 이분형 변수 ─────────────────────
    # 절단점1: 정상(0) vs 전당뇨+당뇨(1) / 절단점2: 정상+전당뇨(0) vs 당뇨(1)
    dm_bin1 = as.integer(HE_DM_HbA1c > 1),
    dm_bin2 = as.integer(HE_DM_HbA1c == 3)
  )

# ============================================================
# 3. Complete case
# ============================================================
dat_cc <- dat %>%
  filter(complete.cases(select(., dm_status, sex_f, wc, fam_dm,
                               smoke_f, stress_f, sleep_cat,
                               social_jetlag, walk_f, htn, dyslip,
                               wt_itvex, psu, kstrata)))
cat("최종 분석 대상자:", nrow(dat_cc), "\n")

# ============================================================
# 4. 복합표본 설계 선언
# ============================================================
svy_design <- svydesign(
  id = ~psu, strata = ~kstrata, weights = ~wt_itvex,
  data = dat_cc, nest = TRUE
)

# ============================================================
# 5. 대상자의 일반적 특성 (Table 2)
# ============================================================
vars     <- c("age", "sex_f", "wc", "fam_dm", "smoke_f", "stress_f",
              "sleep_cat", "social_jetlag", "walk_f", "htn", "dyslip")
cat_vars <- c("sex_f", "fam_dm", "smoke_f", "stress_f",
              "sleep_cat", "walk_f", "htn", "dyslip")
tab1 <- CreateTableOne(
  vars = vars, strata = "dm_status", data = dat_cc,
  factorVars = cat_vars, addOverall = TRUE
)
print(tab1, showAllLevels = TRUE, smd = FALSE, test = TRUE)

# ============================================================
# 6. 비례오즈 가정 검토 (복합표본 반영 Wald F검정) - Table 3
# 두 절단점에서 이분형 로지스틱 회귀 적합 후 절단점 간 계수 차이 검정
# ============================================================
formula_full <- ~ sex_f + age + wc + fam_dm + smoke_f +
  stress_f + walk_f + sleep_cat + social_jetlag + htn + dyslip

bin1 <- svyglm(update(formula_full, dm_bin1 ~ .),
               family = quasibinomial(), design = svy_design)
bin2 <- svyglm(update(formula_full, dm_bin2 ~ .),
               family = quasibinomial(), design = svy_design)

# 두 절단점 모형의 계수와 표준오차 추출 (Wald F검정에 필요)
coef1 <- coef(bin1); se1 <- sqrt(diag(vcov(bin1)))
coef2 <- coef(bin2); se2 <- sqrt(diag(vcov(bin2)))

# 변수별 계수 이름 정의 (각 변수를 동시에 검정)
vars_list <- list(
  sex_f         = "sex_fFemale",
  age           = "age",
  wc            = "wc",
  fam_dm        = "fam_dmYes",
  smoke_f       = c("smoke_fFormer", "smoke_fCurrent"),
  stress_f      = c("stress_fMod-Low", "stress_fMod-High", "stress_fHigh"),
  walk_f        = c("walk_fLow", "walk_fActive"),
  sleep_cat     = c("sleep_catAdequate", "sleep_catLong"),
  social_jetlag = "social_jetlag",
  htn           = "htnYes",
  dyslip        = "dyslipYes"
)

f_wald_results <- lapply(names(vars_list), function(v) {
  coefs  <- vars_list[[v]]
  n_coef <- length(coefs)

  diff_vec <- as.numeric((coef1 - coef2)[coefs])
  var_vec  <- as.numeric(se1[coefs]^2 + se2[coefs]^2)

  # n_coef=1이면 직접 계산, 아니면 행렬 역산
  if (n_coef == 1) {
    F_stat <- diff_vec^2 / var_vec
  } else {
    vcov_diff <- diag(var_vec)
    F_stat <- as.numeric(t(diff_vec) %*% solve(vcov_diff) %*% diff_vec) / n_coef
  }

  p_val <- pf(F_stat, df1 = n_coef, df2 = 128, lower.tail = FALSE)

  data.frame(
    Variable             = v,
    F_statistic          = round(F_stat, 3),
    df_numerator         = n_coef,
    df_denominator       = 128,
    p_value              = round(p_val, 4),
    Statistical_Decision = if_else(p_val < 0.05,
                                   "Reject PO (Use PPO)", "Keep PO")
  )
}) %>% do.call(rbind, .)

print("=== 비례오즈 가정 검토 결과 (Wald F검정) ===")
print(f_wald_results)

# ============================================================
# 7. 계층적 모형 비교 (AIC + BIC + LRT)
# 주의: vglm AIC/BIC/LRT는 표본확장가중치(weights)만 반영한
#       pseudo-likelihood 기반 지표로, 복합표본 설계(strata/psu)를
#       완전히 반영하지 않음. 절대값 해석이 아닌 '모형 간 상대적
#       비교'와 '방향성 확인'을 위한 보조 지표로만 사용.
#       -> 모형 채택의 실질적 근거는 6번의 design-based Wald F검정.
# ============================================================
m0_aic <- vglm(
  dm_status ~ sex_f + age + wc,
  family = cumulative(parallel = TRUE, reverse = TRUE),
  data = dat_cc, weights = wt_itvex
)
m1_aic <- vglm(
  dm_status ~ sex_f + age + wc +
    fam_dm + smoke_f + stress_f + walk_f + sleep_cat + social_jetlag,
  family = cumulative(parallel = TRUE, reverse = TRUE),
  data = dat_cc, weights = wt_itvex
)
m2_aic <- vglm(
  dm_status ~ sex_f + age + wc +
    fam_dm + smoke_f + stress_f + walk_f + sleep_cat + social_jetlag +
    htn + dyslip,
  family = cumulative(parallel = TRUE, reverse = TRUE),
  data = dat_cc, weights = wt_itvex
)
m2_ppo_vglm <- vglm(
  dm_status ~ sex_f + age + wc +
    fam_dm + smoke_f + stress_f + walk_f + sleep_cat + social_jetlag +
    htn + dyslip,
  family = cumulative(parallel = FALSE ~ fam_dm, reverse = TRUE),
  data = dat_cc, weights = wt_itvex
)

# ── LRT: M2_PO vs M2_PPO ─────────────────────────────────────
lrt_result <- lrtest(m2_aic, m2_ppo_vglm)
lrt_chi2 <- round(lrt_result@Body[2, "Chisq"], 3)
lrt_df   <- lrt_result@Body[2, "Df"]
lrt_p    <- lrt_result@Body[2, "Pr(>Chisq)"]

# ── AIC + BIC + LRT 통합 테이블 (표시는 소숫점 2자리로 고정) ──
fit_table <- data.frame(
  Model = c("M0_PO", "M1_PO", "M2_PO", "M2_PPO"),
  Variables = c(
    "인구학적 및 신체계측 특성",
    "M0 + 가족력 및 건강행태 특성",
    "M1 + 대사성 동반질환 (최종 PO)",
    "M2 + 당뇨 가족력 비비례 조건 (최종 PPO)"
  ),
  AIC = c(AIC(m0_aic), AIC(m1_aic), AIC(m2_aic), AIC(m2_ppo_vglm)),
  BIC = c(BIC(m0_aic), BIC(m1_aic), BIC(m2_aic), BIC(m2_ppo_vglm)),
  LRT_chi2 = c(NA, NA, NA, lrt_chi2),
  LRT_df   = c(NA, NA, NA, lrt_df),
  LRT_p    = c(NA, NA, NA,
               ifelse(lrt_p < 0.001, "<.001",
                      formatC(lrt_p, format = "f", digits = 3)))
) %>%
  mutate(
    delta_AIC = AIC - min(AIC),   # 원본값에서 계산 (반올림 전)
    delta_BIC = BIC - min(BIC)
  ) %>%
  mutate(
    # 표시는 항상 소숫점 2자리 문자열로 고정 (끝자리 0도 .00까지 출력)
    AIC       = formatC(AIC,       format = "f", digits = 2, big.mark = ","),
    BIC       = formatC(BIC,       format = "f", digits = 2, big.mark = ","),
    delta_AIC = formatC(delta_AIC, format = "f", digits = 2, big.mark = ","),
    delta_BIC = formatC(delta_BIC, format = "f", digits = 2, big.mark = ",")
  ) %>%
  select(Model, Variables, AIC, BIC,
         delta_AIC, delta_BIC, LRT_chi2, LRT_df, LRT_p)

print("=== AIC/BIC/LRT 비교 (모형 간 상대비교 및 방향성 확인용) ===")
print(fit_table, row.names = FALSE)

# ============================================================
# 8. PO 최종 모형 (복합표본 완전 반영)
# ============================================================
m0_po <- svy_vglm(dm_status ~ sex_f + age + wc,
                  design = svy_design, family = propodds())
m1_po <- svy_vglm(dm_status ~ sex_f + age + wc +
                    fam_dm + smoke_f + stress_f +
                    walk_f + sleep_cat + social_jetlag,
                  design = svy_design, family = propodds())
m2_po <- svy_vglm(dm_status ~ sex_f + age + wc +
                    fam_dm + smoke_f + stress_f +
                    walk_f + sleep_cat + social_jetlag +
                    htn + dyslip,
                  design = svy_design, family = propodds())

# ============================================================
# 9. PPO 최종 모형 (복합표본 완전 반영)
# Wald F검정 결과 fam_dm만 비례오즈 가정 위배 -> fam_dm만 parallel=FALSE
# ============================================================
m2_ppo <- svy_vglm(
  dm_status ~ sex_f + age + wc +
    fam_dm + smoke_f + stress_f +
    walk_f + sleep_cat + social_jetlag +
    htn + dyslip,
  design = svy_design,
  family = cumulative(parallel = FALSE ~ fam_dm, reverse = TRUE)
)

# ============================================================
# 10. 결합 Wald 검정 (Joint Wald Test, aod 패키지) - Table 6
# svy_vglm PPO 최종 모형에서 계수·분산공분산 행렬 추출 후
# 변수별 결합 검정("이 변수 전체가 혈당상태와 유의하게 연관되는가")
# 자유도가 다른 변수 간 통계량 크기 비교는 이론적 한계가 있어
# 아래 11번 순열 중요도로 상호 보완함.
# ============================================================
b <- coef(m2_ppo)
V <- vcov(m2_ppo)
coef_table <- summary(m2_ppo)$coeftable

vars_idx <- list(
  fam_dm        = grep("fam_dm",        rownames(coef_table)),
  dyslip        = grep("dyslip",        rownames(coef_table)),
  htn           = grep("htn",           rownames(coef_table)),
  smoke_f       = grep("smoke_f",       rownames(coef_table)),
  wc            = grep("^wc$",          rownames(coef_table)),
  age           = grep("^age$",         rownames(coef_table)),
  sex_f         = grep("sex_f",         rownames(coef_table)),
  stress_f      = grep("stress_f",      rownames(coef_table)),
  sleep_cat     = grep("sleep_cat",     rownames(coef_table)),
  social_jetlag = grep("social_jetlag", rownames(coef_table)),
  walk_f        = grep("walk_f",        rownames(coef_table))
)

joint_wald_results <- lapply(names(vars_idx), function(v) {
  idx <- vars_idx[[v]]
  if (length(idx) == 0) return(NULL)

  wt  <- aod::wald.test(Sigma = V, b = b, Terms = idx)
  res <- wt$result$chi2  # chi2, df, P

  data.frame(
    Variable  = v,
    Wald_chi2 = round(res[["chi2"]], 3),
    df        = as.integer(res[["df"]]),
    p_value   = as.character(
      ifelse(res[["P"]] < 0.001, "<.001", round(res[["P"]], 3))
    ),
    stringsAsFactors = FALSE
  )
}) %>%
  do.call(rbind, .) %>%
  arrange(desc(Wald_chi2)) %>%
  mutate(Rank = row_number())

print("=== 설명변수의 결합 Wald 검정 결과 ===")
print(joint_wald_results)

# ============================================================
# 11. 5-fold 교차검증 기반 순열 중요도 (Permutation Importance)
# - 결합 Wald 검정의 자유도 비교 한계를 보완하기 위한 방법
# - 매 fold마다 학습자료(train)로 모형을 재적합하고,
#   검증자료(test)에서 변수값을 무작위로 순열한 뒤
#   가중 로그손실(weighted log-loss) 증가량으로 중요도를 정의
# - 별도 패키지(DALEX, iml 등) 없이 직접 구현
#   (복합표본 가중치 + 순위형 다항 예측 구조를 기성 패키지가
#    그대로 지원하지 않아 수동 구현이 더 확실함)
# ============================================================
set.seed(2024)
k      <- 5
n_perm <- 100   # 시간이 오래 걸리면 30~50으로 낮춰서 먼저 테스트 가능

# ── Stratified fold 배정 (dm_status 비율 유지) ──────────────
dat_cc <- dat_cc %>% mutate(fold = NA_integer_)
for (lv in levels(dat_cc$dm_status)) {
  idx <- which(dat_cc$dm_status == lv)
  idx <- sample(idx)
  dat_cc$fold[idx] <- rep(1:k, length.out = length(idx))
}
print(table(dat_cc$fold, dat_cc$dm_status))  # fold별 비율 확인용

vars_perm <- c("sex_f", "age", "wc", "fam_dm", "smoke_f", "stress_f",
               "sleep_cat", "social_jetlag", "walk_f", "htn", "dyslip")

weighted_logloss <- function(pred_mat, obs_idx, w) {
  p_obs <- pred_mat[cbind(seq_along(obs_idx), obs_idx)]
  -sum(w * log(pmax(p_obs, 1e-10))) / sum(w)
}

cv_formula <- dm_status ~ sex_f + age + wc + fam_dm + smoke_f + stress_f +
  walk_f + sleep_cat + social_jetlag + htn + dyslip
cv_family  <- cumulative(parallel = FALSE ~ fam_dm, reverse = TRUE)

# ── Fold별 학습(4개) -> 검증(1개)에서 permutation ────────────
fold_results <- list()

for (fk in 1:k) {
  train_dat <- dat_cc %>% filter(fold != fk)
  test_dat  <- dat_cc %>% filter(fold == fk)

  # 해당 fold의 train 데이터로 모형 재적합 (weights만 반영, vglm)
  fit_fold <- vglm(cv_formula, family = cv_family,
                    data = train_dat, weights = wt_itvex)

  # baseline: test fold 원본 예측 (순열 전)
  pred_base <- predict(fit_fold, newdata = test_dat, type = "response")
  obs_idx   <- as.integer(test_dat$dm_status)
  loss_base <- weighted_logloss(pred_base, obs_idx, test_dat$wt_itvex)

  # 변수별 permutation은 test fold 안에서만 수행 (out-of-sample)
  perm_res <- lapply(vars_perm, function(v) {
    losses <- numeric(n_perm)
    for (i in seq_len(n_perm)) {
      test_perm <- test_dat
      test_perm[[v]] <- sample(test_perm[[v]])
      pred_perm  <- predict(fit_fold, newdata = test_perm, type = "response")
      losses[i]  <- weighted_logloss(pred_perm, obs_idx, test_perm$wt_itvex)
    }
    data.frame(Fold = fk, Variable = v,
               Loss_base = loss_base,
               Loss_permuted_mean = mean(losses),
               Importance = mean(losses) - loss_base)
  }) %>% do.call(rbind, .)

  fold_results[[fk]] <- perm_res
  cat("Fold", fk, "완료\n")
}

cv_perm_raw <- do.call(rbind, fold_results)

# ── Fold 평균으로 최종 CV 순열 중요도 산출 ───────────────────
var_label_map <- c(
  wc            = "Waist circumference",
  age           = "Age",
  fam_dm        = "Family history of diabetes",
  dyslip        = "Dyslipidemia",
  htn           = "Hypertension",
  smoke_f       = "Smoking status",
  sex_f         = "Sex",
  social_jetlag = "Weekday-weekend sleep difference",
  sleep_cat     = "Sleep duration",
  stress_f      = "Perceived stress",
  walk_f        = "Walking frequency"
)

cv_perm_importance <- cv_perm_raw %>%
  group_by(Variable) %>%
  summarise(
    Importance_mean = round(mean(Importance), 5),
    Importance_sd_across_folds = round(sd(Importance), 5),
    .groups = "drop"
  ) %>%
  arrange(desc(Importance_mean)) %>%
  mutate(Rank = row_number(),
         Variable_label = var_label_map[Variable]) %>%
  select(Rank, Variable, Variable_label, Importance_mean, Importance_sd_across_folds)

print("=== 5-fold 교차검증 기반 순열 중요도 (Permutation Importance) ===")
print(cv_perm_importance, n = Inf)

# ============================================================
# 12. 결과 추출 함수 (svy_vglm 최종 모형용) - Table 5
# ============================================================
extract_or_svy <- function(model) {
  s   <- summary(model)$coeftable
  idx <- !grepl("\\(Intercept\\)", rownames(s))
  data.frame(
    Variable = rownames(s)[idx],
    Beta     = round(s[idx, "Coef"], 3),
    OR       = round(exp(s[idx, "Coef"]), 3),
    CI_lower = round(exp(s[idx, "Coef"] - 1.96 * s[idx, "SE"]), 3),
    CI_upper = round(exp(s[idx, "Coef"] + 1.96 * s[idx, "SE"]), 3),
    p_value  = ifelse(s[idx, "p"] < 0.001, "<.001",
                      as.character(round(s[idx, "p"], 3)))
  ) %>% arrange(desc(abs(Beta)))
}

result_po  <- extract_or_svy(m2_po)
result_ppo <- extract_or_svy(m2_ppo)
print("=== PO 최종 모형 결과 ===");  print(result_po)
print("=== PPO 최종 모형 결과 ==="); print(result_ppo)

# ============================================================
# 13. 엑셀 저장
# ============================================================
wb <- createWorkbook()

# Table 2: 대상자의 일반적 특성
tab1_df <- print(tab1, showAllLevels = TRUE, printToggle = FALSE, test = TRUE)
addWorksheet(wb, "Table2_Characteristics")
writeData(wb, "Table2_Characteristics", as.data.frame(tab1_df), rowNames = TRUE)

# Table 3: 비례오즈 가정 Wald F검정
addWorksheet(wb, "Table3_ProportionalOddsTest")
writeData(wb, "Table3_ProportionalOddsTest", f_wald_results, rowNames = FALSE)

# 모형 비교 (AIC/BIC/LRT, 본문 서술용 - 논문 표에는 미포함)
addWorksheet(wb, "ModelComparison_AICBICLRT")
writeData(wb, "ModelComparison_AICBICLRT", fit_table, rowNames = FALSE)

# Table 5: PO / PPO 최종 모형 결과
addWorksheet(wb, "Table5_PO_Results")
writeData(wb, "Table5_PO_Results", result_po, rowNames = FALSE)
addWorksheet(wb, "Table5_PPO_Results")
writeData(wb, "Table5_PPO_Results", result_ppo, rowNames = FALSE)

# Table 6: 결합 Wald 검정 결과
addWorksheet(wb, "Table6_JointWaldTest")
writeData(wb, "Table6_JointWaldTest", joint_wald_results, rowNames = FALSE)

# 순열 중요도 (5-fold CV) - fold별 원자료 + 요약
addWorksheet(wb, "PermImportance_byFold")
writeData(wb, "PermImportance_byFold", cv_perm_raw, rowNames = FALSE)
addWorksheet(wb, "PermImportance_summary")
writeData(wb, "PermImportance_summary", cv_perm_importance, rowNames = FALSE)

saveWorkbook(wb, "tables_result.xlsx", overwrite = TRUE)
cat("저장 완료:", getwd(), "/tables_result.xlsx\n")

# ============================================================
# 14. Forest Plot
# Figure 2: PO vs PPO 계수 비교 (fam_dm 절단점별 차이 시각화)
# Figure 3: PPO 최종 결과 (유의한 변수만)
# ============================================================
label_map <- function(x) {
  case_when(
    x == "fam_dmYes:2"       ~ "Family history (+)\nCutpoint 2",
    x == "fam_dmYes:1"       ~ "Family history (+)\nCutpoint 1",
    x == "fam_dmYes"         ~ "Family history (+)",
    x == "dyslipYes"         ~ "Dyslipidemia",
    x == "htnYes"            ~ "Hypertension",
    x == "smoke_fCurrent"    ~ "Current smoker",
    x == "smoke_fFormer"     ~ "Former smoker",
    x == "wc"                ~ "Waist circumference",
    x == "age"               ~ "Age",
    x == "sex_fFemale"       ~ "Sex (Female)",
    x == "stress_fMod-Low"   ~ "Stress (Mod-Low)",
    x == "stress_fMod-High"  ~ "Stress (Mod-High)",
    x == "stress_fHigh"      ~ "Stress (High)",
    x == "sleep_catAdequate" ~ "Sleep (Adequate)",
    x == "sleep_catLong"     ~ "Sleep (Long)",
    x == "social_jetlag"     ~ "Weekday-weekend\nsleep difference",
    x == "walk_fLow"         ~ "Walking (Low)",
    x == "walk_fActive"      ~ "Walking (Active)"
  )
}

po_df  <- result_po  %>% mutate(Model = "PO")  %>% filter(!grepl("Intercept", Variable))
ppo_df <- result_ppo %>% mutate(Model = "PPO") %>% filter(!grepl("Intercept", Variable))

# ── Figure 2: PO vs PPO 계수 비교 ────────────────────────────
compare_df <- bind_rows(po_df, ppo_df) %>%
  mutate(
    Label = label_map(Variable),
    Significant = p_value == "<.001" | suppressWarnings(as.numeric(p_value)) < 0.05
  )

var_order <- ppo_df %>%
  arrange(desc(abs(Beta))) %>%
  mutate(Label = label_map(Variable)) %>%
  pull(Label)

compare_df$Label <- factor(compare_df$Label, levels = rev(var_order))

p1 <- ggplot(compare_df, aes(x = OR, y = Label, color = Model, shape = Model)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_errorbarh(aes(xmin = CI_lower, xmax = CI_upper),
                 height = 0.3, position = position_dodge(0.5), linewidth = 0.5) +
  geom_point(size = 3, position = position_dodge(0.5)) +
  scale_color_manual(values = c("PO" = "steelblue", "PPO" = "tomato")) +
  scale_shape_manual(values = c("PO" = 16, "PPO" = 17)) +
  labs(title = "Comparison of odds ratio estimates between the\nproportional odds (PO) and partial proportional odds (PPO) models",
       x = "Odds Ratio (95% Confidence Interval)", y = NULL,
       color = "Model", shape = "Model") +
  theme_bw() +
  theme(
    axis.text.y        = element_text(size = 10, color = "black"),
    axis.text.x        = element_text(size = 9),
    axis.title.x       = element_text(size = 10),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "bottom",
    plot.title         = element_text(size = 11, face = "bold", hjust = 0.5)
  )
print(p1)
ggsave("Figure2_PO_vs_PPO.png", p1, width = 8, height = 9, dpi = 300)

# ── Figure 3: PPO 최종 결과 (유의한 변수만) ──────────────────
ppo_sig_df <- result_ppo %>%
  filter(!grepl("Intercept", Variable)) %>%
  mutate(
    p_numeric   = suppressWarnings(as.numeric(p_value)),
    Significant = p_value == "<.001" | (!is.na(p_numeric) & p_numeric < 0.05)
  ) %>%
  filter(Significant) %>%
  mutate(Label = label_map(Variable)) %>%
  arrange(desc(OR)) %>%
  mutate(Label = factor(Label, levels = rev(Label)))

p2 <- ggplot(ppo_sig_df, aes(x = OR, y = Label)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_errorbarh(aes(xmin = CI_lower, xmax = CI_upper),
                 height = 0.3, color = "black", linewidth = 0.5) +
  geom_point(size = 3, color = "black", shape = 19) +
  scale_x_continuous(breaks = seq(0.5, 3.5, by = 0.5), limits = c(0.5, 3.8)) +
  labs(title = "Adjusted odds ratios of significant predictors\nfrom the final PPO model",
       x = "Odds Ratio (95% Confidence Interval)", y = NULL) +
  theme_bw() +
  theme(
    axis.text.y        = element_text(size = 10, color = "black"),
    axis.text.x        = element_text(size = 9),
    axis.title.x       = element_text(size = 10),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(size = 11, face = "bold", hjust = 0.5)
  )
print(p2)
ggsave("Figure3_PPO_significant.png", p2, width = 7, height = 5, dpi = 300)

cat("\n분석 완료. tables_result.xlsx, Figure2_PO_vs_PPO.png, Figure3_PPO_significant.png 생성됨.\n")
