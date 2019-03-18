

*** 9. predict top percentiles ***


* NOTE: In this file we impute the top net wealth (above the thresholds: 
*		p95 and p99) of the SOEP using the fitted Pareto's alpha from the Pretest.
*		(see section 07) We do this for each implicate, so we get 30 new 
*		net wealth variables (5 implicates x 2 Thresholds x 2 Confidence 
*		interval values). For this calculation we use the formula of the 
*		cumulative distribution function:
*		
*		F = 1-(nw_thres/nw)^alpha 	->	nw_hat = ((1-F)^(-1/alpha))*nw_thres
*
*		Further we calculate two godness of fit measures: root-mean-square-error 
*		(RMSE) and relative-root-mean-square-error (RRMSE).
*
*		On the next step we estimate the percentiles (95, 99 and 99.9), total 
*		wealth (of the Top 5 %, Top 1 % and the Top 0.1 %) and the corresponding 
*		shares from the new predicted variables and from the original SOEP data.
*
*		At the end we calculate the mean over all five implicates of each value 
*		from 9.2. After all we get 9 scalars for the original SOEP and 30 scalars
*		for the predicted data. (It doesn't make sense to predict the 95. 
*		percentile and Top 5% characteristics for our predicted data based on a 
*		estimated alpha with a threshold p99. So we omitting the calculation in 
*		this case.)
*
*
********************************************************************************
*
*	9.1 Impute top nw of SOEP with Pretest alphas and goodness of fit measures
*	9.2 Predict percentiles, total wealth and shares of the predicted top wealth
*	9.3 Calculate the mean of the scalars over all five implicates
* 
********************************************************************************

use "${outpath}soep_pretest_2.dta", clear

scalar m=5

** 9.1 Impute top nw of SOEP with Pretest alphas and goodness of fit measures

forvalue imp=1(1)`=m' {

	foreach pct in p95 p99 {
	
		foreach citype in cilo cihi {
	
			* display alphas
			di in red "sc_`citype'_`pct'_pt = `=sc_`citype'_`pct'_pt'"
	
			* nw_hat (with Pretest Alpha)
			gen nw_hat_`imp'_`pct'_`citype' = _`imp'_nw if D_pt == 0 & _`imp'_nw <= sc_thres_`imp'_`pct'
			gen D_nw_hat_`imp'_`pct'_`citype' = 1 if D_pt == 0
			replace D_nw_hat_`imp'_`pct'_`citype' = 0 if D_pt == 0 & _`imp'_nw <= sc_thres_`imp'_`pct'	
			replace nw_hat_`imp'_`pct'_`citype' = ((1-F_sp_`imp'_)^(-1/sc_`citype'_`pct'_pt))*sc_thres_`imp'_`pct' if D_pt == 0 & _`imp'_nw > sc_thres_`imp'_`pct'

			* nw_hat (with SOEP Alpha)
			gen nw_hat2_`imp'_`pct'_`citype' = _`imp'_nw if D_pt == 0 & _`imp'_nw <= sc_thres_`imp'_`pct'
			gen D_nw_hat2_`imp'_`pct'_`citype' = 1 if D_pt == 0
			replace D_nw_hat2_`imp'_`pct'_`citype' = 0 if D_pt == 0 & _`imp'_nw <= sc_thres_`imp'_`pct'	
			replace nw_hat2_`imp'_`pct'_`citype' = ((1-F_sp_`imp'_)^(-1/sc_`citype'_`pct'_sp))*sc_thres_`imp'_`pct' if D_pt == 0 & _`imp'_nw > sc_thres_`imp'_`pct'
			
			* RMSE
			gen trash = (_`imp'_nw - nw_hat_`imp'_`pct'_`citype')^2  if D_nw_hat_`imp'_`pct'_`citype' == 1
			qui sum trash [fw=round(W_sp)] if D_nw_hat_`imp'_`pct'_`citype' == 1
			scalar sc_`citype'rmse_`imp'_`pct' = sqrt((1/r(N))*r(sum))
			di in red "sc_`citype'rmse_`imp'_`pct' = `=sc_`citype'rmse_`imp'_`pct''"
			drop trash
			
			* RRMSE
			qui sum _`imp'_nw  [fw=round(W_sp)]  if D_nw_hat_`imp'_`pct'_`citype' == 1
			scalar sc_`citype'rrmse_`imp'_`pct' = (sc_`citype'rmse_`imp'_`pct' / r(sum))*100
			di in red "sc_`citype'rrmse_`imp'_`pct' = `=sc_`citype'rrmse_`imp'_`pct''"
			
		}
		
	}

** 9.2 Predict percentiles, total wealth and shares of the predicted top wealth

	* Values from the ORIGINAL SOEP - percentiles (pct):
	_pctile _`imp'_nw [fw = round(W_sp)] if D_pt == 0, percentiles(95 99 99.9)
	scalar sc_pcttop50_sp_`imp' = r(r1)
	scalar sc_pcttop10_sp_`imp' = r(r2)
	scalar sc_pcttop01_sp_`imp' = r(r3)

	* Values from the ORIGINAL SOEP - total wealth (tw) & shares (sh):
	sum _`imp'_nw [fw = round(W_sp)] if D_pt == 0
	scalar sc_tw_sp_`imp' = r(sum)
	
	foreach top in top50 top10 top01 {
	
		sum _`imp'_nw [fw = round(W_sp)] if D_pt == 0 & (_`imp'_nw > sc_pct`top'_sp_`imp')
		scalar sc_tw`top'_sp_`imp' = r(sum)
		scalar sc_sh`top'_sp_`imp' = sc_tw`top'_sp_`imp'/sc_tw_sp_`imp'
		
	}

	* Estimate the percentiles, total wealth and shares of the predicted top wealth data:

	* Use alpha with threshold p95 - percentiles (pct):
	foreach citype in cilo cihi {
		
		_pctile nw_hat_`imp'_p95_`citype' [fw = round(W_sp)] if D_pt == 0, percentiles(95 99 99.9)
		scalar sc_pcttop50_`imp'_p95_`citype' = r(r1)
		scalar sc_pcttop10_`imp'_p95_`citype' = r(r2)
		scalar sc_pcttop01_`imp'_p95_`citype' = r(r3)

		
		* Use alpha with threshold p95 - total wealth (tw) & shares (sh):
		sum nw_hat_`imp'_p95_`citype' [fw = round(W_sp)] if  D_pt == 0
		scalar sc_tw_`imp'_p95_`citype' = r(sum)
		
		foreach top in top50 top10 top01 {
		
			sum nw_hat_`imp'_p95_`citype' [fw = round(W_sp)] if D_pt == 0 & (nw_hat_`imp'_p95_`citype' > sc_pct`top'_`imp'_p95_`citype')
			scalar sc_tw`top'_`imp'_p95_`citype' = r(sum)
			scalar sc_sh`top'_`imp'_p95_`citype' = sc_tw`top'_`imp'_p95_`citype'/sc_tw_`imp'_p95_`citype'
		}
		
	}

	* Use alpha with threshold p99 - percentiles (pct):
	foreach citype in cilo cihi {
	
		_pctile nw_hat_`imp'_p99_`citype' [fw = round(W_sp)] if D_pt == 0, percentiles(99 99.9)
		scalar sc_pcttop10_`imp'_p99_`citype' = r(r1)
		scalar sc_pcttop01_`imp'_p99_`citype' = r(r2)
	
		* Use alpha with threshold p99 - total wealth (tw) & shares (sh):
		sum nw_hat_`imp'_p99_`citype' [fw = round(W_sp)] if  D_pt == 0
		scalar sc_tw_`imp'_p99_`citype' = r(sum)
		
		foreach top in top10 top01 {
	
			sum nw_hat_`imp'_p99_`citype' [fw = round(W_sp)] if D_pt == 0 & (nw_hat_`imp'_p99_`citype' > sc_pct`top'_`imp'_p99_`citype')
			scalar sc_tw`top'_`imp'_p99_`citype' = r(sum)
			scalar sc_sh`top'_`imp'_p99_`citype' = sc_tw`top'_`imp'_p99_`citype'/sc_tw_`imp'_p99_`citype'
		}
	
	}

}

** check nw_hat, example comparison
sum nw_hat_1_p95_cihi nw_hat_1_p95_cilo _1_nw if D_pt == 0

** 9.3 Calculate the mean of the scalars over all five implicates

* form the average of SOEP scalars:
foreach top in top50 top10 top01 {

	scalar sc_pct`top'_sp = (sc_pct`top'_sp_1 + sc_pct`top'_sp_2 + sc_pct`top'_sp_3 + sc_pct`top'_sp_4 + sc_pct`top'_sp_5)/m 
	scalar sc_tw`top'_sp = (sc_tw`top'_sp_1 + sc_tw`top'_sp_2 + sc_tw`top'_sp_3 + sc_tw`top'_sp_4 + sc_tw`top'_sp_5)/m 
	scalar sc_sh`top'_sp = (sc_sh`top'_sp_1 + sc_sh`top'_sp_2 + sc_sh`top'_sp_3 + sc_sh`top'_sp_4 + sc_sh`top'_sp_5)/m
	
	* form the average of predicted scalars with Pareto's alpha - threshold p95:
	foreach citype in cilo cihi {
	
		** p95 **
		* top percentiles (pct)
		scalar sc_pct`top'_p95_`citype'	= (sc_pct`top'_1_p95_`citype' + sc_pct`top'_2_p95_`citype' + sc_pct`top'_3_p95_`citype' + sc_pct`top'_4_p95_`citype' + sc_pct`top'_5_p95_`citype')/m 
		scalar sc_pct`top'_p95_`citype'	= sc_pct`top'_p95_`citype' / 1000000
		di in red "sc_pct`top'_p95_`citype' = `=sc_pct`top'_p95_`citype''"
		
		* total wealth (tw)
		scalar sc_tw`top'_p95_`citype'	= (sc_tw`top'_1_p95_`citype' + sc_tw`top'_2_p95_`citype' + sc_tw`top'_3_p95_`citype' + sc_tw`top'_4_p95_`citype' + sc_tw`top'_5_p95_`citype')/m 
		scalar sc_tw`top'_p95_`citype'	= sc_tw`top'_p95_`citype' / 1000000
		di in red "sc_tw`top'_p95_`citype' = `=sc_tw`top'_p95_`citype''"
		
		* shares (sh)
		scalar sc_sh`top'_p95_`citype'	= (sc_sh`top'_1_p95_`citype' + sc_sh`top'_2_p95_`citype' + sc_sh`top'_3_p95_`citype' + sc_sh`top'_4_p95_`citype' + sc_sh`top'_5_p95_`citype')/m 
		di in red "sc_sh`top'_p95_`citype' = `=sc_sh`top'_p95_`citype''"
		
	}

}

* form the average of predicted scalars with Pareto's alpha - threshold p99:

foreach top in top10 top01 {
	
	foreach citype in cilo cihi {
	
		** p99 **
		* top percentiles (pct)
		scalar sc_pct`top'_p99_`citype'	= (sc_pct`top'_1_p99_`citype' + sc_pct`top'_2_p99_`citype' + sc_pct`top'_3_p99_`citype' + sc_pct`top'_4_p99_`citype' + sc_pct`top'_5_p99_`citype')/m 
		scalar sc_pct`top'_p99_`citype' = round(sc_pct`top'_p99_`citype' / 1000000, .001)
		di in red "sc_pct`top'_p99_`citype' = `=sc_pct`top'_p99_`citype''"
		
		* total wealth (tw)
		scalar sc_tw`top'_p99_`citype'	= (sc_tw`top'_1_p99_`citype' + sc_tw`top'_2_p99_`citype' + sc_tw`top'_3_p99_`citype' + sc_tw`top'_4_p99_`citype' + sc_tw`top'_5_p99_`citype')/m 
		scalar sc_tw`top'_p99_`citype'	= round(sc_tw`top'_p99_`citype' / (10^15), .001)
		di in red "sc_tw`top'_p99_`citype' = `=sc_tw`top'_p99_`citype''"	
	
		* shares (sh)
		scalar sc_sh`top'_p99_`citype'	= (sc_sh`top'_1_p99_`citype' + sc_sh`top'_2_p99_`citype' + sc_sh`top'_3_p99_`citype' + sc_sh`top'_4_p99_`citype' + sc_sh`top'_5_p99_`citype')/m 
		di in red "sc_sh`top'_p99_`citype' = `=sc_sh`top'_p99_`citype''"
	
	}
	
}

save "${outpath}soep_pretest_3.dta", replace

***

