
*****************************************************************************
* Assignment: Group 2 Project Do-File
* Members: Anastasya Gunawan (#15686162), Bhavya Jain (#37208667), Isaac Cao (#64781298), Michael Le (#14133870), Victor Antunez (#19535000)
   
*****************************************************************************
  
* Initialize Code
clear all
set more off
   
* Set Working Directory and Import Excel File
cd \\apporto.com\dfs\UCI\Users\angunawa_uci\Desktop
import excel "Dataset Project.xls", firstrow clear
   
* Inspect Data and See Summary Statistics
describe
summarize
   
*****************************************************************************
* Verification of OLS Assumptions on basic regression
*****************************************************************************
   
* Generate log of selling price
gen ln_sellingprice = ln(sellingprice)

* Use per 1,000 feet units
gen sqft_house1000 = squarefootageofhouse/1000
gen sqft_lot1000 = squarefootagelot/1000
gen cbd_1000 = distancetoCBDfeet/1000
gen interstate_1000 = distancetointerstatefeet/1000
   
* Basic OLS regression
reg ln_sellingprice ageinyears cbd_1000 interstate_1000 rooms sqft_house1000 sqft_lot1000 bathrooms
   
* Identify Outliers
/* Interpretation: Studentized residuals were computed to identify outliers.
   Observations with |r| > 3 were considered outliers and removed from the
   dataset. Four observations exceeded this threshold, and one additional
   observation had a missing residual value, resulting in a total of five
   observations being dropped from the sample. */
predict r, rstudent
sort r
list neighborhood r in 1/10
list neighborhood r in-10/L
drop if abs(r) > 3
   
* Check the Normality of Residuals
/* Interpretation: The Shapiro-Wilk test suggests that residuals are normally
distributed. */
kdensity r, normal
pnorm r
qnorm r
swilk r
   
* Check for Homoskedasticity
/* Interpretation: The Breusch-Pagan test fails to reject homoskedasticity.
However, the residual-versus-fitted plot and White test both reject
heteroskedasticity, indicating that the variance of the error term is not
constant. Therefore, heteroskedasticity appears to be present in the model, and
robust standard errors are used for inference. */
rvfplot, yline(0)
estat hettest
estat imtest, white

   
* Check for Multicollinearity
/* Interpretation: All VIF values are well below 5, and the mean VIF is also
low. This indicates that multicollinearity is not a concern in this model. The
explanatory variables are not highly correlated with each other, which allows
for precise estimation of the coefficients. */
vif
   
* Check Linearity and Model Specification
/* Interpretation: The Ramsey RESET test rejects the null hypothesis of correct
model specification, suggesting that the model may suffer from omitted
variables. The added-variable plots indicate that house characteristics such as
square footage, number of rooms, and number of bathrooms are positively
associated with selling price, while age and distance to CBD have negative
relationships. Distance to interstate and square footage of house lot appear to
have weaker effects. Overall, the graphical analysis supports the expected
economic relationships between housing characteristics and selling price. */
avplots
estat ovtest
   
/* OLS Assumptions have been verified. Data has been cleaned of outliers.
Residuals are normally distributed. Tests indicate heteroskedasticity so robust
standard errors will be used for inference. There is no evidence of
multicollinearity, but the model may contain omitted variables.
   
Now, we can proceed with the fixed effects regression. */
   
*****************************************************************************
* Estimating the Fixed Effects Model
*****************************************************************************
 
reg ln_sellingprice ageinyears cbd_1000 interstate_1000 rooms sqft_house1000 sqft_lot1000 bathrooms i.neighborhood i.year, vce(robust)
  
*****************************************************************************
* Question 1 - Evaluating monthly rental rate for the next 4 years
*****************************************************************************

* Baseline assumptions
  
* Suppose that you own a 1,950 sqft house in your city's residential zone neighborhood #5. The house is 12 years old, has 2 bathrooms, 7 rooms and is built on a 5,200 square footage lot. It is also located 3,000 feet from the CBD and from the interstate.
  
* Property values historically increase 4% per year 
  
*Storing the house characteristics
scalar houseage = 12
scalar housesqft = 1.95 // 1950/1000 = 1.95 because of the regressor variables being divided by 1000
scalar neighborhoodzone5 = 1 // Because the neighborhoods are dummy variables in the regression we need to use 0 or 1 
scalar housebathrm = 2 
scalar houserm = 7 
scalar houselot = 5.2 // 5200/1000 = 5.2 
scalar houseCBDdist = 3 // same reasoning 
scalar houseintdist = 3 // same reasoning 
 
*Storing the regression coefficients
scalar b_houseage = _b[ageinyears]
scalar b_housesqft = _b[sqft_house1000]
scalar b_neighborhoodzone5 = _b[5.neighborhood]
scalar b_housebathrm = _b[bathrooms]
scalar b_houserm = _b[rooms]
scalar b_houselot = _b[sqft_lot1000]
scalar b_houseCBDdist = _b[cbd_1000]
scalar b_houseintdist = _b[interstate_1000]
scalar constant = _b[_cons]
  
*Estimating house value log form

scalar ln_predicted_house_price = constant ///
+ b_houseage * houseage ///
+ b_housesqft * housesqft /// 
+ b_neighborhoodzone5 * neighborhoodzone5 /// 
+ b_housebathrm * housebathrm /// 
+ b_houserm * houserm /// 
+ b_houselot * houselot /// 
+ b_houseCBDdist * houseCBDdist /// 
+ b_houseintdist * houseintdist 
  
display ln_predicted_house_price 
  
*Convert back to linear price for interpretaion 
scalar predicted_house_price = exp(ln_predicted_house_price)
  
display "$" predicted_house_price
   
* predicted price of $428668.87
  
* Expected growth of house value for 4 years at 4% annual growth 
  
scalar predicted_house_price_yr1 = predicted_house_price * 1.04 
display "$" predicted_house_price_yr1
  
scalar predicted_house_price_yr2 = predicted_house_price_yr1 * 1.04
display "$" predicted_house_price_yr2
  
scalar predicted_house_price_yr3 = predicted_house_price_yr2 * 1.04
display "$" predicted_house_price_yr3
  
scalar predicted_house_price_yr4 = predicted_house_price_yr3 *1.04
display "$" predicted_house_price_yr4
  
  
* According to OECD, the most recent national average price-to-rent ratio reported
* in the United States is 130

* Generate variable for price-to-rent ratio of 130
gen price_rent_ratio = 130

* Divide predicted house price by ratio to get monthly rent
* Note: House value increases by 4% each year, so each year, the monthly rent
* will increase

* Monthly rent for Year 0
scalar monthly_rent_base = (predicted_house_price / price_rent_ratio)
display "$" monthly_rent_base

* Monthly rent for Year 1
scalar monthly_rent_yr1 = (predicted_house_price_yr1 / price_rent_ratio) 
display "$" monthly_rent_yr1 
  
* Monthly rent for Year 2
scalar monthly_rent_yr2 = (predicted_house_price_yr2 / price_rent_ratio) 
display "$" monthly_rent_yr2 
  
* Monthly rent for Year 3
scalar monthly_rent_yr3 = (predicted_house_price_yr3 / price_rent_ratio) 
display "$" monthly_rent_yr3
  
* Monthly rent for Year 4
scalar monthly_rent_yr4 = (predicted_house_price_yr4 / price_rent_ratio) 
display "$" monthly_rent_yr4
  
  
*****************************************************************************
* Question 2 - Is converting one room into one bathroom economically justified?
*****************************************************************************

* To solve question 2 we will,
  
* Step 1 : Predict selling price for houses in the sample and find the average predicted price
predict ln_pricehat if e(sample)
gen pricehat = exp(ln_pricehat)
  
summarize pricehat
* Step 2 : Store the average predicted price
scalar avg_price = r(mean)
  
* Step 3 : Store bathroom coefficient from regression
scalar b_bath = _b[bathrooms]
  
* Step 4 : Converting log-point effect into percent effect
scalar pct_effect = exp(b_bath)- 1
  
* Step 5 : Now we will estimate dollar increase in house value from one extra bathroom
scalar value_increase = pct_effect * avg_price
  
* Step 6 : Calculating the cost of adding a 90 sqft bathroom
scalar low_cost = 90*200
scalar high_cost = 90*350
  
*Results
  
display "Average predicted house price = " avg_price
display "Bathroom coefficient = " b_bath
display "Percent effect of one extra bathroom = " pct_effect
display "Estimated increase in house value = " value_increase
display "Low renovation cost = " low_cost
display "High renovation cost = " high_cost
display "Net gain at low cost = " value_increase- low_cost
display "Net gain at high cost = " value_increase- high_cost 
  
*****************************************************************************
* Question 3 - Does effect of age on house value change with distance to CBD?
*****************************************************************************

* We want to know the interaction between Age and CBD distance 
* Use an interaction variable 
* Create the interaction variable 
gen interaction = (ageinyears * cbd_1000)

* Run the regression with the interaction variable and note the sign of the coefficient

reg ln_sellingprice ageinyears cbd_1000 interstate_1000 rooms sqft_house1000 sqft_lot1000 bathrooms interaction i.neighborhood i.year, vce(robust)

* Age does have a changing effect as distance to the CBD changes
* It has a coefficient of 0.000164 which means that a unit increase in age or in 1000 ft from the cbd will have an associated increase of house value by 0.0164% 
*Result is statistically significant with a p-value of 0.014 making it significant at the 5% level

*****************************************************************************
* Further Analysis
*****************************************************************************

* Ramsey RESET Test on our model after including the interaction variable
 estat ovtest 
 
/* Interpretiation: In our final model, including the interaction variable, 
The Ramsey RESET Test now fails to reject H0: Model has no omitted variables at the 1% level. This means that although the test still suggests omitted variable bias at a 5% level, the model is better specified than without the interaction variable.*/

*****************************************************************************

