# Survival Analysis (Self-study)

Self-study of survival analysis in R, following Kleinbaum & Klein, *Survival Analysis: A Self-Learning Text*. Scripts reproduce the textbook workflow on public datasets (`MASS::gehan`, `autoReg::anderson`); no course data are included.

## Topics and Code

| Topic | Methods | Code |
|---|---|---|
| Kaplan-Meier and group comparison | KM estimate, cumulative hazard (-log KM vs Nelson-Aalen), log-rank test | `01_kaplan_meier.R` |
| Cox regression | Cox PH with Breslow ties, interaction LR test, Breslow vs Efron, hazard ratios with CI, adjusted survival curves | `02_cox_regression.R` |
| PH assumption and stratified Cox | log-log KM plots, observed vs expected curves, `cox.zph` / Schoenfeld residuals, stratified Cox, LR tests for stratified models, sex-specific fits | `03_ph_assumption_stratified_cox.R` |

Concept notes (PO vs PH, checking assumptions, interaction vs stratification) are in [`docs/notes.md`](docs/notes.md).

## Example: Checking and handling the PH assumption

**Problem.** The Cox model assumes the hazard ratio between groups is constant over time. If it is not, a single hazard ratio is misleading.

**Approach.** Parallel log-log KM curves for `rx`, `logWBC` (categorized) and `sex`; a Schoenfeld residual test (`cox.zph`) on the model with `logWBC + rx + sex`; where a variable is not suitable as a covariate, stratified Cox (`strata(sex)`) with an LR test of the remaining terms.

**Result.** In the model with `logWBC`, `rx` and `sex`, the Schoenfeld test flagged `sex` (p = 0.026), while `logWBC` (p = 0.698) and `rx` (p = 0.929) showed no evidence of non-proportionality; the global test was not significant (p = 0.140). The log-log KM curves for `sex` cross. Stratifying on `sex` gave an HR for `rx` of 2.54 (95% CI 1.01-6.40; LR test chi-square = 4.18, df = 1, p = 0.041) and for `logWBC` of 4.02 (95% CI 2.07-7.78). Comparing the no-interaction and interaction stratified models (`rx:sex`, `logWBC:sex`) gave chi-square = 3.45, df = 2, p = 0.178, so there was no evidence that the effects of `rx` and `logWBC` differ by sex and the no-interaction stratified model was retained.

## Next

Competing risks and multi-state models, which connect to my ongoing research on transitions between disease states.

## Reference

Kleinbaum DG, Klein M. *Survival Analysis: A Self-Learning Text*. Springer.
