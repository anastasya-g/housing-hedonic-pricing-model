# Housing Hedonic Pricing Model

A hedonic pricing model that estimates how physical and locational house characteristics (age, size, location, number of rooms, and bathrooms) influence residential selling prices and rental value. The model uses a log-linear OLS regression with neighborhood and year fixed effects, and includes standard diagnostic testing of OLS assumptions.

## Background

This project began as an assignment for **Econ 122B (Applied Econometrics II)** at UC Irvine, where I built the original model in **STATA** to help a hypothetical homeowner determine a fair monthly rent and evaluate the ROI of a renovation project.

This repository contains my **rebuild of that analysis in Python**, using `pandas` and `statsmodels`, completed as a self-directed project to deepen my Python and applied statistics skills.

## What the Model Does

**1. Estimates a log-linear hedonic pricing model**

The regression predicts the natural log of selling price using house age, distance to the CBD, distance to the interstate, number of rooms, house square footage, lot square footage, and number of bathrooms, with neighborhood and year fixed effects included as controls.

**2. Runs standard OLS diagnostic checks**
- Outlier removal via studentized residuals
- White test for heteroskedasticity (with robust standard errors where needed)
- Shapiro-Wilk test for residual normality
- Variance Inflation Factors (VIFs) for multicollinearity
- Ramsey RESET test for omitted variable bias / model specification

**3. Applies the model to a case-study house** (12 years old, 1,950 sqft, 2 bathrooms, 7 rooms, 5,200 sqft lot, 3,000 ft from the CBD and interstate) to:
- Predict current market value
- Project monthly rent over a 4-year horizon, using a national home price appreciation rate and price-to-rent ratio
- Evaluate whether converting a 90 sqft room into a bathroom is a financially sound renovation
- Test whether the effect of house age on price varies with distance to the CBD (via an interaction term)
