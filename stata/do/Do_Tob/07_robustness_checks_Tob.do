
*** 7. Robustness Checks ***

/* 
Note: Below, we test the equality of pareto's alpha of SOEP vs Pretest by 
applying Stata's suest (seemingly unrelated regressions). 

Results: 
1. ttest: two-sided / right-sided: we can reject the null, there is a difference 
		between both alhpas; left-sided: there is no difference (?!)
2. suest: across all imputations and for all pctile thresholds we cannot reject 
the null that both alphas are not equal.
*/

********************************************************************************
*		
*	Test equality of Pareto's Alpha for SOEP vs. Pretest
*		1. ttest
*		2. Hausman (suest)
* 		3. Root of discrepancy test
*		
********************************************************************************


use "${outpath}soep_pretest_2.dta", clear

********************************************************************************
*	1. ttest 
********************************************************************************

/*
foreach pct of local pctile {
	forval imp=1(1)`=m' {
		di _newline in red "+++++ ttest: ln_nw_`imp'_ SOEP = ln_nw_`imp'_ Pretest +++++" 
		di in red "+++++ threshold: `pct', imputation: `imp' +++++"
		ttest ln_nw_`imp'_ if ln_nw_`imp'_ >= sc_thres_`imp'_`pct', by(D_pretest)
	}
}
*/

********************************************************************************
*	2. Hausman-test suest (seemingly unrelated regressions)
********************************************************************************
/*
 vgl. https://stats.idre.ucla.edu/stata/code/comparing-regression-coefficients-across-groups-using-suest/

 suest + test: test linear relationships among the estimated parameters
 test performs Wald tests of simple and composite linear hypotheses about the parameters of the most recently fit model.

 suest H0: pareto-alpha SOEP - pareto-alpha Pretest = 0
 suest H0: alpha_sp and alpha_pt are equal
*/

* initializing suest regressions
local suest_regtest ""
foreach pct of local pctile {
	foreach type in sp pt {
		forval imp=1(1)5 {
			local suest_regtest `suest_regtest' reg_`imp'_`pct'_`type'
		}
	}
}
suest `suest_regtest'

* run suest, Hausman-test equality of alphas
foreach pct of local pctile {
	forval imp=1(1)5 {
		
		* test SOEP vs. Pretest
		test [reg_`imp'_`pct'_sp_mean]ln_nw_`imp'_=[reg_`imp'_`pct'_pt_mean]ln_nw_`imp'_
		scalar sc_testpval_`imp'_`pct' = r(p)
		
		* test within SOEP (Pretest) across thresholds
		foreach dat in sp pt {
			if inlist("`pct'","p95","p99") /* in case local pct is changed */ {
				test [reg_`imp'_p95_`dat'_mean]ln_nw_`imp'_=[reg_`imp'_p99_`dat'_mean]ln_nw_`imp'_
				scalar sc_testpval_`imp'_`dat' = r(p)
			}
		}
	}
}


********************************************************************************
* 3. Root of discrepancy test
********************************************************************************


		* Calculate average number of observations for degrees of freedom		
		qui scalar sc_n_p95_sp = 1/5 * (sc_n_1_p95_sp + sc_n_2_p95_sp + sc_n_3_p95_sp + sc_n_4_p95_sp + sc_n_5_p95_sp)
		qui scalar sc_n_p95_pt = 1/5 * (sc_n_1_p95_pt + sc_n_2_p95_pt + sc_n_3_p95_pt + sc_n_4_p95_pt + sc_n_5_p95_pt)
		qui scalar sc_n_p99_sp = 1/5 * (sc_n_1_p99_sp + sc_n_2_p99_sp + sc_n_3_p99_sp + sc_n_4_p99_sp + sc_n_5_p99_sp)
		qui scalar sc_n_p99_pt = 1/5 * (sc_n_1_p99_pt + sc_n_2_p99_pt + sc_n_3_p99_pt + sc_n_4_p99_pt + sc_n_5_p99_pt)

				
		** Test equality of SOEP alphas with Pretest alphas
			
				
				* Test SOEP,P95 vs. Pretest,P95
				qui scalar sc_test_nom_p95 = abs(sc_avgalpha_p95_sp - sc_avgalpha_p95_pt)
				qui scalar sc_test_denom_p95 = abs(sqrt(sc_tv_p95_sp + sc_tv_p95_pt))
			
				qui scalar sc_pval_p95 = 2*ttail((sc_n_p95_sp + sc_n_p95_pt - 2), abs(sc_test_nom_p95 / sc_test_denom_p95))
				
				* Test SOEP,P99 vs. Pretest,P99
				qui scalar sc_test_nom_p99 = abs(sc_avgalpha_p99_sp - sc_avgalpha_p99_pt)
				qui scalar sc_test_denom_p99 = abs(sqrt(sc_tv_p99_sp + sc_tv_p99_pt))
				
				qui scalar sc_pval_p99 = 2*ttail(sc_n_p99_sp + sc_n_p99_pt - 2, abs(sc_test_nom_p99 / sc_test_denom_p99))
		
		
		** Test equality of alphas within datasets at different percentiles
		
				* Test SOEP,P95 vs. SOEP,P99
				qui scalar sc_test_nom_sp = abs(sc_avgalpha_p95_sp - sc_avgalpha_p99_sp)
				qui scalar sc_test_denom_sp = abs(sqrt(sc_tv_p95_sp + sc_tv_p99_sp))
				
				qui scalar sc_pval_sp = ttail(sc_n_p95_sp + sc_n_p99_sp - 2, abs(sc_test_nom_sp / sc_test_denom_sp))
				
				* Test Pretest,P95 vs. Pretest, P99
				qui scalar sc_test_nom_pt = abs(sc_avgalpha_p95_pt - sc_avgalpha_p99_pt)
				qui scalar sc_test_denom_pt = abs(sqrt(sc_tv_p95_pt + sc_tv_p99_pt))
				
				qui scalar sc_pval_pt = ttail(sc_n_p95_pt + sc_n_p99_pt - 2, abs(sc_test_nom_pt / sc_test_denom_pt))
				
				
		** Display results
		
				di in red "H0 (alpha_p95_sp == alpha_p95_pt) can be rejected to any signifance level above the p-value of `=sc_pval_p95'." 	_newline ///
				"H0 (alpha_p99_sp == alpha_p99_pt) can be rejected to any signifance level above the p-value of `=sc_pval_p99'." 			_newline ///
				"H0 (alpha_p95_sp == alpha_p95_sp) can be rejected to any signifance level above the p-value of `=sc_pval_sp'." 			_newline ///
				"H0 (alpha_p95_pt == alpha_p99_pt) can be rejected to any signifance level above the p-value of `=sc_pval_pt'." 
		
					
* display all produced estimates, scalars
estimates dir
scalar dir


***
