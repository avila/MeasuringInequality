
*** 7. Robustness Checks ***

/*
TODO: pack scalars into latex table?
TODO: multiply alphas with (-1) 
*/

********************************************************************************
*		
*	OUTLINE
*		
*		1. Hausman (suest + mi dataset)
*		2. Test of Overlapping CIs
*
*		Note: Below, we test the equality of pareto's alpha of SOEP vs Pretest and 
*		with lower bounds set at the 95th and 99th percentile.  
*		
********************************************************************************

********************************************************************************
*
*	1. Hausman-test suest (seemingly unrelated regressions)
*
********************************************************************************
/*
 based on: https://stats.idre.ucla.edu/stata/code/comparing-regression-coefficients-across-groups-using-suest/
 and https://www.stata.com/support/faqs/statistics/combine-results-with-multiply-imputed-data/#suest

 suest H0: pareto-alpha_SOEP - pareto-alpha_Pretest = 0
 suest H0: alpha_sp and alpha_pt are equal
*/

use "${outpath}soep_pretest_2_MI.dta", clear

********************************************************************************
* define mysuest program
********************************************************************************

cap program drop mysuest
program mysuest, eclass properties(mi)
		// USAGE: mysuest "NameOfFirstReg" "FirstReg" "NameOfSecondReg" "SecondReg"

        version 14.2
		args data1 model1 data2 model2

        qui `model1'
        estimates store `data1'
        qui `model2'
        estimates store `data2'
        suest `data1' `data2'
        estimates drop `data1' `data2'
        
        ereturn local title "Seemingly unrelated estimation"
end

********************************************************************************
* Test mi estimate
********************************************************************************

scalar sc_lb95 = 340000
scalar sc_lb99 = 880000

// "esampvaryok" necessary due to variation in observations across imputations.
mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= sc_lb95 & D_pt == 0) [iw=W]
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= sc_lb95 & D_pt == 1) [iw=W]

mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= sc_lb99 & D_pt == 0) [iw=W]
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= sc_lb99 & D_pt == 1) [iw=W]

********************************************************************************
* Run mi estimate with mysuest
********************************************************************************

*** Lower bound @95 pct
mi estimate, esampvaryok: mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb95 & D_pt == 0) [iw=W]" ///
		"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb95 & D_pt == 1) [iw=W]"
qui matrix mat_tmp =  e(b_mi)
scalar sc_alpha_sp_95_mean = mat_tmp[1,1]
scalar sc_alpha_pt_95_mean = mat_tmp[1,4]

qui matrix mat_tmp = r(table)
scalar sc_alpha_sp_95_ci_low = mat_tmp[5,1]
scalar sc_alpha_sp_95_ci_upp = mat_tmp[6,1]

scalar sc_alpha_pt_95_ci_low = mat_tmp[5,4]
scalar sc_alpha_pt_95_ci_upp = mat_tmp[6,4]

mi estimate, vartable nocitable // Variance following Rubin's rule

*** Lower bound @99 pct
mi estimate, esampvaryok: mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb99 & D_pt == 0) [iw=W]" ///
		"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb99 & D_pt == 1) [iw=W]"
		* note: only iweight seems to work in mi estimate + suest, otherwise error. 
qui matrix mat_tmp =  e(b_mi)
scalar sc_alpha_sp_99_mean = mat_tmp[1,1]
scalar sc_alpha_pt_99_mean = mat_tmp[1,4]
		
qui matrix mat_tmp = r(table)
scalar sc_alpha_sp_99_ci_low = mat_tmp[5,1]
scalar sc_alpha_sp_99_ci_upp = mat_tmp[6,1]

scalar sc_alpha_pt_99_ci_low = mat_tmp[5,4]
scalar sc_alpha_pt_99_ci_upp = mat_tmp[6,4]

mi estimate, vartable nocitable // Variance following Rubin's rule

foreach type in pt sp {
	foreach pct in 95 99 {
		di in red "alpha (`type', `pct', mean): `=sc_alpha_`type'_`pct'_mean'"
		foreach ci in low upp {
			di in red "alpha (`type', `pct', `ci'): `=sc_alpha_`type'_`pct'_ci_`ci''"
		}
	}
}

********************************************************************************
* Run mi estimate with mysuest and test difference accross coefficients
********************************************************************************
/*
RESULTS:	at 95pct lower bound: pvalue = 0.058. 
			-> almost reject H_0 that alpha_pt == alpha_sp 
			
			at 99pct lower bout: pvalue = 0.270
			-> not able to reject h_0. 
			-> confidence intervals are larger due to lower number of observations
			-> indicates that with more observations, more conclusive results 
			   could be achieved. 
*/

foreach pct in 95 99 {
	di in red 80 * "*"
	di in red "* Test of coeffecients (`pct'th percentile)"
	mi estimate (diff: [soep_mean]ln_nw - [pretest_mean]ln_nw), esampvaryok nocoef: 	///
		mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb`pct' & D_pt == 0) [iw=W]"      	///
				"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb`pct' & D_pt == 1) [iw=W]"
	mi testtransform diff
	scalar sc_pval_`pct' = r(p)
	scalar sc_F_`pct' = r(F)	
}

********************************************************************************
*
*	2. Graphical analysis of overlapping CIs
*
********************************************************************************

use "${outpath}soep_pretest_2.dta", clear

/* 
Idea: 	Given alpha_SOEP_mean alpha_Pretest_mean and their total variances
		We simulate normal distrib. based on both location parameters and plot them
*/

clear
set seed 12593
set obs 100
set graph on

/* Temporarily */
scalar sc_meanalpha_p95_sp = 2.0
scalar sc_totalvar_p95_sp = 1.0
scalar sc_meanalpha_p95_pt = 1.2
scalar sc_totalvar_p95_pt = 0.35

gen alpha_p95_sp = rnormal(sc_meanalpha_p95_sp, sc_totalvar_p95_sp)
gen alpha_p95_pt = rnormal(sc_meanalpha_p95_sp, sc_totalvar_p95_sp)


* plot 1
histogram alpha_p95_sp, frequency normal color(%0) scheme(s2mono)
/* TODO: https://www.statalist.org/forums/forum/general-stata-discussion/general/1417021-plotting-two-or-more-overlapping-density-curves-on-the-same-graph */


* plot 2
kdensity alpha_p95_sp, color(%30) recast(area) ///
addplot(kdensity alpha_p95_pt, color(%30) recast(area)) ///
legend(order(1 "SOEP" 2 "Pretest"))

/*
* plot 3
twoway 	(kdensity alpha_p95_sp, kernel(gaussian)) ///
		(kdensity alpha_p95_pt, kernel(gaussian))
*/

***


