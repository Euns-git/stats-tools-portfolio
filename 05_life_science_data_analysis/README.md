# Life Science Data Analysis

Coursework in R from an undergraduate life science data analysis course (Department of Statistics, Ewha Womans University), based on Rosner, *Fundamentals of Biostatistics*. Homework covers descriptive statistics, probability, one- and two-sample inference, nonparametric methods, and categorical data tests. Textbook data files are not included.

## Topics and Code

| Topic | Methods | Code |
|---|---|---|
| Exploratory analysis | Summary statistics, correlation, group means, boxplots/histograms, age-group profile plot, binomial convolution probability | `01_exploratory_analysis.R` |
| Inference and nonparametric tests | Paired t-test, Wilcoxon signed-rank, Wilcoxon rank-sum | `02_statistical_tests.R` |
| Categorical data tests | McNemar test, two-proportion test, chi-square test of independence and goodness of fit | `03_categorical_data_tests.R` |

## Example: Exploring lung function (FEV) in 654 children

**Problem.** Which characteristics are associated with FEV (forced expiratory volume) in a sample of children?

**Approach.** Summaries, correlations, and boxplots of `fev` by `Age`, `Hgt`, `Sex` and `Smoke`; mean FEV by age group (3-4, 5-9, 10-14, 15-19) and sex, shown as a profile plot.

**Result.** FEV was strongly correlated with height (r = 0.868) and age (r = 0.756). The sample contained 318 and 336 children in the two sex groups and 589 non-smokers versus 65 smokers.

## Reference

Rosner B. *Fundamentals of Biostatistics*. Cengage.
