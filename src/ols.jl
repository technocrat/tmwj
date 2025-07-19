using CairoMakie
using CSV
using DataFrames
using GLM
using OLSPlots
using RobustModels
using Statistics
using MLJ, MLJLinearModels
using GLMNet
using RegressionTables

df = CSV.read("data/educ_votes.csv", DataFrame)
df = subset(df, :state => ByRow(x -> x == "Ohio"))
df.geoid = string.(df.geoid)

tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)
geo = subset(full_geo, :STUSPS => ByRow(x -> x == "OH"))
geo = select(geo, :geometry, :GEOID)
rename!(geo, :GEOID => :geoid)
df = innerjoin(df, geo, on=:geoid)
select!(df, Not(:state))
df.higher_ed = df.college_pct + df.grad_pct

full_model = @formula(margin_pct ~ nocollege_pct + college_pct + grad_pct)
model = lm(full_model, df)
vif(model)
adjr2(model)
diagnostic_plots(model)

model = rlm(full_model, df, MEstimator{TukeyLoss}())

# Or using Huber M-estimator
model = rlm(full_model, df, MEstimator{HuberLoss}())

"""
These diagnostic plots reveal several important issues with your GLM model:

**Residuals vs Fitted (top-left):**
The red smoothing line shows a clear non-linear pattern, curving downward then upward. This indicates model misspecification - the linear relationship assumption is violated. The residuals should be randomly scattered around zero with no discernible pattern.

**Normal Q-Q Plot (top-right):**
The residuals follow the theoretical quantiles reasonably well in the center but deviate substantially in both tails, particularly the upper tail. This suggests the residuals are not normally distributed, with heavier tails than expected under normality.

**Scale-Location Plot (bottom-left):**
This plot shows heteroscedasticity - the variance of residuals is not constant across fitted values. The red line slopes upward and shows curvature, indicating that residual variance increases with fitted values. The √|standardized residuals| should be roughly constant.

**Residuals vs Leverage (bottom-right):**
Several high-leverage points are visible (notably points 287, 1765, 2600). The Cook's distance contours (dashed red lines at 0.5) help identify influential observations. While most points fall within acceptable Cook's distance, the high-leverage points warrant investigation as they may be driving the model fit.

**Recommendations for your Julia model:**

1. **Transform variables:** Consider log transformations or polynomial terms for your predictors
2. **Add interaction terms:** The education percentages might interact in meaningful ways
3. **Investigate outliers:** Examine the high-leverage observations (rows 287, 1765, 2600) in your dataset
4. **Consider robust regression:** Use packages like `GLM.jl` with robust standard errors or `RobustModels.jl`
5. **Check for missing predictors:** The non-linear pattern suggests important variables may be omitted

The current model likely produces biased coefficient estimates and unreliable confidence intervals due to these violations.
"""

function vif(df, predictors)
    vifs = Float64[]
    for pred in predictors
        # Regress each predictor on all others
        other_preds = filter(x -> x != pred, predictors)
        formula_str = string(pred, " ~ ", join(other_preds, " + "))
        formula = eval(Meta.parse("@formula($formula_str)"))
        
        model = lm(formula, df)
        r_squared = r2(model)
        
        # VIF = 1/(1 - R²)
        vif_val = 1 / (1 - r_squared)
        push!(vifs, vif_val)
    end
    
    return DataFrame(Variable = predictors, VIF = vifs)
end

predictors = [:nocollege_pct, :college_pct, :grad_pct]
vif_results = vif(df, predictors)

# Try model with just HS_pct and BA_pct
model1 = lm(@formula(margin_pct ~ nocollege_pct + college_pct), df)
diagnostic_plots(model1)

# Or HS_pct and GRAD_pct  
model2 = lm(@formula(margin_pct ~ nocollege_pct + grad_pct), df)
diagnostic_plots(model2)

# Create total higher education variable
df.higher_ed = df.college_pct + df.grad_pct
model3 = lm(@formula(margin_pct ~ nocollege_pct + higher_ed), df)
diagnostic_plots(model3)

# Try model with just GRAD_pct
model4 = lm(@formula(margin_pct ~ grad_pct), df)
diagnostic_plots(model4)

# Try model with just BA_pct
model5 = lm(@formula(margin_pct ~ college_pct), df)
diagnostic_plots(model5)

# Try model with just HS_pct
model6 = lm(@formula(margin_pct ~ nocollege_pct), df)
diagnostic_plots(model6)

# Try model with just HS_pct
model7 = lm(@formula(margin_pct ~ nocollege_pct + college_pct), df)
diagnostic_plots(model7)

# Fit with cross-validation to find optimal regularization
X = Matrix(select(df, [:nocollege_pct, :college_pct, :grad_pct]))
y = df.margin_pct

cv_result = glmnetcv(X, y, alpha=0)
best_lambda = cv_result.lambda[argmin(cv_result.meanloss)]

# Fit final model
ridge_final = glmnet(X, y, alpha=0, lambda=[best_lambda])

# Get predictions for diagnostic plots
y_pred = GLMNet.predict(ridge_final, X)[:]

# Create residual plots
residuals = y - y_pred

# Check the actual coefficients to see the shrinkage effect
# Get coefficients from GLMNet object
coeffs = ridge_final.betas[:, 1]  # First (and only) lambda solution
intercept = ridge_final.a0[1]     # Intercept term

println("Ridge intercept: ", intercept)
println("Ridge coefficients: ", coeffs)
# Compare with original OLS for the same variables
ols_full = lm(@formula(margin_pct ~ nocollege_pct + college_pct + grad_pct), df)
println("OLS coefficients: ", GLM.coef(ols_full))

# Original OLS with all three variables
ols_full = lm(@formula(margin_pct ~ nocollege_pct + college_pct + grad_pct), df)
ols_coeffs = GLM.coef(ols_full)

println("\nComparison:")
println("OLS coefficients: ", ols_coeffs[2:end])  # Skip intercept
println("Ridge coefficients: ", coeffs)
println("Shrinkage factors: ", coeffs ./ ols_coeffs[2:end])
