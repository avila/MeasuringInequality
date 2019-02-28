

*** 3. Prepare Pareto Distribution ***

/* 
NOTE:
*/

use "${outpath}soep_pretest_1_MI.dta", clear

mi passive: gen ln_nw = ln(nw) 

forval imp=1(1)5 {

	* generate log net wealth
	gen ln_nw_`imp'_ = ln(_`imp'_nw)

	****************************************************************************	
	*		Pretest (_pt)
	****************************************************************************

	sort D_pretest _`imp'_nw
	qui sum W_pt if D_pretest==1
	scalar sc_N = r(sum)
	gen F_pt_`imp'_ = sum(W_pt)/sc_N if D_pretest==1

	****************************************************************************	
	*		SOEP (_sp)	
	****************************************************************************

	sort D_pretest _`imp'_nw
	qui sum W_sp if D_pretest==0
	scalar sc_N = r(sum)
	gen F_sp_`imp'_ = sum(W_sp)/sc_N if D_pretest==0
}


****************************************************************************	
*		Pretest (_pt)
****************************************************************************

gen F_pt = .
replace F_pt = F_pt_1_ if _mi_miss == 0
mi register passive F_pt

forval imp=1(1)5 {
	replace _`imp'_F_pt = F_pt_`imp'_
}
mi passive: gen P_pt = 1 - F_pt
mi passive: gen lnP_pt = ln(P_pt)


****************************************************************************	
*		SOEP (_sp)
****************************************************************************

gen F_sp = .
replace F_sp = F_sp_1_ if _mi_miss == 0
mi register passive F_sp

forval imp=1(1)5 {
	replace _`imp'_F_sp = F_sp_`imp'_
}

mi passive: gen P_sp = 1 - F_sp
mi passive: gen lnP_sp = ln(P_sp)



* save dataset
br _*_lnP* *ln_nw
save "${outpath}soep_pretest_2_MI.dta", replace



********************************************************************************	
*
*		MI ESTIMATE
*
********************************************************************************


mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= 340000 & D_pretest == 0)
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= 340000 & D_pretest == 1)

mi estimate, esampvaryok: reg lnP_sp ln_nw if(nw >= 880000 & D_pretest == 0)
mi estimate, esampvaryok: reg lnP_pt ln_nw if(nw >= 880000 & D_pretest == 1)


cap program drop mysuest
program mysuest, eclass properties(mi)
        version 12.0
	args model1 model2

        qui `model1'
        estimates store est1
        qui `model2'
        estimates store est2
        suest est1 est2
        estimates drop est1 est2
        
        ereturn local title "Seemingly unrelated estimation"
end

mi estimate, esampvaryok: mysuest "reg lnP_sp ln_nw if(nw >= 340000 & D_pretest == 0)" "reg lnP_pt ln_nw if(nw >= 340000 & D_pretest == 1)"


test [est1_mean]ln_nw = [est2_mean]ln_nw

mi estimate (diff: [est1_mean]ln_nw - [est2_mean]ln_nw), esampvaryok nocoef: mysuest "reg lnP_sp ln_nw if(nw >= 340000 & D_pretest == 0)" "reg lnP_pt ln_nw if(nw >= 340000 & D_pretest == 1)"
mi testtransform diff


mi estimate (diff: [est1_mean]ln_nw - [est2_mean]ln_nw), esampvaryok nocoef: mysuest "reg lnP_sp ln_nw if(nw >= 880000 & D_pretest == 0)" "reg lnP_pt ln_nw if(nw >= 880000 & D_pretest == 1)"
mi testtransform diff
