
*** 3. Prepare Pareto Distribution ***

use "${outpath}soep_pretest_1.dta", clear

* loop over all imputed net wealth variables

forval imp=1(1)5 {

	* generate log net wealth
	gen ln_nw_`imp'_ = ln(_`imp'_nw)

	****************************************************************************
	*		
	*		Pretest (_pt)
	*		
	****************************************************************************

	sort D_pt _`imp'_nw
	qui sum W_pt if D_pt==1
	scalar sc_N_`imp'_pt_ = r(sum)
	gen F_pt_`imp'_ = sum(W_pt)/sc_N_`imp'_pt_ if D_pt==1
	gen P_pt_`imp'_ = 1 - F_pt_`imp'_ if D_pt==1
	gen lnP_pt_`imp'_ = ln(P_pt_`imp'_) if D_pt==1


	****************************************************************************
	*		
	*		SOEP (_sp)
	*		
	****************************************************************************

	sort D_pt _`imp'_nw
	qui sum W_sp if D_pt==0
	scalar sc_N_`imp'_sp_ = r(sum)
	gen F_sp_`imp'_ = sum(W_sp)/sc_N_`imp'_sp_ if D_pt==0
	gen P_sp_`imp'_ = 1 - F_sp_`imp'_ if D_pt==0
	gen lnP_sp_`imp'_ = ln(P_sp_`imp'_) if D_pt==0

}

* check all generated variables
foreach data in sp pt {
	di in red _newline "+++++ `data' +++++"
	sum ln_nw_*_
	sum F_`data'_*_
	sum lnP_`data'_*_
	sum P_`data'_*_
}

* save dataset
save "${outpath}soep_pretest_2.dta", replace


********************************************************************************
*		
*		Generate MI IMPUTED dataset
*		
********************************************************************************
/*
NOTE: Another version of the dataset is generated in order to use stata's 
capabilities of dealing with imputed dataset. The second version of the 
dataset is saved as "soep_pretest_2_MI.dta". 
*/


//use "${outpath}soep_pretest_1.dta", clear

foreach type in pt sp {
	forval imp=1(1)5 {

		/* 
		NOTE: the variables with _#_ in the name (at end or start) seems to be 
		protected by stata when converting into mi dataset. Therefore, the last 
		underscore "_" is removed on the generated variables, so that it can be 
		later converted into a mi passive variable.
		*/
		
		rename F_`type'_`imp'_ F_`type'_`imp'
		drop P_`type'_`imp'_ lnP_`type'_`imp'_

		
	}
}

***

// ln_nw_#_ also must be dropped (or renamed) in order to convert into mi dataset.
drop ln_nw_*_

// _mi_miss seems to be necessary to unset MI. It indicates if obs is missing
// here: if imputed variable are all equal --> not missing.
gen _mi_miss = 1
replace _mi_miss = 0 if _1_nw == _2_nw & _1_nw == _3_nw & _1_nw == _4_nw & _1_nw == _5_nw 

// generate "raw" nw, that is, where not missing. 
gen nw = .
replace nw = _1_nw if _mi_miss == 0

mi unset 		// dataset was previously defined as mi dataset. 
drop mi_miss
rename (_1_nw _2_nw _3_nw _4_nw _5_nw) (nw1 nw2 nw3 nw4 nw5)	
// renaming seems to be necesssary because "mi import"
// tries to redefine _1_nw, _2_nw... variables

// recreate dataset indicating which var are imputed. 
mi import wide, imputed(nw=nw1 nw2 nw3 nw4 nw5) drop clear

// not strictly necessary, but "safer" 
mi register regular schicht 

********************************************************************************	
*
*		MI IMPUTE set
*
********************************************************************************

mi passive: gen ln_nw = ln(nw) 

********************************************************************************	
*		Pretest (_pt)
********************************************************************************

gen F_pt = .
replace F_pt = F_pt_1 if _mi_miss == 0
mi register passive F_pt

forval imp=1(1)5 {
	replace _`imp'_F_pt = F_pt_`imp'
}
mi passive: gen P_pt = 1 - F_pt
mi passive: gen lnP_pt = ln(P_pt)


********************************************************************************	
*		SOEP (_sp)
********************************************************************************

gen F_sp = .
replace F_sp = F_sp_1 if _mi_miss == 0
mi register passive F_sp

forval imp=1(1)5 {
	replace _`imp'_F_sp = F_sp_`imp'
}
mi passive: gen P_sp = 1 - F_sp
mi passive: gen lnP_sp = ln(P_sp)


local varlist W lnP
foreach var in `varlist' {
	// generate unique Weight and lnP variable for both sp and pt. 
	cap gen `var' = `var'_sp
	replace `var' = `var'_pt if missing(`var')
}

*** save dataset
save "${outpath}soep_pretest_2_MI.dta", replace

