//    Estimate on completed data using logit
//clear all
//webuse mheart1s20
//mi describe
//mi estimate, dots: logit attack smokes age bmi hsgrad female

use "${pretest}pretest_topw.dta", clear
mi query
mi query

gen _mi_miss = 1
replace _mi_miss = 0 if _1_nw == _2_nw & _1_nw == _3_nw & _1_nw == _4_nw & _1_nw == _5_nw 
gen nw = .
replace nw = _1_nw if _mi_miss == 0

mi unset 
drop mi_miss
rename _1_nw nw1
rename _2_nw nw2
rename _3_nw nw3
rename _4_nw nw4
rename _5_nw nw5

mi import wide, imputed(nw=nw1 nw2 nw3 nw4 nw5) drop clear
mi register regular schicht
mi desc

mi xeq: summarize nw

mi estimate, dots: reg nw schicht
