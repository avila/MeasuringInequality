
*** 2. Weights ***

use "${outpath}soep_pretest_0.dta", clear

********************************************************************************
*		
*		Weights: SOEP (_sp)
*		
********************************************************************************

* check plausibility of weights
forval imp=1(1)5{
	sum _`imp'_nw [fw=round(W_sp,1)]
}

********************************************************************************
*		
*		Reweighting: Pretest (_pt)
*		
********************************************************************************

gen W_pt = .
scalar sc_strata = 3

/* 	Note that it turns out the drawn pretest HHs have different response rates 
	than the sampling probabilities. Therefore, we apply the inverse of the 
	sample share for each stratum. */
	
* actual shares of pretest individuals in drawn sample
qui sum D_pt if D_pt==1
scalar sc_N_pt = r(N)
di in red "pretest n = `=sc_N_pt'" 

forval i=1(1)3 {
	qui sum D_pt if schicht==`i'
	scalar sc_share_strat`i' = r(N)/sc_N_pt
	di in red "share stratum `i' = `=sc_share_strat`i''" 
}

*** Alternative: Re-weighting according to their response rates
* Stratum 1
replace W_pt = (1/`=sc_share_strat1') if D_pt==1 & schicht==1
* Stratum 2
replace W_pt = (1/`=sc_share_strat2') if D_pt==1 & schicht==2
* Stratum 3
replace W_pt = (1/`=sc_share_strat3') if D_pt==1 & schicht==3

replace W_pt = W_pt / sc_strata if D_pt==1

* from sample to 1% HH-population (2017: about 41,304,000 HHs * 0.01 = 413,000)
* (vgl. https://de.statista.com/statistik/daten/studie/156950/umfrage/anzahl-der-privathaushalte-in-deutschland-seit-1991/)
qui sum _1_nw if D_pt==1
replace W_pt = W_pt * (413000/r(N))

* check frequency weights
sum _1_nw if D_pt==0 [fw = round(W_sp)]
sum _1_nw if D_pt==1 [fw = round(W_pt)]


save "${outpath}soep_pretest_1.dta", replace


***


