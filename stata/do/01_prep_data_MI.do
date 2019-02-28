
*** 1. Data preparation ***

* load soep wealth
use "${soep}pwealth.dta", clear
keep persnr syear w0111a  w0111b  w0111c  w0111d  w0111e w02220  syear 

* rename according to pretest
ren (w0111a  w0111b  w0111c  w0111d  w0111e w02220) (_1_nw _2_nw _3_nw _4_nw _5_nw imp_flag)

* keep most current syear
drop if syear < 2012

* add cross-sectional weights: w1110512 of wave bc (year 2012)
merge 1:1 persnr using "${soep}bcpequiv.dta", keepusing(w1110512)
keep if _merge == 3
drop _merge

* check realized hh interviews
merge 1:1 persnr using "${soep}ppfad.dta", keepusing(bcnetto sex gebjahr)
keep if _merge == 3
drop _merge


* append pretest dataset
append using "${pretest}pretest_topw.dta"

* define syear for pretest
replace syear = 2017 if schicht!=.

* now we have a dataset of all individ. from the pretest and of all individ. of 
* the most current syear when the wealth module was asked (=2012). 
* Note: no frequency weights applied


* generate soep-pretest dummy
gen D_pretest = 0
replace D_pretest = 1 if schicht!=.
label define pretestlabel 0 "SOEP 2012" 1 "PRETEST 2017"
label values D_pretest  pretestlabel
label variable D_pretest "dummy SOEP or pretest"


mi query		// this dataset is already defined as a "mi dataset", but it seems 
				// it is not properly done (its missing the main nw variable, 
				// which seems to be necessary in order to use the "mi commands"

// _mi_miss seems to be necessary to unset MI. It indicates if obs is missing
// here: if imputed variable are all equal --> not missing.
gen _mi_miss = 1
replace _mi_miss = 0 if _1_nw == _2_nw & _1_nw == _3_nw & _1_nw == _4_nw & _1_nw == _5_nw 

// generate "raw" nw, that is, where not missing (not imputed) 
gen nw = .
replace nw = _1_nw if _mi_miss == 0

mi unset 
drop mi_miss
rename (_1_nw _2_nw _3_nw _4_nw _5_nw) (nw1 nw2 nw3 nw4 nw5)	
// renaming seems to be necesssary because "mi import"
// tries to redefine _1_nw, _2_nw... variables

// recreate dataset indicating which var are imputed. 
mi import wide, imputed(nw=nw1 nw2 nw3 nw4 nw5) drop clear
mi register regular schicht // not strictly necessary, but "safer" 
mi desc

// passive -> generate variables for m imputed columns based on imputed variable.
mi passive: gen nw_thous 	= nw/1e3
mi passive: gen nw_mio 		= nw/1e6

save "${outpath}soep_pretest_0_MI.dta", replace
***
