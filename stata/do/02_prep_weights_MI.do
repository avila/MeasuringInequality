
*** 2. Weights ***

use "${outpath}soep_pretest_0_MI.dta", clear


********************************************************************************
*		
*		Weights: SOEP (_sp)
*		
********************************************************************************

ren w1110512 W_sp

* check SOEP weights
sum gebjahr [fw = round(W_sp)]


********************************************************************************
*		
*		Reweighting: Pretest (_pt)
*		
********************************************************************************

gen W_pt = .
scalar sc_strata = 3

*** Re-weighting according to sampling probabilities
* Stratum 1
replace W_pt = (7/1)/sc_strata if D_pretest==1 & schicht==1
* Stratum 2
replace W_pt = (7/2)/sc_strata if D_pretest==1 & schicht==2
* Stratum 3
replace W_pt = (7/4)/sc_strata if D_pretest==1 & schicht==3

/* 	Note that it turns out the drawn pretest individuals have different response 
	rate that the sampling probabilities. Therefore, we apply the inverse of the 
	sample share for each stratum. */

ren W_pt W_pt_old

gen W_pt = .

* actual shares of pretest individuals in drawn sample
qui sum D_pretest if D_pretest==1
scalar sc_N_pretest = r(N)
di in red "total pretest n = `=sc_N_pretest'" 

forval i=1(1)3 {
	qui sum D_pretest if schicht==`i'
	scalar sc_share_strat`i' = r(N)/sc_N_pretest
	di in red "share stratum `i' = `=sc_share_strat`i''" 
}

*** Alternative: Re-weighting according to their response rates
* Stratum 1
replace W_pt = (1/`=sc_share_strat1')	if D_pretest==1 & schicht==1
* Stratum 2
replace W_pt = (1/`=sc_share_strat2')	if D_pretest==1 & schicht==2
* Stratum 3
replace W_pt = (1/`=sc_share_strat3')	if D_pretest==1 & schicht==3

replace W_pt = W_pt / sc_strata if D_pretest==1

* from sample to 1% population
qui sum _1_nw if D_pretest==1
replace W_pt = W_pt * (660000/r(N))

* check frequency weights
sum _1_nw if D_pretest==0 [fw = round(W_sp)]
sum _1_nw if D_pretest==1 [fw = round(W_pt)]


********************************************************************************
*		
*		Weighting together: SOEP + Pretest (_sppt)
*		
********************************************************************************

/* Note: Because the weights provided in the SOEP are adjusted only for the SOEP,
		one cannot simply add the pretest without considering its relation to the 
		population. Therefore, we scale down the SOEP-weights by 1% and fill it
		with the pretest sample. Then we add the pretest weights to the SOEP-
		weights. SOEP+Pretest (_sppt) represent the population of Germany. 
*/

* get the population of SOEP
qui sum _1_nw if D_pretest==0 [fw=round(W_sp)]
scalar sc_N_sp_pop = r(N)

* get the population of Pretest
qui sum _1_nw if D_pretest==1 [fw=round(W_pt)]
scalar sc_N_pt_pop = r(N)


save "${outpath}soep_pretest_1_MI.dta", replace

***
