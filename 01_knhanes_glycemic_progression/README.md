# KNHANES 2024: Risk Factors Across Stages of Diabetes Progression

R code for a first-author manuscript (under review) analyzing how risk factors differ across stages of glycemic progression (normal → prediabetes → diabetes) among Korean adults, using the 2024 Korea National Health and Nutrition Examination Survey (KNHANES) and a partial proportional odds (PPO) model that accounts for the complex survey design.

**Manuscript.** 성인의 당뇨 진행 단계별 위험요인의 차별적 효과: 국민건강영양조사(2024) 기반 부분 비례오즈 모형(Partial Proportional Odds Model) 적용

## Data

Raw KNHANES data are not included. They are available from the Korea Disease Control and Prevention Agency ([knhanes.kdca.go.kr](https://knhanes.kdca.go.kr)) after a data-use application. To run the code, save the file as `HN24_ALL.sav` (or edit the path in `analysis.R`).
Raw data files (`*.sav`) are excluded from the repository via `.gitignore`.

## Contents

| File | Description |
|---|---|
| `analysis.R` | Full analysis: preprocessing, survey design, tests, model fitting, variable importance, figures |
| `figures/` | Forest plots (Figures 2 and 3) not included in the manuscript because of space limits |

## Analysis Pipeline (`analysis.R`)

1. **Preprocessing.** Load the data; derive the diabetes progression stage (`dm_status`) and predictors (waist circumference, family history of diabetes, smoking status, stress, weekday-weekend sleep difference, walking practice, hypertension, dyslipidemia, etc.); keep complete cases.
2. **Survey design.** Declare the design with `svydesign()` (strata, clusters, weights).
3. **Descriptive statistics.** Table 2 with `tableone`.
4. **Proportional odds assumption.** Compare coefficients across cut-point-specific binary logistic models and test them with a design-based Wald F-test (Table 3).
5. **Model comparison.** AIC, BIC and LRT for stepwise models M0, M1 and M2 (Table 4), reported as reference only because `vglm` uses a pseudo-likelihood; the model choice rests on the design-based Wald F-test in step 4.
6. **Final models.** Proportional odds (PO) and PPO models fitted with `svy_vglm` (`svyVGAM`).
7. **Joint Wald tests.** Joint significance of each variable (group) within the fitted model (Table 6).
8. **Permutation importance.** Stratified 5-fold cross-validation: the model is refit on four folds, and variables are permuted only in the held-out fold; importance is the increase in weighted log-loss.
9. **Export.** Tables 2-6 and importance results to `tables_result.xlsx`.
10. **Forest plots.** PO vs PPO odds ratios (Figure 2) and PPO significant variables only (Figure 3).

## Packages

`haven`, `dplyr`, `tableone`, `survey`, `svyVGAM`, `VGAM`, `aod`, `openxlsx`, `ggplot2`

```r
install.packages(c("haven", "dplyr", "tableone", "survey", "svyVGAM",
                   "VGAM", "aod", "openxlsx", "ggplot2"))
```

Numerical results are produced by running the code on the approved KNHANES data.
