

*** 6b. predict top percentiles ***

********************************************************************************
*
* Calculating example values for Top 5%, 1%, 0.1%
*
********************************************************************************

* NOTE: Calculate the min. net wealth that the Top x% richest population has.
*		We use the fitted Pareto's Alpha of the Pretest and predict the Top 
*		net nwealths of the SOEP.

* use: 	threshold = sc_thres_1_p95 
*		alpha = sc_alpha_1_p95_pt

* calculation: 	F = 1-(y_thres/y)^sc_alpha
* 				nw_hat = ((P)^(-1/sc_alpha)) * nw_thres where P=1-F

scalar m=5
local pctile p95 p99

use "${outpath}soep_pretest_2.dta", clear

* 1. Generate predicted nw variable
gen nw_hat_1_p95_ = _1_nw if D_pretest == 0 & _1_nw < `=sc_thres_1_p95'
gen D_nw_hat_1_p95_ = 0
replace D_nw_hat_1_p95_ = 1 if D_pretest == 0 & _1_nw < `=sc_thres_1_p95'

/* NOTE: sc_alphas are negative */
replace nw_hat_1_p95_ = ((1-F_sp_1_)^(1/`=sc_alpha_1_p95_pt'))*`=sc_thres_1_p95' if D_pretest == 0 & _1_nw >= `=sc_thres_1_p95'

/*
sort D_pretest _1_nw
br nw_hat_1_p95_ _1_nw D_pretest
*/


* 2. Goodness of fit measures: mse, rmse, rrmse
* TODO


* 2. Predict Top Wealths for selected Top percentiles
* Top 5%
scalar sc_nw_hat_top50 = ((1-0.95)^(1/`=sc_alpha_1_p95_pt'))*`=sc_thres_1_p95'
* Top 1%
scalar sc_nw_hat_top10 = ((1-0.99)^(1/`=sc_alpha_1_p95_pt'))*`=sc_thres_1_p95'
* Top 0.1%
scalar sc_nw_hat_top01 = ((1-0.999)^(1/`=sc_alpha_1_p95_pt'))*`=sc_thres_1_p95'

di "Top 5%: `=sc_nw_hat_top50'"
di "Top 1%: `=sc_nw_hat_top10'"
di "Top 0.1%: `=sc_nw_hat_top01'"


* 3. total sum net wealth of Top (Top 5%, 1% and Top 0.1%)
* TODO

* 4. Table: goodness of fit measures + predicted Top pct + total sum
* TODO

* 5. Graphs: actual data vs fitted data
* TODO



***

