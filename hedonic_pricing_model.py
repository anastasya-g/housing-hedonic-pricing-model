"""
Hedonic Pricing Model for Residential Rent Estimation
=======================================================
Python recreation of a Stata-based econometric project (originally completed
for Econ 122B at UC Irvine, Group 2: Cao, Gunawan, Antunez, Le, Jain).

Goal: Estimate a fair monthly rent for a specific house using a log-linear
OLS hedonic pricing model with neighborhood/year fixed effects, run standard
regression diagnostics, evaluate a renovation's ROI, and test an interaction
between house age and distance to the CBD.
"""

import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.stats.diagnostic import het_white, linear_reset
from statsmodels.stats.outliers_influence import variance_inflation_factor
from scipy import stats

# -----------------------------------------------------------------
# 1. Load and prepare data
# -----------------------------------------------------------------
df = pd.read_excel('Dataset_Project.xls')
df.columns = ['year', 'age', 'neighborhood', 'dist_cbd', 'dist_interstate',
              'rooms', 'sqft_house', 'sqft_lot', 'bathrooms', 'sellingprice']
df = df.dropna()

# Rescale distances/areas per 1,000 units so coefficients are interpretable
df['cbd_1000'] = df['dist_cbd'] / 1000
df['interstate_1000'] = df['dist_interstate'] / 1000
df['sqft_house1000'] = df['sqft_house'] / 1000
df['sqft_lot1000'] = df['sqft_lot'] / 1000
df['ln_sellingprice'] = np.log(df['sellingprice'])

df['neighborhood'] = df['neighborhood'].astype('category')
df['year'] = df['year'].astype('category')

FORMULA = ('ln_sellingprice ~ age + cbd_1000 + interstate_1000 + rooms + '
           'sqft_house1000 + sqft_lot1000 + bathrooms + '
           'C(neighborhood) + C(year)')

# -----------------------------------------------------------------
# 2. Remove large outliers (|studentized residual| > 3)
# -----------------------------------------------------------------
prelim_model = smf.ols(FORMULA, data=df).fit()
student_resid = prelim_model.get_influence().resid_studentized_external
df_clean = df[np.abs(student_resid) <= 3].copy()
print(f"Removed {np.sum(np.abs(student_resid) > 3)} outlier(s). "
      f"Final n = {len(df_clean)}")

# -----------------------------------------------------------------
# 3. Fit final model (robust standard errors, given heteroskedasticity)
# -----------------------------------------------------------------
model = smf.ols(FORMULA, data=df_clean).fit()
robust_model = smf.ols(FORMULA, data=df_clean).fit(cov_type='HC1')
print(robust_model.summary())

# -----------------------------------------------------------------
# 4. OLS assumption checks
# -----------------------------------------------------------------
print("\n--- White test for heteroskedasticity ---")
lm, lm_p, f, f_p = het_white(model.resid, model.model.exog)
print(f"LM stat={lm:.2f}, p={lm_p:.4f}  ->  {'heteroskedastic' if lm_p < 0.05 else 'homoskedastic'}")

print("\n--- Shapiro-Wilk test for residual normality ---")
sw_stat, sw_p = stats.shapiro(model.resid)
print(f"W={sw_stat:.4f}, p={sw_p:.4f}")

print("\n--- Variance Inflation Factors (multicollinearity) ---")
X_vif = sm.add_constant(df_clean[['age', 'cbd_1000', 'interstate_1000',
                                   'rooms', 'sqft_house1000', 'sqft_lot1000',
                                   'bathrooms']])
vif = pd.DataFrame({
    'Variable': X_vif.columns,
    'VIF': [variance_inflation_factor(X_vif.values, i) for i in range(X_vif.shape[1])]
})
print(vif.to_string(index=False))

print("\n--- Ramsey RESET test (omitted variable bias) ---")
print(linear_reset(model, power=3, use_f=True))

# -----------------------------------------------------------------
# 5. Predict market value & monthly rent for the case-study house
#    (12yo, 1,950 sqft, 2 bath, 7 rooms, 5,200 sqft lot, 3,000 ft from
#    CBD and interstate, neighborhood #5)
# -----------------------------------------------------------------
new_house = pd.DataFrame({
    'age': [12], 'cbd_1000': [3], 'interstate_1000': [3], 'rooms': [7],
    'sqft_house1000': [1.95], 'sqft_lot1000': [5.2], 'bathrooms': [2],
    'neighborhood': pd.Categorical([5], categories=df_clean['neighborhood'].cat.categories),
    'year': pd.Categorical([df_clean['year'].cat.categories.max()],
                            categories=df_clean['year'].cat.categories)
})
price_pred = np.exp(model.predict(new_house)[0])
print(f"\nPredicted current market price: ${price_pred:,.2f}")

GROWTH_RATE = 0.04       # Zillow Research (2025) national avg. appreciation
PRICE_TO_RENT = 133.66   # OECD national average
print("\n--- 4-Year Rent Projection ---")
for yr in range(4):
    p = price_pred * (1 + GROWTH_RATE) ** yr
    rent = p / PRICE_TO_RENT
    print(f"{'Base' if yr == 0 else f'Year {yr}'}: "
          f"Price=${p:,.2f}   Rent/mo=${rent:,.2f}")

# -----------------------------------------------------------------
# 6. Renovation ROI: convert a 90 sqft room into a bathroom
# -----------------------------------------------------------------
delta_ln = model.params['bathrooms'] - model.params['rooms']
pct_change = np.exp(delta_ln) - 1
value_increase = pct_change * price_pred
cost_low, cost_high = 90 * 200, 90 * 350
print(f"\n--- Renovation ROI ---")
print(f"Estimated value increase: ${value_increase:,.2f} "
      f"({pct_change*100:.1f}%)")
print(f"Estimated renovation cost: ${cost_low:,} - ${cost_high:,}")
print("Verdict:", "Worthwhile" if value_increase > cost_high else "Marginal")

# -----------------------------------------------------------------
# 7. Does the effect of age vary with distance to the CBD?
# -----------------------------------------------------------------
model_interaction = smf.ols(FORMULA + ' + age:cbd_1000', data=df_clean).fit()
beta_int = model_interaction.params['age:cbd_1000']
p_int = model_interaction.pvalues['age:cbd_1000']
print(f"\n--- Age x Distance-to-CBD Interaction ---")
print(f"Beta = {beta_int:.6f}, p = {p_int:.4f}")
print("Interpretation: the negative effect of age on price weakens as "
      "distance from the CBD increases." if p_int < 0.05 else
      "No significant interaction detected.")
