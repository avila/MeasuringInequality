
*** 2. Weights ***

use "$out_path/soep_pretest_0.dta", clear

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

/*  We calculate the re-weights of the Pretest observations by applying the 
	inverse of the sample share for each stratum */
	
qui sum D_pretest if D_pretest==1
scalar sc_N_pretest = r(N)
di in red "total pretest n = `=sc_N_pretest'" 

forval i=1(1)3 {
	qui sum D_pretest if schicht==`i'
	replace W_pt = (sc_N_pretest/r(N))/sc_strata if schicht==`i'
}

* extrapolation from sample to 1% population
qui sum D_pretest if D_pretest==1
gen W_pt_old = W_pt * (660000/r(N))

* check frequency weights
sum nwsoep_t if D_pretest==0 [fw = round(W_sp)]
sum nwpt_t if D_pretest==1 [fw = round(W_pt_old)]


/*  Seb_Note I: there exist a contradiction in the weighting schemes. On the one 
	hand we use the frequency weights for the SOEP provided by the dataset 
	bcpequiv.dta and just keep the richest person per household. When we 
	extrapolate the SOEP-observations we end up by around 19 mio. people. 
	On the other hand we extrapolate the re-weighted Pretest-oberservations 
	up to 600.000 - the Top 1 % OF THE WHOLE POPULATION. So if we compare the 
	both weighted data, the results aren't consistent. */

********************************************************************************
*		
*		consistent extrapolation: Pretest
*		
********************************************************************************

/*  Seb_Note II: We don't extrapolate to the whole population, but we extrapolate 
	to the richest person per household in the population. We assume that the 
	share of richest person per household in the SOEP (53,47 % unweighted - 
	59,23 % weighted) is the same than in Pretest. We compute this share to the 
	total population 660.000 (Top 1 %) for our new Pretest weights.
	
	Seb_Note III: We know that die Pretest data include the personal net wealth 
	at household level (per household, one observation). From 
	https://de.statista.com/statistik/daten/studie/156950/umfrage/anzahl-der-privathaushalte-in-deutschland-seit-1991/
	we see that in 2017 it exists about 41,3 Mio. households in Germany. So it's 
	easy to compute the total number of households in the Top 1% (around 
	413.000). Set this value for the extrapolation of the Pretest data.
*/

* use the unweighted share 53,47 %:

qui sum D_pretest if D_pretest==1
gen W_pt_unw = W_pt * ((660000*0.5347)/r(N))

* use the weighted share 59,23 %:

qui sum D_pretest if D_pretest==1
gen W_pt_w = W_pt * ((660000*0.5923)/r(N))

* use the value from offical household statistics from Destatis:

qui sum D_pretest if D_pretest==1
gen W_pt_dest = W_pt * (413000/r(N))

* check frequency weights
sum nwsoep_t if D_pretest==0 [fw = round(W_sp)]
sum nwpt_t if D_pretest==1 [fw = round(W_pt_old)]
sum nwpt_t if D_pretest==1 [fw = round(W_pt_unw)]
sum nwpt_t if D_pretest==1 [fw = round(W_pt_w)]
sum nwpt_t if D_pretest==1 [fw = round(W_pt_dest)]

save "$out_path/soep_pretest_1.dta", replace


***


