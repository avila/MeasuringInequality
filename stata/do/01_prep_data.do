
*** 1. Data preparation ***

* load wealth data on HH-level
use "${soep}hwealth.dta", clear

* HH net overall wealth
keep hhnrakt syear w011ha w011hb w011hc w011hd w011he w022h0 syear 

* rename according to pretest
ren (w011ha w011hb w011hc w011hd w011he w022h0) (_1_nw _2_nw _3_nw _4_nw _5_nw imp_flag)

* keep most current syear
drop if syear < 2012

* merge weights: HH-weights "Hochrechnungsfaktoren 2012" = bchhrf (2012, wave bc)
merge 1:1 hhnrakt using "${soep}hhrf.dta", keepusing(bchhrf)
keep if _merge == 3
drop _merge

* rename weight (naming convention: SOEP = _sp)
ren bchhrf W_sp

* check plausibility of weights
sum _1_nw [fw=round(W_sp,1)]
/*	-> 36,201,747 HHs in Germany
	-> 39,707,000 HHs in Germany according to Statista
 (vgl. https://de.statista.com/statistik/daten/studie/156950/umfrage/anzahl-der-privathaushalte-in-deutschland-seit-1991/ )
*/

* append pretest dataset
* NOTE: Pretest is on individ-level, but net overall wealth was asked on HH-level
append using "${pretest}pretest_topw.dta"

* define syear for pretest
replace syear = 2017 if schicht!=.

* now we have a dataset of all HHs from the pretest and of all HHs of the most 
* current syear when the wealth module was asked (=2012). 

* generate soep-pretest dummy
gen D_pt = 0
replace D_pt = 1 if schicht!=.
label define pretestlabel 0 "SOEP 2012" 1 "PRETEST 2017"
label values D_pt  pretestlabel
label variable D_pt "Dummy SOEP or Pretest"

* net wealth in thousand / mio
forval i=1(1)5 {
	gen _`i'_nw_thous	= _`i'_nw /    1000
	gen _`i'_nw_mio		= _`i'_nw / 1000000
}

save "${outpath}soep_pretest_0.dta", replace


***
