
*** 3. Prepare Pareto Distribution ***

use "${outpath}soep_pretest_1.dta", clear

* loop over all imputed net wealth variables

forval imp=1(1)5 {

	/* 
	NOTE: the variables with _#_ in the name (at end or start) seems to be 
	protected by stata when converting into mi dataset. Therefore, the last 
	underscore "_" is removed on the generated variables, so that it can be 
	later converted into a mi passive variable.
	*/

	* generate log net wealth
	gen ln_nw_`imp' = ln(_`imp'_nw)

	****************************************************************************
	*		
	*		Pretest (_pt)
	*		
	****************************************************************************

	sort D_pt _`imp'_nw
	qui sum W_pt if D_pt==1
	scalar sc_N_`imp'_pt_ = r(sum)
	gen F_pt_`imp' = sum(W_pt)/sc_N_`imp'_pt_ if D_pt==1

	****************************************************************************
	*		
	*		SOEP (_sp)
	*		
	****************************************************************************

	sort D_pt _`imp'_nw
	qui sum W_sp if D_pt==0
	scalar sc_N_`imp'_sp_ = r(sum)
	gen F_sp_`imp' = sum(W_sp)/sc_N_`imp'_sp_ if D_pt==0
}

***

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


*** save dataset
save "${outpath}soep_pretest_2_MI.dta", replace


********************************************************************************	
*
*		MI ESTIMATE (// this section should be transfered to a seperate file.)
*
********************************************************************************

// following: https://www.stata.com/support/faqs/statistics/combine-results-with-multiply-imputed-data/#suest


********************************************************************************
* define mysuest program
********************************************************************************

/* 
USAGE: mysuest "NameOfFirstReg" "FirstReg" "NameOfSecondReg" "SecondReg"
*/
cap program drop mysuest
program mysuest, eclass properties(mi)
        version 14.2
		args data1 model1 data2 model2

        qui `model1'
        estimates store `data1'
        qui `model2'
        estimates store `data2'
        suest `data1' `data2'
        estimates drop `data1' `data2'
        
        ereturn local title "Seemingly unrelated estimation"
end

********************************************************************************
* Test mi estimate
********************************************************************************

scalar sc_lb95 = 340000
scalar sc_lb99 = 880000

// "esampvaryok" necessary due to variation in observations across imputations.
mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= sc_lb95 & D_pt == 0) [iw=W]
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= sc_lb95 & D_pt == 1) [iw=W]

mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= sc_lb99 & D_pt == 0) [iw=W]
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= sc_lb99 & D_pt == 1) [iw=W]

********************************************************************************
* Run mi estimate with mysuest
********************************************************************************

* generate one variable for both weights, otherwise error in SUEST. 

mi estimate, esampvaryok: mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb95 & D_pt == 0) [iw=W]" ///
		"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb95 & D_pt == 1) [iw=W]"
mi estimate, esampvaryok: mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb99 & D_pt == 0) [iw=W]" ///
		"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb99 & D_pt == 1) [iw=W]"
		* note: only iweight seems to work in mi estimate + suest, otherwise error. 
mi estimate, vartable nocitable

********************************************************************************
* Run mi estimate with mysuest and test difference accross coefficients
********************************************************************************

mi estimate (diff: [soep_mean]ln_nw - [pretest_mean]ln_nw), esampvaryok nocoef: 	///
	mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb95 & D_pt == 0) [iw=W]"      ///
			"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb95 & D_pt == 1) [iw=W]"
mi testtransform diff
//mi estimate, vartable nocitable


mi estimate (diff: [soep_mean]ln_nw - [pretest_mean]ln_nw), esampvaryok nocoef: 	///
	mysuest "soep" "reg lnP_sp ln_nw if(nw >= sc_lb99 & D_pt == 0) [iw=W]"      ///
			"pretest" "reg lnP_pt ln_nw if(nw >= sc_lb99 & D_pt == 1) [iw=W]"
mi testtransform diff
//mi estimate, vartable nocitable

***
