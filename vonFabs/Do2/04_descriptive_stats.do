
*** 4. descriptive statistics ***

set more off
use "${outpath}soep_pretest_2.dta", clear


********************************************************************************
*
*	list example dataset
*
********************************************************************************

sort _1_nw
gen trash = _n
list syear _*_nw imp_flag schicht D_pretest if inlist(,trash,1,2,3,27825,28068,28067,28048,28044,28045,28046,17040,17041,17042), noobs clean

* latex table
listtex syear _*_nw imp_flag schicht D_pretest 											///
	if inlist(,trash,1,2,3,27825,28068,28067,28048,28044,28045,28046,17040,17041,17042) ///
	using "${tables}datset_excerpt1.tex", replace type rstyle(tabular)					///
            head("\begin{tabular}{rrr}" `"\textit{Survey Year}&\textit{Net Wealth #1}&\textit{Net Wealth #2}&\textit{Net Wealth #3}&\textit{Net Wealth #4}& \textit{Net Wealth #5}& \textit{Imp. Flag}& \textit{Schicht}& \textit{Dummy Pretest/SOEP}\\"') /// 
			foot("\end{tabular}") e(&\cr{\noalign{\hrule}})
* txt table
listtex syear _*_nw imp_flag schicht D_pretest 											///
	if inlist(,trash,1,2,3,27825,28068,28067,28048,28044,28045,28046,17040,17041,17042) ///
	using "${tables}datset_excerpt2.tex", replace type rstyle(tabular)	 missnum(.) 	///
	head("Survey Year&Net Wealth #1&Net Wealth #2&Net Wealth #3&Net Wealth #4&Net Wealth #5&Imp. Flag&Schicht&Dummy Pretest")

* Clean Up
drop trash

********************************************************************************
*
*	summary statistics: net wealth SOEP, PRETEST, SOEP+PRETEST
*
********************************************************************************

* format variables
doubletofloat _*_nw

* nw of soep 2012
sum _1_nw if D_pretest
scalar sc_max_soep = r(max)

*  nw of pretest 2017
tabstat _*_nw if D_pretest==0, s(n mean p50 p75 p95 p99 min max sd) format(%14.2f) c(v)
tabstat _*_nw if D_pretest==1, s(n mean p50 p75 p95 p99 min max sd) format(%14.2f) c(v)
tabstat _*_nw, s(n mean p50 p75 p95 p99 min max sd) format(%14.2f) c(v)

* define display formats
local fmt_count "%10.0fc"
local fmt_stats "%10.2fc"

*** Generate summary statistics for SOEP (sp), Pretest (pt) and for both (sppt) ***
* Note: the code loops first over '0' meaning that nw is displayed unrestricted and
*		'1' meaning that nw is restricted on the range: nw>0 (see local option_`data').
*		For simplicity, we pick `imp' = 1 for _1_nw_mio for nw>0

forval i=1(1)2 {
	
	*local i=1
	* generate used locals for 'estpost summarize'
	local estpost_sp	""
	local estpost_pt	""
	local estpost_sppt	""
	* nw full range
	local option1_sp	"if D_pretest == 0"
	local option1_pt	"if D_pretest == 1"
	local option1_sppt	""
	* nw>0
	local option2_sp	"if _1_nw_mio > 0 & D_pretest == 0"
	local option2_pt	"if _1_nw_mio > 0 & D_pretest == 1"
	local option2_sppt	"if _1_nw_mio > 0"
	* sources
	local source_sp		"SOEP 2012 (v33.1)"
	local source_pt		"Pretest 2017"
	local source_sppt	"`source_sp' and `source_pt'"

	
	* generate estpost locals and variables
	foreach data in sp pt sppt {
		
		forval imp=1(1)5 {
			local estpost_`data' "`estpost_`data'' _`imp'_nw_mio_`data'"
			* label
			local label_sp		"SOEP nw imp. `imp'"
			local label_pt		"Pretest nw imp. `imp'"
			local label_sppt	"SOEP + Pretest nw imp. `imp'"

			di "`estpost_`data''"
			gen _`imp'_nw_mio_`data' = _`imp'_nw_mio `option`i'_`data''
			label variable _`imp'_nw_mio_`data' "`label_`data''"
		}
	
		* sample sizes
		qui sum _1_nw_mio_`data' `option`i'_`data''
		scalar sc_N_i`i'_`data'=r(N)

	}

	* generate summary statistics
	estpost summarize `estpost_sp' `estpost_pt' `estpost_sppt', detail

	esttab using "${tables}summary_statistics`i'_in_mio.tex", 			///
				replace varwidth(44) nonumber noobs nomtitles label		///
				cells("count(fmt(`fmt_count')) mean(fmt(`fmt_stats')) p50(fmt(`fmt_stats')) p75(fmt(`fmt_stats')) p90(fmt(`fmt_stats')) p99(fmt(`fmt_stats')) min(fmt(`fmt_stats')) max(fmt(`fmt_stats'))" ) ///
				title(Descriptive Statistics of `source_sp' and `source_pt') ///
				addnote("Source: `source_sppt'." "Note: Net wealth (nw) imputed, in mio. Euro, for simplicity rounded.")
				

	****************************************************************************
	*
	* tables with applied frequency weights: SOEP, PRETEST, SOEP+PRETEST
	*
	****************************************************************************

	
	local W_sp_info		"SOEP: with applied cross-sectional weight (N=`=sc_N_i`i'_sp')"
	local W_pt_info		"Pretest: with own re-weighting scheme (N=`=sc_N_i`i'_pt')"
	local W_sppt_info 	"SOEP (cross-sectional weights, scaled down by 1\%) and Pretest (own re-weighting) (N=`=sc_N_i`i'_sppt')"
		
	*** SOEP (sp), PRETEST (pt), SOEP+PRETEST(sppt) with frequency weights
	
	foreach data in sp pt sppt {
	
		estpost summarize `estpost_`data'' [fw=round(W_`data')] `option`i'_`data'', detail 

		esttab using "${tables}summary_statistics`i'_in_mio_`data'_only_weighted.tex", 	///
				replace varwidth(44) nonumber noobs nomtitles label						///
				cells("count(fmt(`fmt_count')) mean(fmt(`fmt_stats')) p50(fmt(`fmt_stats')) p75(fmt(`fmt_stats')) p90(fmt(`fmt_stats')) p99(fmt(`fmt_stats')) min(fmt(`fmt_stats')) max(fmt(`fmt_stats'))" ) ///
				title(Descriptive Statistics of `source_`data'') 						///
				addnote("Source: `source_`data''." "Note: Net wealth (nw), imputed, weighted and displayed in mio. Euro, for simplicity rounded." "`W_`data'_info'.")
				
	}

	drop `estpost_sp' `estpost_pt' `estpost_sppt'

}



***

