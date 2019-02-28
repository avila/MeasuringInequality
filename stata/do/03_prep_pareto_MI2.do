

*** 3. Prepare Pareto Distribution ***

/* 
NOTE
*/


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

	sort D_pretest _`imp'_nw
	qui sum W_pt if D_pretest==1
	scalar sc_N = r(sum)
	gen F_pt_`imp'_ = sum(W_pt)/sc_N if D_pretest==1
	/* adjust single observation on top end of distribution  */
	*replace F_pt_`imp'_ = .999999 if F_pt_`imp'_==1
	gen P_pt_`imp'_ = 1 - F_pt_`imp'_ if D_pretest==1
	gen lnP_pt_`imp'_ = ln(P_pt_`imp'_) if D_pretest==1


	****************************************************************************
	*		
	*		SOEP (_sp)
	*		
	****************************************************************************

	sort D_pretest _`imp'_nw
	qui sum W_sp if D_pretest==0
	scalar sc_N = r(sum)
	gen F_sp_`imp'_ = sum(W_sp)/sc_N if D_pretest==0
	/* adjust single observation on top end of distribution  */
	*replace F_sp_`imp'_ = .999999 if F_sp_`imp'_==1
	gen P_sp_`imp'_ = 1 - F_sp_`imp'_ if D_pretest==0
	gen lnP_sp_`imp'_ = ln(P_sp_`imp'_) if D_pretest==0

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


***

