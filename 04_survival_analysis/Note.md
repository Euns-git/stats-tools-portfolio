Notes: Survival Analysis

Short concept notes written while studying. Not results; see the scripts for what was run.

1. What "proportional hazards" means

The Cox model assumes h(t | x1) / h(t | x0) = exp(β) at every t. The hazard curves of two groups may rise and fall, but their ratio is constant. If the hazards cross, the ratio is above 1 early and below 1 later, so no single HR describes the groups and the Cox model is not appropriate as specified.

2. Checking PH
Log-log KM plot (fun = "cloglog"): under PH, log(-log S(t)) curves for groups are parallel (vertical shift = β). Graphical and subjective, especially with few events or a categorized continuous variable.
Observed vs expected: compare KM curves with Cox-model curves for the same covariate; large gaps suggest PH fails.
Schoenfeld residuals (cox.zph, ggcoxzph): test whether the scaled residuals trend with time; a significant trend suggests the effect changes over time. Gives a p-value per covariate and a global test.
The two approaches are complementary: log-log plots are visual and work for a categorical grouping; Schoenfeld tests handle continuous covariates and give a formal test.
3. If PH fails
Stratify on the offending variable (strata(x)): separate baseline hazards per stratum, common coefficients for the rest. No HR is estimated for the stratifying variable.
Add interaction (e.g., with time or with the covariate) when the effect itself differs.
Split follow-up or use time-dependent coefficients when the effect changes over time.
4. Stratified Cox: two versions
No-interaction: coefficients are the same across strata; only baselines differ.
Interaction: coefficients differ across strata (equivalent to fitting each stratum separately).
Compare with an LR test. The df equals the number of interaction terms added (e.g., rx:sex and logWBC:sex gives df = 2). Check the df against the number of terms rather than assuming 1.
5. Interaction vs stratification

An interaction term (rx * logWBC) asks whether the effect of one covariate depends on another, within one baseline hazard. Stratification allows the baseline hazard itself to differ and does not estimate the stratifying variable's effect. They answer different questions.

6. Ties

Breslow and Efron approximate the partial likelihood when events tie. Efron is generally closer to the exact likelihood when there are many ties; with few ties the two give nearly the same estimates.

7. Analogy used in my other work

The proportional hazards assumption in Cox regression parallels the proportional odds assumption in ordinal logistic regression: one common effect across all cut points (or all times). In the KNHANES analysis, the PO assumption was tested per variable and relaxed only for the variable that violated it (partial proportional odds); the same logic applies to relaxing PH for a single covariate by stratifying or interacting.

8. Caution on subgroup analyses

Fitting models separately by subgroup (e.g., by sex) reduces events per fit, so wide CIs and non-significant results may reflect low power rather than no difference. Use the interaction test to judge whether effects differ.