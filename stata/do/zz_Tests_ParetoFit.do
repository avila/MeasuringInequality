********************************************************************************
*		
*	APPENDIX?: Test paretofit 
*		
********************************************************************************

/* 
This scripts runs the paretofit command over p95 and p99 percentiles thresholds
for pretest and soep datasets for each imputeded netweatlh column. 

NOTE: avila: I am not sure about the weights in the Pretest paretofit command. 
but it doesn't change much...
*/

use "${outpath}soep_pretest_2.dta", clear

* m: number of imputations
scalar m = 5

* define threshold levels as percentiles of SOEP
local pctile p95 p99

* define datasets: SOEP (sp), Pretest (pt)
local data pt sp //

foreach dat of local data {
	forval imp=1(1)`=m' {
		foreach pc of local pctile {
			// always get lower bound from SOEP. 
			qui sum _`imp'_nw if D_pretest==0, d
			scalar sc_thres_`imp'_`pc'_sp = r(`pc')
			
			di in red 80 * "="
			di in red "Data: `dat'. Imputation: `imp'. Percentile: `pc'. Lower bound: `=sc_thres_`imp'_`pc''"
			di in red 80 * "="
			
			if "`dat'" == "sp" {
				paretofit _`imp'_nw if D_pretest == 0 [weig=W_`dat'], x0(`=sc_thres_`imp'_`pc'_sp') cdf(cdf_`imp'_`pc'_`dat') robust
				scalar sc_alpha_pfit_`imp'_`pc'_`dat' = e(ba)
			}
			if "`dat'" == "pt" {
				paretofit _`imp'_nw if D_pretest == 1 [weig=W_`dat'], x0(`=sc_thres_`imp'_`pc'_sp') cdf(cdf_`imp'_`pc'_`dat') robust
				scalar sc_alpha_pfit_`imp'_`pc'_`dat' = e(ba)
			}
		}
	}
}


* summary 
// pareto fit using level (not log) variables. Options:	x0 -> lower bound 
//							cdf() -> creates a cdf value for each observatoin
//							robust -> robust std errors
//
// results are more stable than OLS regressions. 
// results are much lower that OLS regressions. 


// test one plot for one imputation for sp
preserve
	drop if cdf_5_p95_sp >= .
	line  cdf_5_p95_sp _5_nw, name(fig_in_levels)
	
	gen P_5_p95_sp = 1 - cdf_5_p95_sp
	line P_5_p95_sp _5_nw, yscale(log) xscale(log) name(fig_log_log_scale)
	
	// P2: divide by 20, so that 1 -> 0.05. 
	gen P2 = P_5_p95_sp / 20
	line P2 _5_nw, yscale(log) xscale(log) name(fig_log_log_scale_2)
restore
