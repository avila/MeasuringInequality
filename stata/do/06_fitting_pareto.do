
*** 6. Fitting Pareto ***

/* Note: Here, pareto alphas are estimated on the basis of the SOEP and the 
	pretest dataset. As we have 5 imputed net wealths, 5 alphas are estimated 
	for each data set. As thresholds serve the p95 and p99 of the SOEP.
	alpha, sd, N, r2 are saved to scalars.
	In total, we have 20 alphas: 5x SOEP with p95 thres, 5x SOEP with p99 thres,
	5x pretest with p95 thres,  5x pretest with p99 thres.
	
	content:
	1.	Calculating Pareto's alphas
	2.	Calculating CI of alpha according to Rubin (1987)
	*/

use "${outpath}soep_pretest_2.dta", clear

* m: number of imputations
scalar m = 5

* define threshold levels as percentiles of SOEP
local pctile p95 p99

* define percentile of alpha CI
scalar sc_alphaCI = .975

* global: display all scalars below
global show_all "TRUE"


********************************************************************************
*		
*		1.	Calculating Pareto's alphas
*		
********************************************************************************

forval imp=1(1)`=m' {

	* Calculate Threshold Values (only for SOEP)
	qui sum _`imp'_nw if D_pt==0, d
	foreach pc of local pctile {
		scalar sc_thres_`imp'_`pc' = r(`pc')
	}
	
	* Calculate Pareto's Alpha (SOEP and Pretest, with threshold from SOEP)
	foreach type in sp pt {

		foreach pct of local pctile {
	
			if "`type'" == "sp" {
				local D_type 0
			}
			if "`type'" == "pt" {
				local D_type 1
			}
			
				* run regression
				qui reg lnP_`type'_`imp'_ ln_nw_`imp'_ if (_`imp'_nw > sc_thres_`imp'_`pct' & D_pt==`D_type') [fw=round(W_`type')]
					
					* name regression
					estimates title: reg lnP_`type'_`imp'_ ~ ln_nw_`imp'_ (thres: `pct')
					
					* save regression
					est store reg_`imp'_`pct'_`type'

					* save scalars
					scalar sc_alpha_`imp'_`pct'_`type' = _b[ln_nw]
					scalar sc_sd_`imp'_`pct'_`type' = _se[ln_nw]
					scalar sc_N_`imp'_`pct'_`type' = e(N)
					scalar sc_rss_`imp'_`pct'_`type' = e(rss) /* resid. sum of sq. needed for CI calc. */
					scalar sc_r2_`imp'_`pct'_`type' = e(r2)
					scalar sc_cons_`imp'_`pct'_`type' = _b[_cons]

				* Display results
				if "$show_all" == "TRUE" {
					if "`type'" == "sp" {
						local data "SOEP"
					}
					else {
						local data "Pretest"
					}
					
					di in red "+++++++++++++++++++++++"
					di "dataset:		`data'"
					di "threshold pctile: 	`pct'"
					di "threshold value: 	sc_thres_`imp'_`pct' = `=sc_thres_`imp'_`pct''"
					di "alpha:		sc_alpha_`imp'_`pct'_`type' = `=sc_alpha_`imp'_`pct'_`type''"
					di "sd:    		sc_sd_`imp'_`pct'_`type' = `=sc_sd_`imp'_`pct'_`type''"	
					di "N: 			sc_N_`imp'_`pct'_`type' = `=sc_N_`imp'_`pct'_`type''"
					di "sse:		sc_sse_`imp'_`pct'_`type' = `=sc_rss_`imp'_`pct'_`type''"
					di "r2:			sc_r2_`imp'_`pct'_`type' = `=sc_r2_`imp'_`pct'_`type''"
				}
		}
	}
}


********************************************************************************
*		
*		2.	Calculating CI of alpha according to Rubin (1987)
*		
********************************************************************************


* SOEP (sp), p95, 1. imputation

* given: rss

* 1. weighted within-variance (wwv) = SSE / sum(((W*ln(nw)) - (sum( W*ln(nw) / sum(W) )))^2)

* 2. average within-variance (awv)

* 3. estimate of alpha / average alpha (avga)

* 4. between-variance of alphas (bva)

* 5. total variance (totvar) = awv + (1 + m^(-1)) * bva

* 6. CI: lower bound (cilb), upper bound (ciub)

* display results



********************************************************************************
********************************************************************************

* Zuerst: SOEP (sp), p95

* given: rss denotes SSE = sum of squared errors

* 1. WV: within-variance (see formula x.x on page xx) 

*forval imp=1(1)5 {
	
	*generate weighted mean of logged net wealth (wmeanlnnw)
	qui sum W_sp if D_pt==0
	scalar sc_wmeanlnnw_p95_sp_1 = (W_sp * ln_nw_1_)/sc_N_1_sp_
	
	*estimate within variance (= SSE / sum(((W*ln(nw)) - (sum( W*ln(nw) / sum(W) )))^2)	
	estimates restore reg_1_p95_sp
	qui scalar sc_wv_p95_sp_1 = e(rss) / sum((sum(W_sp * ln_nw_1_)/sc_w_mean_ln_nw_p95_sp_1)^2) /* TODO */
	
	if "$show_all" == "TRUE" {
	di "within variancec: imp 1: `=sc_wv_p95_sp_1'; imp2: `=sc_wv_p95_sp_2'; imp3: `=sc_wv_p95_sp_3'; imp4: `=sc_wv_p95_sp_4'; imp5: `=sc_wv_p95_sp_5'" 
	}
	
}


* 2. AWV: average within-variance (according to formula x.x on page xx)
scalar sc_awv_p95_sp_ = 1/m*((sc_swv_sp_p95_1+sc_wv_sp_p95_2+sc_wv_sp_p95_3+sc_wv_sp_p95_4+sc_wv_sp_p95_5) / sc_N_1_p95_sp)

if "$show_all" == "TRUE" {
		di " avg. within variance: `awv_p95_sp_'" 
}


* 3. estimate of alpha (according to formula x.x on page xx)
qui scalar sc_avgalpha_p95_sp = 1/m*(sc_alpha_1_p95_sp + sc_alpha_2_p95_sp + sc_alpha_3_p95_sp + sc_alpha_4_p95_sp + sc_alpha_5_p95_sp)

if "$show_all" == "TRUE" {
		di "alphas: `=sc_alpha_1_p95_sp' `=sc_alpha_2_p95_sp' `=sc_alpha_3_p95_sp'' `=sc_alpha_4_p95_sp' `=sc_alpha_5_p95_sp''" 
		_newline "avg. alpha: `=sc_avgalpha_p95_sp'"
		}
		

* 4. BV: between-variance of the alphas (according to formula x.x on page xx)
qui scalar sc_bv_p95_sp = 0

		forval i=1(1)`=m' {
			qui scalar sc_bv_p95_sp = sc_bv_p95_sp + (sc_alpha_`i'_p95_sp - sc_avgalpha_p95_sp)^2
		}
		
		if "$show_all" == "TRUE" {		
		di  "between variance: `=sc_bv_p95_sp'"
		}


* 5. TV: total variance (according to formula x.x on page xx) 			(awv + (1 + m^(-1)) * bv)
qui scalar sc_tv_p95_sp = sc_awv_p95_sp_ + (1+m^-1) * sc_bv_p95_sp
		if "$show_all" == "TRUE" {
		di "total variance: `=sc_tv_p95_sp'"
		}


* 6.1 CI: lower bound and upper bound (according to formulas x.x and x.x on page xx)
qui scalar sc_cilb_p95_sp = sc_avgalpha_p95_sp - invnorm(sc_alphaCI) * sqrt(sc_tv_p95_sp)
qui scalar sc_ciub_p95_sp = sc_avgalpha_p95_sp + invnorm(sc_alphaCI) * sqrt(sc_tv_p95_sp)
		
********************************************************************************
********************************************************************************




























foreach type in sp pt {

	foreach pct of local pctile {

	* 1. sample variance
		if "$show_all" == "TRUE" {
		di " within variances: `=sc_sd_1_`pct'_`type''^2 `=sc_sd_2_`pct'_`type''^2 `=sc_sd_3_`pct'_`type''^2 `=sc_sd_4_`pct'_`type''^2 `=sc_sd_5_`pct'_`type''^2" 
		}
		
	* 2. avg. within variance
		qui scalar sc_avgwithinsd2_`pct'_`type' = 1/m*((sc_sd_1_`pct'_`type'^2 + sc_sd_2_`pct'_`type'^2 + sc_sd_3_`pct'_`type'^2 + sc_sd_4_`pct'_`type'^2 + sc_sd_5_`pct'_`type'^2) / sc_N_1_`pct'_sp)
		if "$show_all" == "TRUE" {
		di " avg. within variances: `=sc_avgwithinsd2_`pct'_sp'" 
		}
		
	* 3. avg. alpha across all imp.
		qui scalar sc_avgalpha_`pct'_`type' = 1/m*(sc_alpha_1_`pct'_`type' + sc_alpha_2_`pct'_`type' + sc_alpha_3_`pct'_`type' + sc_alpha_4_`pct'_`type' + sc_alpha_5_`pct'_`type')
		if "$show_all" == "TRUE" {
		di "alphas: `=sc_alpha_1_`pct'_`type'' `=sc_alpha_2_`pct'_`type'' `=sc_alpha_3_`pct'_`type'' `=sc_alpha_4_`pct'_`type'' `=sc_alpha_5_`pct'_`type''" _newline "avg. alpha: `=sc_avgalpha_1_`pct'_`type''"
		}
		
	* 4. between variance
		qui scalar sc_betweensd2_`pct'_`type' = 0
		forval i=1(1)`=m' {
			qui scalar sc_betweensd2_`pct'_`type' = sc_betweensd2_`pct'_`type' + (sc_alpha_`i'_`pct'_`type' - sc_avgalpha_`pct'_`type')^2
		}	
		if "$show_all" == "TRUE" {		
		di  "between variance: `=sc_betweensd2_`pct'_`type''"
		}
		
	* 5. total variance = avg within variance + (1+m^-1)*between variance
		qui scalar sc_totalsd2_`pct'_`type' = sc_avgwithinsd2_`pct'_`type' + (1+m^-1)*sc_betweensd2_`pct'_`type'
		if "$show_all" == "TRUE" {
		di "total variance: `=sc_totalsd2_`pct'_sp'"
		}
		
	* 6. CI: lower bound (cilb), upper bound (ciub)
		qui scalar sc_cilb_`pct'_`type' = sc_avgalpha_`pct'_`type' - invnorm(sc_alphaCI) * sqrt(sc_totalsd2_`pct'_`type')
		qui scalar sc_ciub_`pct'_`type' = sc_avgalpha_`pct'_`type' + invnorm(sc_alphaCI) * sqrt(sc_totalsd2_`pct'_`type')

	* 7. show all scalars
		scalar sc_alphaCI_left=1-`=sc_alphaCI'
		di in red "type of dataset: `type', obs: `=sc_N_1_`pct'_`type''; imputations: `=m'; threshold: `pct'" _newline
		di in red "alphas: `=sc_alpha_1_`pct'_`type'' `=sc_alpha_2_`pct'_`type'' `=sc_alpha_3_`pct'_`type'' `=sc_alpha_4_`pct'_`type'' `=sc_alpha_5_`pct'_`type''" _newline
		di in red "avg alpha: `=sc_avgalpha_`pct'_`type''" _newline
		di in red "CI (`=sc_alphaCI_left';`=sc_alphaCI'): (`=sc_cilb_`pct'_`type''; `=sc_ciub_`pct'_`type'')" _newline 
		di in red "++++++++++++++++++++++++++++++++++++"

	}
}



***

