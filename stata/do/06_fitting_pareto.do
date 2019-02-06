
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
	3.	Test equality of Pareto's Alpha for SOEP vs. Pretest
			3.1. ttest
			3.2. Hausman (suest)
				a) soep vs pretest
				b) within soep/pretest across percentiles
			3.3. chow test
	4.	calculating example values (Top 5%, 1%, 0.1%)
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


	* calculate absolut threshold value out of local pctile
	qui sum _`imp'_nw if D_pretest==0, d
	
	foreach pc of local pctile {
		scalar sc_absthres_`imp'_`pc' 		= r(`pc')
		scalar sc_absthres_`imp'_`pc'_round = round(r(`pc'),.01)

		if "$show_all" == "TRUE" {
			di "threshold `pc': `=sc_absthres_`imp'_`pc'_round'"
		}
	}

	* generate percentiles out of local pctile
	qui sum ln_nw_`imp'_ if D_pretest==0, d
	
	foreach pc of local pctile {
		scalar thres_`imp'_`pc' 		= r(`pc')
		scalar thres_`imp'_`pc'_round 	= round(r(`pc'),.01)

		if "$show_all" == "TRUE" {
			di "threshold `pc': `=thres_`imp'_`pc'_round'"
		}
	}

	foreach type in sp pt sppt {

		foreach pct of local pctile {
	
			if "`type'" == "sp" {
				local D_pretest 0
			}
			else {
				local D_pretest 1
			}
			
				qui reg lnP_`type'_`imp'_ ln_nw_`imp'_ if (ln_nw_`imp'_ >= thres_`imp'_`pct' & D_pretest==`D_pretest')
					estimates title: reg lnP_`type'_`imp'_ ~ ln_nw_`imp'_ (thres: `pct')
					est store reg_`imp'_`pct'_`type'
				
					scalar sc_alpha_`imp'_`pct'_`type' = _b[ln_nw]
					scalar sc_sd_`imp'_`pct'_`type' = _se[ln_nw]
					scalar sc_N_`imp'_`pct'_`type' = e(N)
					scalar sc_r2_`imp'_`pct'_`type' = e(r2)
					scalar sc_cons_`imp'_`pct'_`type' = _b[_cons]

				
				if "$show_all" == "TRUE" {
					di "++++++++++++++"
					di "alpha: 	sc_alpha_`imp'_`pct'_`type' = `=sc_alpha_`imp'_`pct'_`type''"
					di "sd:    	sc_sd_`imp'_`pct'_`type' = `=sc_sd_`imp'_`pct'_`type''"					
					di "N: 		sc_N_`imp'_`pct'_`type' = `=sc_N_`imp'_`pct'_`type''"
					di "r2:		sc_r2_`imp'_`pct'_`type' = `=sc_r2_`imp'_`pct'_`type''"
				}
		}
	}
}


********************************************************************************
*		
*		2.	Calculating CI of alpha according to Rubin (1987)
*		
********************************************************************************


foreach type in sp pt sppt {

	foreach pct of local pctile {

	* 1. within variance
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

********************************************************************************
*		
*		3. 	Test equality of Pareto's Alpha for SOEP vs. Pretest
*			3.1. ttest, 3.2. Hausman (suest), 3.3. chow test
*		
********************************************************************************

/* 
Note: Below, we test the equality of pareto's alpha of SOEP vs Pretest by 
applying Stata's suest (seemingly unrelated regressions). 

Results: 
1. ttest: two-sided / right-sided: we can reject the null, there is a difference 
		between both alhpas; left-sided: there is no difference (?!)
2. suest: across all imputations and for all pctile thresholds we cannot reject 
the null that both alphas are not equal.
3. chow test: alphas are not equal.
*/

********************************************************************************
*	3.1. ttest 
********************************************************************************

foreach pct of local pctile {
	forval imp=1(1)`=m' {
		di _newline in red "+++++ ttest: ln_nw_`imp'_ SOEP = ln_nw_`imp'_ Pretest +++++" 
		di in red "+++++ threshold: `pct', imputation: `imp' +++++"
		ttest ln_nw_`imp'_ if ln_nw_`imp'_ >= thres_`imp'_`pct', by(D_pretest)
	}
}

********************************************************************************
*	3.2. Hausman-test suest (seemingly unrelated regressions)
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
	foreach type in sp pt sppt {
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
* 	3.3. Chow Test
********************************************************************************
/*
 vgl. https://www.stata.com/support/faqs/statistics/computing-chow-statistic/
 vgl. https://www.iuj.ac.jp/faculty/kucc625/method/panel/chow_test.pdf 

 H0: alpha_SOEP = alpha_Pretest (within sppt dataset)

 Note: We can only run the chow test when both subgroups (SOEP, Pretest) arepart 
 of the same n (distinguishing via D_pretest=0,1). Therefore, we can test: sppt 
 and not sp vs. pt.
	- group 1: SOEP
	- group 2: Pretest
	- both: SOEP+Pretest
*/
foreach pct of local pctile {

	forval imp=1(1)5 {
		
		* pooled regression
		qui reg lnP_sppt_`imp'_ ln_nw_`imp'_ if (ln_nw_`imp'_ >= thres_`imp'_`pct')
		scalar sc_rss_sppt_`imp'_pooled = e(rss)

		* regression group 1
		qui reg lnP_sppt_`imp'_ ln_nw_`imp'_ if (ln_nw_`imp'_ >= thres_`imp'_`pct' & D_pretest==0)
		scalar sc_N_sppt_`imp'_grp1 = e(N)
		scalar sc_rss_sppt_`imp'_grp1 = e(rss)

		* regression group 2
		qui reg lnP_sppt_`imp'_ ln_nw_`imp'_ if (ln_nw_`imp'_ >= thres_`imp'_`pct' & D_pretest==1)
		scalar sc_N_sppt_`imp'_grp2 = e(N)
		scalar sc_rss_sppt_`imp'_grp2 = e(rss)


		* 2 restriction: j=2, df: k=2
		scalar j=2
		scalar k=2
		scalar Ndf=sc_N_sppt_`imp'_grp1 + sc_N_sppt_`imp'_grp2 - 2*k

		* Chow F-statistic
		scalar sc_chow_F = ((sc_rss_sppt_`imp'_pooled - sc_rss_sppt_`imp'_grp1 - sc_rss_sppt_`imp'_grp2)/j) / ((sc_rss_sppt_`imp'_grp1 + sc_rss_sppt_`imp'_grp2)/(sc_N_sppt_`imp'_grp1 + sc_N_sppt_`imp'_grp2 - 2*k))

		* Chow H0 p-value
		scalar sc_chow_pval = Ftail(k,Ndf,sc_chow_F)

		di in red "++++++++++++++++++++++++++++ (imp.: `imp', pct.: `pct') +++"
		di in red "const. of SOEP = const. of Pretest and alpha_SOEP = alpha_Pretest"
		di in red "chow F-statistic: `=sc_chow_F', p-value: `=sc_chow_pval'"
		if `=sc_chow_pval' <= 0.005 {
			di in red " -> We can reject H0: coefficients are not equal!"
		}
		else {
			di in red "-> We cannot reject H0: coefficients are equal!"
		}

	}
}


* display all produced estimates, scalars
estimates dir
scalar dir


********************************************************************************
* Save scalar results to tables
********************************************************************************

do "${do}06a_sc_to_table.do"




***

