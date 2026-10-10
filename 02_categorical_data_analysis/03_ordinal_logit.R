# Cumulative logit (proportional odds) model with treatment-by-gender interaction
# Data: Agresti, Introduction to Categorical Data Analysis, small-cell lung cancer trial
# Packages: VGAM

library(VGAM)

lung <- data.frame(
  treat  = factor(c("Sequential", "Sequential", "Alternating", "Alternating")),
  gender = factor(c("Male", "Female", "Male", "Female")),
  prog   = c(28,  4, 41, 12),   # progressive disease
  nochg  = c(45, 12, 44,  7),   # no change
  part   = c(29,  5, 20,  3),   # partial remission
  comp   = c(26,  2, 20,  1)    # complete remission
)
lung

# Proportional odds model
fit_po <- vglm(cbind(prog, nochg, part, comp) ~ treat + gender,
               family = cumulative(parallel = TRUE), data = lung)
summary(fit_po)
exp(coef(fit_po))

# Does allowing a treatment-by-gender interaction improve fit?
fit_int <- vglm(cbind(prog, nochg, part, comp) ~ treat * gender,
                family = cumulative(parallel = TRUE), data = lung)
summary(fit_int)

G2   <- deviance(fit_po) - deviance(fit_int)
df   <- df.residual(fit_po) - df.residual(fit_int)
pval <- pchisq(G2, df = df, lower.tail = FALSE)
G2; df; pval
