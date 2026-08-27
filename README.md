# Housing Hedonic Pricing Model

A hedonic pricing model that estimates how physical and locational house characteristics (age, size, location, number of rooms, and bathrooms) influence residential selling prices and rental value. The model uses a log-linear OLS regression with neighborhood and year fixed effects, and includes standard diagnostic testing of OLS assumptions.

## Background

This project began as an assignment for **Econ 122B (Applied Econometrics II)** at UC Irvine, where I built the original model in **STATA** to help a hypothetical homeowner determine a fair monthly rent and evaluate the ROI of a renovation project.

This repository contains my **rebuild of that analysis in Python**, using `pandas` and `statsmodels`, completed as a self-directed project to deepen my Python and applied statistics skills.

## What the Model Does

1. **Estimates a log-linear hedonic pricing model:**
