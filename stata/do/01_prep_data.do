
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

* net wealth in thousand / mio
forval i=1(1)5 {
	gen _`i'_nw_thous	= _`i'_nw /    1000
	gen _`i'_nw_mio		= _`i'_nw / 1000000
}


save "${outpath}soep_pretest_0.dta", replace

***
