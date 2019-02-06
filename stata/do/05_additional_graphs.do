
*** 5. graphs ***

/* 
NOTE: In the following several graphs are plotted. Though, we have 5 imp. nw vars,
we plot only _1_nw_mio for simplicitly.
*/

set more off
use "${outpath}soep_pretest_2.dta", clear

********************************************************************************
*		
*		histograms: SOEP vs. Pretest
*		
********************************************************************************


* single histogram: nw in mio, soep vs. pretest, nw >0
forval s=0(5)5 {
	twoway	(histogram _1_nw_mio if _1_nw_mio>`s' & D_pretest==0, width(15) color(grey%50) freq) ///
		(histogram _1_nw_mio if _1_nw_mio>`s' & D_pretest==1, width(15) color(cranberry%35)		///
        xtitle("Net Wealth (in Mio. Euro)")														///
		legend(label(1 "SOEP 2012") label(2 "Pretest 2017")) scheme(s2mono) 					///
		note("Note: Net wealth in mio. Euro; values larger than `s' mio. Euro, first imputed net wealth variable.") ///
		saving(${graphs}histogram_nw_mio_larger`s'_sp_pt.gph, replace)							///
		ytitle("frequency") ylabel(, format(%9.0fc)) freq)
	graph export "${graphs}histogram_nw_mio_larger`s'_sp_pt.pdf", replace
}

* combining both graphs above
gr combine ${graphs}histogram_nw_mio_larger0_sp_pt.gph ${graphs}histogram_nw_mio_larger5_sp_pt.gph, ///
	 saving(${graphs}histogram_nw_mio_sp_pt_combined.gph, replace) scheme(s2mono) ///
	 commonscheme xcommon col(1) iscale(.7) 									///
	 title("Net Wealth of SOEP and Pretest", size(medsmall)) ///
	 note("Source: SOEP 2012 (v33.1) and Pretest 2017.")
graph export "${graphs}histogram_nw_mio_sp_pt_combined.pdf", replace


********************************************************************************
*		
*		CDF: SOEP (_sp), Pretest (_pt), SOEP+Pretest (_sppt)
*		
********************************************************************************

foreach data in sp pt sppt {
	
	if "`data'" == "sp" {
		local cumul_title "CDF of Net Wealth of SOEP"
		local cumul_lgnd "order(1 "SOEP")"
	}
	if "`data'" == "pt" {
		local cumul_title "CDF of Net Wealth of Pretest"
		local cumul_lgnd "order(1 "Pretest")"
	}
	if "`data'" == "sppt"  {
		local cumul_title "CDF of Net Wealth of SOEP and Pretest"
		local cumul_lgnd "order(1 "SOEP" 2 "Pretest")"
	}

	* prepare cumul variable
	cumul _1_nw_mio [fw=round(W_`data')] if _1_nw_mio>=0, gen(_1_nw_mio_cumul_`data')
	sort _1_nw_mio_cumul_`data'
	
	* plot cumul
	twoway	(line _1_nw_mio_cumul_`data' _1_nw_mio if D_pretest==0, lpattern(-) lcolor(grey))	///
			(line _1_nw_mio_cumul_`data' _1_nw_mio if D_pretest==1, ylab(, grid) ytitle("")		///
			lpattern(--) lcolor(cranberry%75)							///
			xlab(, grid) xtitle("Net Wealth (in Mio. Euro)") scheme(s2mono) 		///
			title("`cumul_title'") 						///
			legend(`cumul_lgnd') saving(${graphs}cumul_`data', replace))
	
	graph export "${graphs}cumul_`data'.pdf", replace
	
	drop _1_nw_mio_cumul_`data'
}

* TEST: Probability Density Function
//twoway	(kdensity _1_nw_mio if _1_nw_mio>1 & D_pretest==0 [fw=round(W_sp)])			///
//		(kdensity _1_nw_mio if _1_nw_mio>1 & D_pretest==1 [fw=round(W_pt)])

set graph on

***

