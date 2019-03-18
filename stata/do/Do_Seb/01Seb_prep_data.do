
*** 1. Data preparation ***

* load soep wealth data: pwealth - keep the net wealth variable and identifyers 
use "$data_path/pwealth.dta", clear
keep hhnrakt persnr syear w0111a w0111b w0111c w0111d w0111e w02220
tab syear 

* rename according to pretest
rename (w0111a  w0111b  w0111c  w0111d  w0111e w02220) (_1_nw _2_nw _3_nw _4_nw _5_nw imp_flag)

* keep most current syear
drop if syear < 2012
tab imp_flag

* If there is more than just one person in a household, just keep the richest one

egen nwmean_soep=rowtotal(_1_nw _2_nw _3_nw _4_nw _5_nw)
replace nwmean_soep=nwmean_soep/5
gsort hhnrakt - nwmean_soep
by hhnrakt, sort: gen hh_d=_n
keep if hh_d == 1
drop hh_d
tab imp_flag

* add cross-sectional weights: w1110512 of wave bc (year 2012)
merge 1:1 persnr using "$data_path/bcpequiv.dta", keepusing(w1110512)
keep if _merge == 3
drop _merge

* check realized hh interviews
merge 1:1 persnr using "$data_path/ppfad.dta", keepusing(bcnetto sex gebjahr)
keep if _merge == 3
drop _merge

* append pretest dataset
append using "$data_path/pretest_topw.dta"

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

* average of imputed values from Pretest and overall net wealth in thousand / mio

egen nwmean_pt=rowtotal(_1_nw _2_nw _3_nw _4_nw _5_nw) if schicht!=.
replace nwmean_pt=nwmean_pt/5

gen nwsoep_t = nwmean_soep / 1000
gen nwsoep_mio = nwmean_soep / 1000000
gen nwpt_t = nwmean_pt / 1000
gen nwpt_mio = nwmean_pt / 1000000

save "$out_path/soep_pretest_0.dta", replace

***
