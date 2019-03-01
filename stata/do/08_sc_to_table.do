
*** 8. save scalars to table ***

clear
set matsize 11000
scalar m=5
local pctile p95 p99
local data sp pt


********** Table 1 **********

foreach pct of local pctile {

	/*
	**** template ****																	Hausman
					/ alpha_sp	/ N_sp	/ alpha_pt	/ N_pt	/ thres_pct	/ thres_val	/ suest_p-value	/
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
	matrix colnames R = var alpha_sp N_sp alpha_pt N_pt thres_`pct' thres_val_`pct' suest_p-val
	matrix rownames R = nw1 sd1 nw2 sd2 nw3 sd3 nw4 sd4 nw5 sd5 CI_lp CI_ub
	*matrix list R

	* pct without 'p'
	scalar PC = substr("`pct'",2,3)
	
	scalar b = 2
	scalar c = 3
	foreach dat of local data {
		scalar a = 1
		forval imp=1(1)`=m' {
		
			* display scalars
			if "$show_all" == "TRUE" {
			di in red "scalar sc_alpha_`imp'_`pct'_`dat' = `=sc_alpha_`imp'_`pct'_`dat''"
			di in red "matrix: R[`=a',`=b']"
			di in red "scalar sc_N_`imp'_`pct'_`dat' = `=sc_N_`imp'_`pct'_`dat''"
			di in red "matrix: R[`=a',`=c']"
			}

			* write scalars into matrix R
			matrix R[`=a',`=b'] = round(`=sc_alpha_`imp'_`pct'_`dat'',.001)
			matrix R[`=a',`=c'] = `=sc_N_`imp'_`pct'_`dat''
			matrix R[`=a',6] = `=PC'
			matrix R[`=a',7] = `=sc_absthres_`imp'_`pct'_round'
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
	ren (R2 R3 R4 R5 R6 R7 R8) (alpha_sp N_sp alpha_pt N_pt thres_`pct' thres_val_`pct' suest_pval)

	save "${outpath}alhpa_results_`pct'_temp.dta", replace
	clear



	use "${outpath}alhpa_results_`pct'_temp.dta", clear

	cap qui label drop alpha_results
	label define alpha_results 1 "net wealth 1" 2 "" 3 "net wealth 2" 4 "" 5 "net wealth 3" 6 "" 7 "net wealth 4" 8 "" 9 "net wealth 5" 10 "" 11 "CI lower (`=sc_alphaCI_left')" 12 "CI upper (`=sc_alphaCI')"
	replace R1 = _n
	label values R1 alpha_results
	label variable R1 ""

	* prepare sd in parenthesis
	foreach dat of local data {
		tostring alpha_`dat', replace force
		replace alpha_`dat' = "(" + alpha_`dat' + ")" if !mod(_n,2) & _n!=12
	}

	* drop thres_val_`pct', we don't want to display `pct' in a column. Instead, write `pct' as title in table
	drop thres_`pct'

	* check
	if "$show_all" == "TRUE" {
	l
	}

	*** Latex table ***
	listtex * using "${tables}alhpa_results_`pct'.tex", replace type rstyle(tabular) missnum() ///
			head("\begin{table} \centering \begin{tabular}{ccccccccc}" `"\hline \textit{}&	\textit{$\alpha_{SOEP}$}&	\textit{$N_{SOEP}$}&	\textit{$\alpha_{Pretest}$}&	\textit{$N_{Pretest}$}&	textit{threshold}&	\textit{Hausman} \\ \hline"') ///
			foot("\hline \multicolumn{5}{l}{% \begin{minipage}{10cm}%  \vspace{.1cm} text text text \end{minipage}% } \\  \end{tabular} \caption{table title} \label{tab:reference} \end{table}")

/* *** NOTE for Latex table: ***
** add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}

** add \hline before the line "CI lower"

** to place table accurately on page: 
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/alhpa_results_p99_edited.tex}}

*/

}


********* Table 2 ***********
	/*
	**** template ****
			/ alpha_sp_99	/	N_sp_99	/ alpha_sp_95	/ N_sp_95	/ suest_p-val	/
	nw1		/				/			/				/			/				/
	sd1		/				/			/				/			/				/
	nw2		/				/			/				/			/				/	
	sd2		/				/			/				/			/				/
	nw3		/				/			/				/			/				/	
	sd3		/				/			/				/			/				/
	nw4		/				/			/				/			/				/
	sd4		/				/			/				/			/				/
	nw5		/				/			/				/			/				/
	sd5		/				/			/				/			/				/
	ci lb	/				/			/				/			/				/
	ci up	/				/			/				/			/				/
	*/


foreach dat of local data {
	
	* define matrix: scalar results
	matrix T = J(12, 6 ,.)
	matrix colnames T = var alpha_`dat'_p95 N_`dat'_p95 alpha_sp_p99 N_sp_p99 sc_testpval_`imp'_sp_p95vsp99
	matrix rownames T = nw1 sd1 nw2 sd2 nw3 sd3 nw4 sd4 nw5 sd5 CI_lp CI_ub
	matrix list T

	scalar a = 1
	forval imp=1(1)`=m' {

		scalar b = `=a' + 1
		
		* write scalars into matrix R
		matrix T[`=a',2] = round(`=sc_alpha_`imp'_p95_`dat'',.001)
		matrix T[`=a',4] = round(`=sc_alpha_`imp'_p99_`dat'',.001)
		matrix T[`=a',3] = `=sc_N_`imp'_p95_`dat''
		matrix T[`=a',5] = `=sc_N_`imp'_p99_`dat''
		matrix T[`=a',6] = round(`=sc_testpval_`imp'_`dat'',.001)
		
		matrix T[`=b',2] = round(`=sc_sd_`imp'_p95_`dat'',.001)
		matrix T[`=b',4] = round(`=sc_sd_`imp'_p99_`dat'',.001)
		
		scalar a = `=a' + 2
	}

	matrix T[11,2] = round(`=sc_cilb_p95_`dat'',.001)
	matrix T[12,2] = round(`=sc_ciub_p95_`dat'',.001)
	matrix T[11,4] = round(`=sc_cilb_p99_`dat'',.001)
	matrix T[12,4] = round(`=sc_ciub_p99_`dat'',.001)


	* transform matrix to Stata-file and process
	matrix list T
	drop _all
	svmat double T
	matrix drop T

	* rename and sort
	ren (T2 T3 T4 T5 T6) (alpha_`dat'_p95 N_`dat'_p95 alpha_`dat'_p99 N_`dat'_p99 suest_pval)

	save "${outpath}alhpa_results_`dat'_temp.dta", replace
	clear

	use "${outpath}alhpa_results_`dat'_temp.dta", clear

	cap qui label drop alpha_results
	label define alpha_results 1 "net wealth 1" 2 "" 3 "net wealth 2" 4 "" 5 "net wealth 3" 6 "" 7 "net wealth 4" 8 "" 9 "net wealth 5" 10 "" 11 "CI lower (`=sc_alphaCI_left')" 12 "CI upper (`=sc_alphaCI')"
	replace T1 = _n
	label values T1 alpha_results
	label variable T1 ""

	* prepare sd in parenthesis
	tostring alpha_`dat'_p95, replace force
	tostring alpha_`dat'_p99, replace force

	replace alpha_`dat'_p95 = "(" + alpha_`dat'_p95 + ")" if !mod(_n,2) & _n!=12
	replace alpha_`dat'_p99 = "(" + alpha_`dat'_p99 + ")" if !mod(_n,2) & _n!=12

	* check
	if "$show_all" == "TRUE" {
	l
	}
	
	if "`dat'" == "sp" {
	local dat_name "SOEP"
	}
	if "`dat'" == "pt" {
	local dat_name "Pretest"
	}
	
	*** Latex table ***
	listtex * using "${tables}alpha_results_`dat'.tex", replace type rstyle(tabular) missnum() ///
			head("\begin{table} \centering \begin{tabular}{cccccc}" `"\hline \textit{} & \textit{$\alpha_{p95}$}& \textit{$N_{p95}$} & \textit{$\alpha_{p99}$}& \textit{$N_{p99}$}& \textit{Hausman} \\ \hline"') ///
			foot("\hline \end{tabular} \caption{Pareto's Alphas based on the `dat_name'} \label{tab:reference} \end{table}")

}


/* *** NOTE for Latex table: ***
	
** add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}

** add \hline before the line "CI lower"

** to place table accurately on page: 
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/alhpa_results_p99_edited.tex}}

*/



***

