*** 3. Prepare Pareto Distribution ***

/* 
NOTE
*/

use "$out_path/soep_pretest_1.dta", clear

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
	qui sum W_pt_dest if D_pretest==1
	scalar sc_N = r(sum)
	gen cum_pop_share_pt_`imp'_ = sum(W_pt_dest)/sc_N if D_pretest==1
	replace cum_pop_share_pt_`imp'_=0.99999 if cum_pop_share_pt_`imp'_==1
	gen P_pt_`imp'_ = 1 - cum_pop_share_pt_`imp'_ if D_pretest==1
	gen lnP_pt_`imp'_ = ln(P_pt_`imp') if D_pretest==1

	****************************************************************************
	*		
	*		SOEP (_sp)
	*		
	****************************************************************************

	sort D_pretest _`imp'_nw
	qui sum W_sp if D_pretest==0
	scalar sc_N = r(sum)
	gen cum_pop_share_sp_`imp'_ = sum(W_sp)/sc_N if D_pretest==0
	replace cum_pop_share_sp_`imp'_=0.99999 if cum_pop_share_sp_`imp'_==1
	gen P_sp_`imp'_ = 1 - cum_pop_share_sp_`imp'_ if D_pretest==0
	gen lnP_sp_`imp'_ = ln(P_sp_`imp') if D_pretest==0
}

* check all generated variables
foreach data in sp pt {
	di in red _newline "+++++ `data' +++++"
	sum ln_nw_*_
	sum cum_pop_share_`data'_*_
	sum lnP_`data'_*_
	sum P_`data'_*_
}

* save dataset
save "$out_path/soep_pretest_2.dta", replace

***
