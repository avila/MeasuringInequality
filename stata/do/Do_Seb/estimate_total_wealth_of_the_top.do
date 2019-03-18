/*

*** results from Sebastian ***

set more off
use "$out_path/soep_pretest_2.dta", clear

*** 1.) descriptive statistics *************************************************

* a) Use the mean of imputations from SOEP and Pretest

tabstat nwmean_soep [fw = round(W_sp)] if D_pretest==0, s(n mean p50 p75 p90 p95 p99 min max sd) format(%14.2f) c(v)
tabstat nwmean_soep if D_pretest==0, s(n mean p50 p75 p95 p90 p99 min max sd) format(%14.2f) c(v)

tabstat nwmean_pt [fw = round(W_pt_dest)] if D_pretest==1, s(n mean p50 p75 p90 p95 p99 min max sd) format(%14.2f) c(v)
tabstat nwmean_pt if D_pretest==1, s(n mean p50 p75 p90 p95 p99 min max sd) format(%14.2f) c(v)

*** 2.) Estimating Parteo's alpha.

* a) Use the mean of imputations from SOEP and Pretest for comparison only

*** SOEP_mean ******************************************************************

* generate log net wealth

gen ln_nwmean_soep = ln(nwmean_soep)

* generate cumulative population share 

sort D_pretest nwmean_soep
qui sum W_sp if D_pretest==0
scalar sc_N = r(sum)
gen cum_pop_share_soep_mean = sum(W_sp)/sc_N if D_pretest==0
replace cum_pop_share_soep_mean=0.99999 if cum_pop_share_soep_mean==1

* generate P = 1-F(y) and log(P)

gen P_soep_mean = 1 - cum_pop_share_soep_mean if D_pretest==0
gen lnP_soep_mean = ln(P_soep_mean) if D_pretest==0	

* estimate Paretos alpha for the lower bounds p95 and p99 with OLS

forvalues low=95(4)99 {
	sum nwmean_soep [fw = round(W_sp)] if D_pretest==0, d
	scalar lowbound_`low'=r(p`low')
	reg lnP_soep_mean ln_nwmean_soep [fw=round(W_sp)] if nwmean_soep>lowbound_`low'
	matrix list e(b)
	scalar alpha_soepmean_`low'=abs(_b[ln_nwmean_soep])
}
	
*** Pretest_mean ***************************************************************

* generate log net wealth

gen ln_nwmean_pt = ln(nwmean_pt)

* generate cumulative population share 

sort D_pretest nwmean_pt
qui sum W_pt_dest if D_pretest==1
scalar sc_N = r(sum)
gen cum_pop_share_pt_mean = sum(W_pt_dest)/sc_N if D_pretest==1
replace cum_pop_share_pt_mean=0.99999 if cum_pop_share_pt_mean==1

* generate P = 1-F(y) and log(P)

gen P_pt_mean = 1 - cum_pop_share_pt_mean if D_pretest==1
gen lnP_pt_mean = ln(P_pt_mean) if D_pretest==1	

* estimate Paretos alpha for the lower bounds p95 and p99 (FROM SOEP) (!) with OLS

forvalues low=95(4)99 {
	reg lnP_pt_mean ln_nwmean_pt [fw=round(W_pt_dest)] if nwmean_pt>lowbound_`low'
	matrix list e(b)
	scalar alpha_ptmean_`low'=abs(_b[ln_nwmean_pt])
}

********************************************************************************

forval i=1(1)5 {
	
*** SOEP_imputed ***************************************************************

* The variables for the estimation are already defined in chapter 03!

* estimate Paretos alpha for the lower bounds p95 and p99 with OLS

	forvalues low=95(4)99 {
		sum _`i'_nw [fw = round(W_sp)] if D_pretest==0, d
		scalar lowbound_`i'_`low'=r(p`low')
		reg lnP_sp_`i'_ ln_nw_`i'_ [fw=round(W_sp)] if _`i'_nw>lowbound_`i'_`low' & D_pretest==0 
		matrix list e(b)
		scalar alpha_soep_`i'_`low'=abs(_b[ln_nw_`i'_])

	}	

*** Pretest_imputed ************************************************************
	
	forvalues low=95(4)99 {
		reg lnP_pt_`i'_ ln_nw_`i'_ [fw=round(W_pt_dest)] if _`i'_nw>lowbound_`i'_`low' & D_pretest==1 
		matrix list e(b)
		scalar alpha_pt_`i'_`low'=abs(_b[ln_nw_`i'_])
	}	
}

*** Predict the top net wealth data with different alphas. Three alternatives: ***

*** At the front: calcualte the total wealth of the overall population, of the Top 5 % and of the Top 1 % using only SOEP ***

*** unweighted *** 

sum nwmean_soep if D_pretest==0, d
scalar totalwealth_overall_unw = r(sum)/1000000
sum nwmean_soep if D_pretest==0 & nwmean_soep > r(p95)
scalar totalwealth_top5_unw = r(sum)/1000000

sum nwmean_soep if D_pretest==0, d
sum nwmean_soep if D_pretest==0 & nwmean_soep > r(p99)
scalar totalwealth_top1_unw = r(sum)/1000000

*** weighted ***

sum nwmean_soep [fw = round(W_sp)] if D_pretest==0
scalar totalwealth_overall = r(sum)/1000000
sum nwmean_soep [fw = round(W_sp)] if D_pretest==0 & nwmean_soep > lowbound_95
scalar totalwealth_top5 = r(sum)/1000000
sum nwmean_soep [fw = round(W_sp)] if D_pretest==0 & nwmean_soep > lowbound_99
scalar totalwealth_top1 = r(sum)/1000000

*** Pretest: weighted (note: we just describe the Top 5 % and 1 % by using the corresponding percentiles from the SOEP) ***

sum nwmean_pt [fw = round(W_pt_dest)] if D_pretest==1 & nwmean_pt > lowbound_95
scalar totalwealth_pt_top5 = r(sum)/1000000
sum nwmean_pt [fw = round(W_pt_dest)] if D_pretest==1 & nwmean_pt > lowbound_99
scalar totalwealth_pt_top1 = r(sum)/1000000
*/
*** I. use formular y_hat = exp(ln(lowbound)-(ln(P)/alpha)) ********************

*** estimate top wealth with Paretos Alpha from 95. percentile (Mean Pretest prediction)

gen nwmean_hat_p95 = nwmean_soep if D_pretest==0 & nwmean_soep <= lowbound_95
gen top5nw_imp = exp(ln(lowbound_95)-(ln(P_soep_mean)/alpha_ptmean_95)) if D_pretest==0 & nwmean_soep > lowbound_95
replace nwmean_hat_p95 = top5nw_imp if D_pretest==0 & nwmean_soep > lowbound_95

*** calculate top wealth information ***

sum nwmean_hat_p95 [fw = round(W_sp)] if D_pretest==0
scalar totalwealth_overall_p95 = r(sum)/1000000
sum nwmean_hat_p95 [fw = round(W_sp)] if D_pretest==0 & nwmean_hat_p95 > lowbound_95
scalar totalwealth_top5_p95 = r(sum)/1000000
sum nwmean_hat_p95 [fw = round(W_sp)] if D_pretest==0 & nwmean_hat_p95 > lowbound_99
scalar totalwealth_top1_p95 = r(sum)/1000000

*** II. use formular y_hat = (1-cum_pop_share)^(1/-alpha)*lowbound *************

gen nwmean_hat_p992 = nwmean_soep if D_pretest==0 & nwmean_soep < lowbound_99
gen top1nw_imp2 = P_soep_mean^(1/-alpha_ptmean_99)*lowbound_99 if D_pretest==0 & nwmean_soep  
replace nwmean_hat_p992 = top1nw_imp2 if D_pretest==0 & nwmean_soep >= lowbound_99
sum nwmean_hat_p992, d 
return list

*** calculate top wealth information ***

sum nwmean_hat_p992 [fw = round(W_sp)] if D_pretest==0
scalar totalwealth_overall_p992 = r(sum)/1000000
sum nwmean_hat_p992 [fw = round(W_sp)] if D_pretest==0 & nwmean_hat_p992 > lowbound_95
scalar totalwealth_top5_p992 = r(sum)/1000000
sum nwmean_hat_p992 [fw = round(W_sp)] if D_pretest==0 & nwmean_hat_p992 > lowbound_99
scalar totalwealth_top1_p992 = r(sum)/1000000

	
*** --> implausible values for the estimated top wealth values. 
