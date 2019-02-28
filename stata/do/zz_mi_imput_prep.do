// this script redefines the pretest data into a "mi" dataset, 
// where stata can take into account imputed varibles. 

use "${pretest}pretest_topw.dta", clear
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

// summary for every imputation
mi xeq: summarize nw

// test estimation taking imputation into account
mi estimate, dots: reg nw schicht

// Check within / Between Variance
mi estimate, vartable nocitable

// generate another variable that is defined on a imputed variable 
// (stata autoamtically generates for every _imp_ variable.) 
mi passive: generate lnw = ln(nw)
