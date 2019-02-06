
*** 7. Pareto Graphs ***

/* 
Note: 12 graphs: 
	- sp, pt, sppt
	- threshold p95, p99
	- with lfit / lfitci	
	
	* We want to plot starting from the threshold.
	* unfortunately, Stata can't handle xscale(range(.)) while plotting several 
	* twoway-graphs. Therefore, we drop all obs below the threshold value with 
	* Stata's preserve command

*/

use "${outpath}soep_pretest_2.dta", clear

* define threshold levels as percentiles of SOEP
local pctile p95 p99

* define datasets: SOEP (sp), Pretest (pt), SOEP+Pretest (sppt)
local data pt sp sppt

* m: number of imputations
scalar m = 5

forval imp=1(1)`=m' {
	foreach pc of local pctile {	
		qui sum ln_nw_`imp'_ if D_pretest==0, d
		scalar sc_thres_`imp'_`pc' = r(`pc')
		scalar sc_thres_`imp'_`pc'_round = round(r(`pc'),.01)
		scalar sc_max_`imp' = r(max)
		if "${show_all}" == "TRUE" {
			di "threshold `pc': `=sc_thres_`imp'_`pc'_round'"
			di "maximum: `=sc_max_`imp''"
		}
	}
}


********************************************************************************
*		
*		Pareto Distribution: SOEP, Pretest, SOEP+Pretest
*		
********************************************************************************

* define cosmetic locals
local symbol_opt "jitter(1.25) msize(small) msymbol(oh) mlwidth(thin)"
local line_opt " lpattern(_--) lwidth(thin)"

* loop over three datasets
foreach dat of local data {
	
	if "`dat'" == "sp" {
		local g_title "SOEP"
		local g_nw_opt "D_pretest==0"
		local g_src "SOEP 2012 (v33.1)"
		local g_note " with applied cross-sectional weights."
		local g_note2 "         "
		local g_abbrev "Abbrev.: {it:nw}=net wealth, {it:`dat'}=SOEP."
		local g_col "blue%80"
	}
	if "`dat'" == "pt" {
		local g_title "Pretest"
		local g_nw_opt "D_pretest==1"
		local g_src "Pretest 2017"
		local g_note " with own calculated re-weighting scheme."
		local g_note2 "         "
		local g_abbrev "Abbrev.: {it:nw}=net wealth, {it:`dat'}=Pretest."
		local g_col "cranberry%80"

	}
	if "`dat'" == "sppt" {
		local g_title "SOEP and the Pretest"
		local g_nw_opt "inlist(D_pretest,0,1)"
		local g_src "SOEP 2012 (v33.1) and Pretest 2017"
		local g_note ". For the SOEP we scale down the cross-sectional"
		local g_note2 "weights by 1% and added the weights of the Pretest."
		local g_abbrev ""
		local g_abbrev2 " Abbrev.: {it:nw}=net wealth, {it:`dat'}=SOEP+Pretest."
		local g_col "navy%80"
		
	}

	****************************************************************************
	*		Pareto Distribution: Scatterplot
	****************************************************************************
	
	twoway ///
	(scatter lnP_`dat'_1_ ln_nw_1_ if `g_nw_opt', sort(ln_nw_1_) `symbol_opt' mlcolor(gs5%50))		 ///
	(scatter lnP_`dat'_2_ ln_nw_2_ if `g_nw_opt', sort(ln_nw_2_) `symbol_opt' mlcolor(midblue%50))	 ///
	(scatter lnP_`dat'_3_ ln_nw_3_ if `g_nw_opt', sort(ln_nw_3_) `symbol_opt' mlcolor(cranberry%50)) ///
	(scatter lnP_`dat'_4_ ln_nw_4_ if `g_nw_opt', sort(ln_nw_4_) `symbol_opt' mlcolor(orange%50))	 ///
	(scatter lnP_`dat'_5_ ln_nw_5_ if `g_nw_opt', sort(ln_nw_5_) `symbol_opt' mlcolor(gold%60)		 ///
	ylab(, grid) ytitle("ln(P)") xlab(, grid) xtitle("ln(nw)") scheme(s2mono) 						 ///
	title("Pareto Distribution of the `g_title'") ///
	legend(row(1) order(1 "ln(nw{sub:1})" 2 "ln(nw{sub:2})" 3 "ln(nw{sub:3})" 4 "ln(nw{sub:4})" 5 "ln(nw{sub:5})")) ///
	note("Source: `g_src'." "Note: We display all 5 imputed net wealth variables`g_note'" "`g_abbrev'`g_note2'`g_abbrev2'"))
	
	*graph export "${graphs}pareto_distrib_scatter_`dat'.pdf", replace
	
	
	****************************************************************************
	*		Pareto Distribution: Scatterplot + lin. regression fit
	****************************************************************************
	
	preserve
	
	foreach pct of local pctile {
	
	restore
	preserve
		forval imp=1(1)5 {
			drop if ln_nw_`imp'_ < `=sc_thres_`imp'_`pct''
		}

	local thres_pct = substr("`pct'",2,3)
	di in red "+++++ dataset: `dat', threshold: `pct', threshold value: `=sc_thres_1_`pct''"
	
	twoway ///
	(scatter lnP_`dat'_1_ ln_nw_1_ if ln_nw_1_ >= `=sc_thres_1_`pct'' & `g_nw_opt', sort(ln_nw_1_) `symbol_opt' mcolor(gs4%50))		///
	(scatter lnP_`dat'_2_ ln_nw_2_ if ln_nw_2_ >= `=sc_thres_2_`pct'' & `g_nw_opt', sort(ln_nw_2_) `symbol_opt' mcolor(midblue%50))	///
	(scatter lnP_`dat'_3_ ln_nw_3_ if ln_nw_3_ >= `=sc_thres_3_`pct'' & `g_nw_opt', sort(ln_nw_3_) `symbol_opt' mcolor(cranberry%50)) ///
	(scatter lnP_`dat'_4_ ln_nw_4_ if ln_nw_4_ >= `=sc_thres_4_`pct'' & `g_nw_opt', sort(ln_nw_4_) `symbol_opt' mcolor(orange%50))	///
	(scatter lnP_`dat'_5_ ln_nw_5_ if ln_nw_5_ >= `=sc_thres_5_`pct'' & `g_nw_opt', sort(ln_nw_5_) `symbol_opt' mcolor(gold%50))	///
	(lfit lnP_`dat'_1_ ln_nw_1_ if ln_nw_1_ >= `=sc_thres_1_`pct'' & `g_nw_opt', sort(ln_nw_1_) `line_opt' lcolor(gs5)) 			///
	(lfit lnP_`dat'_2_ ln_nw_2_ if ln_nw_2_ >= `=sc_thres_2_`pct'' & `g_nw_opt', sort(ln_nw_2_) `line_opt' lcolor(blue)) 			///
	(lfit lnP_`dat'_3_ ln_nw_3_ if ln_nw_3_ >= `=sc_thres_3_`pct'' & `g_nw_opt', sort(ln_nw_3_) `line_opt' lcolor(cranberry)) 		///
	(lfit lnP_`dat'_4_ ln_nw_4_ if ln_nw_4_ >= `=sc_thres_4_`pct'' & `g_nw_opt', sort(ln_nw_4_) `line_opt' lcolor(orange)) 			///
	(lfit lnP_`dat'_5_ ln_nw_5_ if ln_nw_5_ >= `=sc_thres_5_`pct'' & `g_nw_opt', sort(ln_nw_5_) `line_opt' lcolor(gold) 			///
	ytitle("ln(P)") xlab(, grid) xtitle("ln(nw)") scheme(s2mono) ///
	title("Pareto Distribution of `g_title'") subtitle("with fitted regression lines") /*xscale(range(10 20))*/ ///
	legend(row(5) order(1 "ln({it:nw}{sub:{it:1}})" 6 "ln({it:P}{sub:{it:1,`dat'}}) ~ ln({it:nw}{sub:{it:1}})" 2 "ln({it:nw}{sub:{it:2}})" 7 "ln({it:P}{sub:{it:2,`dat'}}) ~ ln({it:nw}{sub:{it:2}})" 3 "ln({it:nw}{sub:{it:3}})" ///
	8 "ln({it:P}{sub:{it:3,`dat'}}) ~ ln({it:nw}{sub:{it:3}})" 4 "ln({it:nw}{sub:{it:4}})" 9 "ln({it:P}{sub:{it:4,`dat'}}) ~ ln({it:nw}{sub:{it:4}})" 5 "ln({it:nw}{sub:{it:5}})" 10 "ln({it:P}{sub:{it:5,`dat'}}) ~ ln({it:nw}{sub:{it:5}})" )) ///
	note("Source: `g_src'." "Note: We display all 5 imputed net wealth variables`g_note'" "`g_note2' Threshold at `thres_pct'% percentile of the SOEP. `g_abbrev'" "`g_abbrev2'"))

	*graph export "${graphs}pareto_distrib_scatter_`dat'_`pct'_reg.pdf", replace

	}
	
	restore
	*/

	****************************************************************************
	*		Pareto Distribution: Scatterplot + lin. regression fit SINGLE
	****************************************************************************

	* define cosmetic locals
	local symbol_opt2 "jitter(.5) msize(small) msymbol(oh) mlwidth(thin) mcol(`g_col')"
	local line_opt2 "lpattern(solid) lwidth(vthin) lcol(gs10%50)"
	local g_all ""
	
	foreach pct of local pctile {
	
	forval imp=1(1)`=m' {
	
	di in red "+++++ dataset: `dat', imputation: `imp', threshold: `pct', threshold value: `=sc_thres_`imp'_`pct''"
			
		* standalone graph
		twoway  ///
		(scatter lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt', `symbol_opt2' sort(ln_nw_`imp'_)) 		///
		(lfitci lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt' & ln_nw_`imp'_ >= `=sc_thres_`imp'_`pct'', 	///
		ciplot(rline)) ///
		(lfit lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt' & ln_nw_`imp'_ >= `=sc_thres_`imp'_`pct'', 	/// 
		sort(ln_nw_`imp'_) ytitle("ln(P)") xlab(, grid) xtitle("ln(nw)") ///
		scheme(s2mono) title("ln({it:nw}{sub:{it:`imp'}})") `line_opt2' ///
		saving(`g_`imp'', replace) ///
		legend(row(1) order(1 "ln({it:nw}{sub:{it:`imp'}})" 3 "ln({it:P}{sub:{it:`imp',`dat'}}) ~ ln({it:nw}{sub:{it:`imp'}})" 2)))
		
		
		* combine above graphs (not needed anymore)
		/*
		local g_`imp' "${graphs}pareto_single_`dat'_`imp'_temp.gph"

		twoway  ///
		(scatter lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt', `symbol_opt2' sort(ln_nw_`imp'_)) ///
		(lfitci lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt' & ln_nw_`imp'_ >= `=sc_thres_`imp'_`pct'', ///
		ciplot(rline)) ///
		(lfit lnP_`dat'_`imp'_ ln_nw_`imp'_ if `g_nw_opt' & ln_nw_`imp'_ >= `=sc_thres_`imp'_`pct'', /// 
		sort(ln_nw_`imp'_) ytitle("ln(P)") xlab(, grid) xtitle("ln(nw)") ///
		scheme(s2mono) title("ln({it:nw}{sub:{it:`imp'}})") `line_opt2' ///
		saving(`g_`imp'', replace) ///
		legend(off))
		
		if inlist("`dat'","sp","pt") {
			local g_all "`g_all' `g_`imp''"
		}
		*/
	}
	}	
	
}


***
