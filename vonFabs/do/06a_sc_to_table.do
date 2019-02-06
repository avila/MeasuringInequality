
*** 6a. save scalars to table ***



clear
set matsize 11000
scalar m=5
local pctile p95 p99
local data sp pt

foreach pct of local pctile {

	/*
	**** template ****
					/ alpha_sp	/ N_sp	/ alpha_pt	/ N_pt	/ thres_pct	/ thres_val	/ suest_p-val	/
	nw1				/			/		/			/		/			/			/				/
	sd1				/			/		/			/		/			/			/				/
	nw2				/			/		/			/		/			/			/				/			
	sd2				/			/		/			/		/			/			/				/
	nw3				/			/		/			/		/			/			/				/			
	sd3				/			/		/			/		/			/			/				/
	nw4				/			/		/			/		/			/			/				/			
	sd4				/			/		/			/		/			/			/				/
	nw5				/			/		/			/		/			/			/				/			
	sd5				/			/		/			/		/			/			/				/
	ci lb			/			/		/			/		/			/			/				/
	ci up			/			/		/			/		/			/			/				/
	*/

	* define matrix: scalar results
	matrix R = J(12, 8 ,.)
	matrix colnames R = var alpha_sp N_sp alpha_pt N_pt thres_`pct' thres_val suest_p-val
	matrix rownames R = nw1 sd1 nw2 sd2 nw3 sd3 nw4 sd4 nw5 sd5 CI_lp CI_ub
	*matrix list R

	* pct without 'p'
	scalar PC = substr("`pct'",2,3)
	
	scalar b = 2
	scalar c = 3
	foreach dat of local data {	
		scalar a = 1
		forval imp=1(1)`=m' {
			di in red "scalar sc_alpha_`imp'_`pct'_`dat' = `=sc_alpha_`imp'_`pct'_`dat''"
			di in red "matrix: R[`=a',`=b']"
			di in red "scalar sc_N_`imp'_`pct'_`dat' = `=sc_N_`imp'_`pct'_`dat''"
			di in red "matrix: R[`=a',`=c']"

			matrix R[`=a',`=b'] = round(`=sc_alpha_`imp'_`pct'_`dat'',.001)
			matrix R[`=a',`=c'] = `=sc_N_`imp'_`pct'_`dat''
			matrix R[`=a',6] = `=PC'
			matrix R[`=a',7] = `=sc_absthres_`imp'_p95_round'
			matrix R[`=a',8] = round(`=sc_testpval_`imp'_`pct'',.001)
					
			scalar a = `=a' + 1
			
			matrix R[`=a',`=b'] = round(`=sc_sd_`imp'_`pct'_`dat'',.01)
			matrix R[11,`=b'] = round(`=sc_cilb_`pct'_`dat'',.001)
			matrix R[12,`=b'] = round(`=sc_ciub_`pct'_`dat'',.001)

			scalar a = `=a' + 1
		}
		
		scalar b = `=b' + 2
		scalar c = `=c' + 2

	}

	* transform matrix to Stata-file and process
	matrix list R
	drop _all
	svmat double R
	matrix drop R

	* rename and sort
	ren (R2 R3 R4 R5 R6 R7 R8) (alpha_sp N_sp alpha_pt N_pt thres_`pct' thres_val suest_pval)

	save "${outpath}alhpa_results_`pct'_temp.dta", replace
	clear



use "${outpath}alhpa_results_`pct'_temp.dta", clear

cap qui label drop alpha_results
label define alpha_results 1 "net wealth 1" 2 "" 3 "net wealth 2" 4 "" 5 "net wealth 3" 6 "" 7 "net wealth 4" 8 "" 9 "net wealth 5" 10 "" 11 "CI lower (`=sc_alphaCI_left')" 12 "CI upper (`=sc_alphaCI')"
replace R1 = _n
label values R1 alpha_results
label variable R1 ""

*** Latex table ***

listtex * using "${tables}alhpa_results_`pct'.tex", replace type rstyle(tabular) missnum() head("\begin{tabular}{ccccccccc}" `"\hline \textit{}&\textit{alpha\_SOEP}&\textit{N\_SOEP}&\textit{alpha\_Pretest}&\textit{N\_Pretest}&\textit{threshold percentile}&\textit{threshold value}&\textit{p-value}\\ \hline"') foot("\hline \end{tabular}")

/* *** NOTE for Latex table: ***
1. add manually to Latex in 2nd line:
	\hline \textit{}&\textit{$\alpha_{SOEP}$}&\textit{$N_{SOEP}$}&\textit{$\alpha_{Pretest}$}&\textit{$N_{Pretest}$}&\makecell{\textit{threshold} \\ \textit{percentile}}&\makecell{\textit{threshold} \\ \textit{value}}&\makecell{\textit{p-value} \\ $\alpha_{SOEP}=\alpha_{Pretest}$}\\ \hline
2. add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}
3. set sd into brackets
*/

}

***




