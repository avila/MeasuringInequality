***************************************************************************
**** In many data sets, income is top coded (here: y>=9000) ***************
**** If so, we can impute the top coded incomes using the Pareto dist. ****
**** We assume that income is Pareto distributed for incomes >5500. *******
***************************************************************************

**** Top coded incomes

clear

input F	y_top
.05	1000
.1	2000
.15	2500
.2	2800
.25	6000
.3	6200
.35	6350
.4	6520
.45	6710
.5	6930
.55	7180
.6	7460
.65	7800
.7	8220
.75	8730
.8	9000
.85	9000
.9	9000
.95	9000
.99	9000
end


**** Step 1: Estimation of Pareto alpha

* Define lowest income where Pareto gets started

global y_low= 6000 // changed so that it matches the observed Lower bound
global lb_pct .25  // the lowerbound is at the 25th percentile

* Define variables for estimation 

gen P=1-F
gen lnP=ln(P)
gen lny_top=ln(y_top)

* Perform estimation

reg lnP lny_top if y_top < 9000 & y_top>$y_low
matrix list e(b)
local alpha=-_b[lny_top]

disp `alpha'

**** Step 2: Imputation 

* Compute estimates of income

gen y_hat=(1-F)^(1/-`alpha')*$y_low
gen F2 = (F - $lb_pct) * (1/(1-$lb_pct)) // blown-out CDF
gen P2 = 1-F2

gen y_hat2=(1-F2)^(1/-`alpha')*$y_low
* Generate imputed income variable

gen y_imp=y_top if y_top<9000
replace y_imp=y_hat if y_top>=9000

gen y_imp2 = y_top if y_top<9000
replace y_imp2 = y_hat2 if y_top>=9000


browse

*****
