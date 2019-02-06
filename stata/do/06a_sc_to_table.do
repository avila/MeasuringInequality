
*** 6a. save scalars to table ***



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
			head("\begin{tabular}{ccccccccc}" `"\hline \textit{}&	\textit{alpha\_SOEP}&	\textit{N\_SOEP}&	\textit{alpha\_Pretest}&	\textit{N\_Pretest}&	textit{threshold}&	\textit{Hausman}\\ \hline"') ///
			foot("\hline \end{tabular}")


/* *** NOTE for Latex table: ***

1. provide a table environment that encases the tabular environment
	\begin{table}
		\centering
		....			<<-- add here
		\end{tabular}
		\caption{table title} \label{tab:reference}
	\end{table}

2. add to Latex in 2nd line:
	\hline \textit{}&   \textit{$\alpha_{SOEP}$}&   \textit{$N_{SOEP}$}&   \textit{$\alpha_{Pretest}$}&    \textit{$N_{Pretest}$}&	\textit{threshold}& \textit{Hausman} \\ \hline
	
3. add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}

4. add \hline before the line "CI lower"

5. add title and label

6. save tex-file to overleaf-folder

7. to place table accurately on page: 
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/alhpa_results_p99_edited.tex}}

	DONE!

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

	*** Latex table ***
	listtex * using "${tables}alpha_results_`dat'.tex", replace type rstyle(tabular) missnum() ///
			head("\begin{tabular}{cccccc}" `"\hline \textit{}&	\textit{\alpha_p95}&	\textit{N_p95}&	\textit{\alpha_p99}&	\textit{N_p99}&	\textit{Hausman}\\ \hline"') ///
			foot("\hline \end{tabular}")

}


/* *** NOTE for Latex table: ***

1. provide a table environment that encases the tabular environment
	\begin{table}
		\centering
		....			<<-- add here
		\end{tabular}
		\caption{table title} \label{tab:reference}
	\end{table}

2. add to Latex in 2nd line:
	\hline \textit{}&   \textit{$\alpha_{SOEP}$}&   \textit{$N_{SOEP}$}&   \textit{$\alpha_{Pretest}$}&    \textit{$N_{Pretest}$}&	\textit{threshold}& \textit{Hausman} \\ \hline
	\hline \textit{}&   \textit{$\alpha_{p95}$}&    \textit{$N_{p95}$}& \textit{$\alpha_{p99}$}&    \textit{$N_{p99}$}& \textit{Hausman}\\ \hline
	
3. add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}

4. add \hline before the line "CI lower"

5. add title and label

6. save tex-file to overleaf-folder

7. to place table accurately on page: 
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/alhpa_results_p99_edited.tex}}

	DONE!

*/


********* Table 3 ***********

********************************************************************************
* Calculating example values (Top 5%, 1%, 0.1%)
********************************************************************************
* NOTE: E.g. calculate the min. net wealth that the Top 1% richest population has, 
*		according to the fitted Pareto's Alpha based on the Pretest.

* Idea: solve for ln_nw:
* 		lnP   = alpha * ln_nw + intercept
* 		ln_nw = 1/alpha * (lnP - intercept)
* 		then: exp() for absolute value

* corresponding variables
* lnP: 		lnP_sp_*_ 			-- base on SOEP
* alpha: 	sc_alpha_*_p*_pt	-- bases on Pretest
* intercept: sc_cons_*_p*_sp	-- comes from fitting Pareto's Alpha for SOEP

* Tables:
* #1: table with p95 with alpha soep -> soep fitted
* #2: table with p99 with alpha soep -> soep fitted
* #3: table with p95 with alpha pretest -> soep fitted
* #4: table with p99 with alpha pretest -> soep fitted


* 1. Define top wealth percentages (=values of ordinate in Pareto's Distribution)
scalar sc_top001 = 	ln(0.001)
scalar sc_top01  = 	ln(0.01)
scalar sc_top025 = 	ln(0.025)
scalar sc_top05  = 	ln(0.05)

* 2. Example: calculate the top 1% threshold p95, imput. 1, top 1%
*scalar sc_nw_top1_1_p95_sp_ = exp((1/`=sc_alpha_1_p95_pt')*(`=sc_top01' - `=sc_cons_1_p95_pt'))
*di "sc_nw_top1_1_p95_sp_ = `=sc_nw_top1_1_p95_sp_'"

* 3. Generate Tables
/* 
Scalar Coding:
sc_nw_top001_a_pt_`imp'_`pct'_sp_ = 
[scalar]_[netwealth]_[top0.1%]_[alpha from pt]_[imputation_pct]_[threshold]_[estimated on soep]
 */

foreach pct of local pctile {

	use "${outpath}soep_pretest_2.dta", clear
	
	* make sure only SOEP is in dataset
	keep if D_pretest==0
	
	* prepare a matrix where scalars will be saved to
	capture matrix drop P
	matrix P = J(7, 5 ,.)
	matrix colnames P = var P_top_95 P_top_975 P_top_99 P_top_999
	matrix rownames P = nw1 nw2 nw3 nw4 nw5 nw_mean N
	matrix list P

	scalar a = 1

	forval imp=1(1)`=m' {
		
		di "+++++ `=a' +++++"
		
		* generate scalars
		scalar sc_nw_top05_a_pt_`imp'_`pct'_sp_ 	= exp((1/`=sc_alpha_`imp'_`pct'_pt')*(`=sc_top05' 	- `=sc_cons_`imp'_`pct'_sp'))
		scalar sc_nw_top025_a_pt_`imp'_`pct'_sp_	= exp((1/`=sc_alpha_`imp'_`pct'_pt')*(`=sc_top025' 	- `=sc_cons_`imp'_`pct'_sp'))
		scalar sc_nw_top01_a_pt_`imp'_`pct'_sp_ 	= exp((1/`=sc_alpha_`imp'_`pct'_pt')*(`=sc_top01' 	- `=sc_cons_`imp'_`pct'_sp'))
		scalar sc_nw_top001_a_pt_`imp'_`pct'_sp_	= exp((1/`=sc_alpha_`imp'_`pct'_pt')*(`=sc_top001' 	- `=sc_cons_`imp'_`pct'_sp'))

		* calculate maximum net wealth (intersection with abszissa, calculate ln(nw) where lnP gets null)
		*scalar sc_nw_max_a_pt_5_`pct'_sp_ 			= exp((1/`=sc_alpha_`imp'_`pct'_pt')*(-1000	- `=sc_cons_`imp'_`pct'_sp'))
		
		*** write scalars into matrix ***
		* net wealth value
		matrix P[`=a',2] = round( `=sc_nw_top05_a_pt_`imp'_`pct'_sp_',.001)
		matrix P[`=a',3] = round(`=sc_nw_top025_a_pt_`imp'_`pct'_sp_',.001)
		matrix P[`=a',4] = round( `=sc_nw_top01_a_pt_`imp'_`pct'_sp_',.001)
		matrix P[`=a',5] = round(`=sc_nw_top001_a_pt_`imp'_`pct'_sp_',.001)

		* mean of imputations
		if `imp'==`=m' {
		matrix P[6,2] = (1/`=m')*( `=sc_nw_top05_a_pt_1_`pct'_sp_' + `=sc_nw_top05_a_pt_2_`pct'_sp_' + `=sc_nw_top05_a_pt_3_`pct'_sp_' + `=sc_nw_top05_a_pt_4_`pct'_sp_' + `=sc_nw_top05_a_pt_5_`pct'_sp_')
		matrix P[6,3] = (1/`=m')*(`=sc_nw_top025_a_pt_1_`pct'_sp_' + `=sc_nw_top025_a_pt_2_`pct'_sp_' + `=sc_nw_top025_a_pt_3_`pct'_sp_' + `=sc_nw_top025_a_pt_4_`pct'_sp_' + `=sc_nw_top025_a_pt_5_`pct'_sp_')
		matrix P[6,4] = (1/`=m')*( `=sc_nw_top01_a_pt_1_`pct'_sp_' + `=sc_nw_top01_a_pt_2_`pct'_sp_' + `=sc_nw_top01_a_pt_3_`pct'_sp_' + `=sc_nw_top01_a_pt_4_`pct'_sp_' + `=sc_nw_top01_a_pt_5_`pct'_sp_')
		matrix P[6,5] = (1/`=m')*(`=sc_nw_top001_a_pt_1_`pct'_sp_' + `=sc_nw_top001_a_pt_2_`pct'_sp_' + `=sc_nw_top001_a_pt_3_`pct'_sp_' + `=sc_nw_top001_a_pt_4_`pct'_sp_' + `=sc_nw_top001_a_pt_5_`pct'_sp_')		
		
		* N populations
		matrix P[7,2] = 66000000*0.05 /* Top 5% population */
		matrix P[7,3] = 66000000*0.025
		matrix P[7,4] = 66000000*0.01 /* Top 1% population */
		matrix P[7,5] = 66000000*0.001

		* sum net wealth above (graphically: triangle)
		*matrix P[8,2] = ((`=sc_nw_max_a_pt_5_`pct'_sp_' - P[5,2]) * 66000000*0.05) / 2
		*matrix P[8,3] = ((`=sc_nw_max_a_pt_5_`pct'_sp_' - P[5,3]) * 66000000*0.025) / 2
		*matrix P[8,4] = ((`=sc_nw_max_a_pt_5_`pct'_sp_' - P[5,4]) * 66000000*0.01) / 2
		*matrix P[8,5] = ((`=sc_nw_max_a_pt_5_`pct'_sp_' - P[5,5]) * 66000000*0.001) / 2
		
		}
		
		if "$show_all" == "TRUE" {
		di "+++++++++++++++++++"
		di "sc_nw_top001_a_pt_`imp'_`pct'_sp_ 	= `=sc_nw_top001_a_pt_`imp'_`pct'_sp_'"
		di "sc_nw_top01_a_pt_`imp'_`pct'_sp_ 	= `=sc_nw_top01_a_pt_`imp'_`pct'_sp_'"
		di "sc_nw_top025_a_pt_`imp'_`pct'_sp_ 	= `=sc_nw_top025_a_pt_`imp'_`pct'_sp_'"
		di "sc_nw_top05_a_pt_`imp'_`pct'_sp_ 	= `=sc_nw_top05_a_pt_`imp'_`pct'_sp_'"
		}

		scalar a = `=a' + 1
		
	}

	* transform matrix to Stata-file and process
	matrix list P
	drop _all
	svmat double P
	matrix drop P

	* rename
	ren (P2 P3 P4 P5) (top_05 top_025 top_01 top_001)

	save "${outpath}estimated_net_wealth_top5to001_`pct'_temp.dta", replace
	clear

	use "${outpath}estimated_net_wealth_top5to001_`pct'_temp.dta", clear

	* prepare variables for presentation
	replace P1 = _n
	label values P1 nw_results
	label variable P1 ""

	qui ds
	foreach var in `r(varlist)' {
	
		if "`var'" != "P1" {
			 replace `var' = round(`var'/1000000,.001) if (_n!=7 & `var'!=.) 
		}
	}
	
	cap qui label drop nw_results
	label define nw_results 1 "net wealth 1" 2 "net wealth 2" 3 "net wealth 3" 4 "net wealth 4" 5 "net wealth 5" 6 "mean" 7 "N"

	* check
	if "$show_all" == "TRUE" {
	l
	}

	*** Latex table ***
	listtex * using "${tables}estimated_net_wealth_top5to001_`pct'.tex", replace type rstyle(tabular) missnum() ///
			head("\begin{tabular}{cccccc}" `"\hline \textit{}&	\textit{top05}&	\textit{top025}&	\textit{top01}&	\textit{top001}\\ \hline"') ///
			foot("\hline \end{tabular}")

}
l

/*	*** template ***
	
	/ y_top_95	/ y_top_975	/ y_top_99	/ y_top_99.9/
nw1	/			/			/			/			/
nw2	/			/			/			/			/
nw3	/			/			/			/			/
nw4	/			/			/			/			/
nw5	/			/			/			/			/
mean/			/			/			/			/
N	/			/			/			/			/
sum	/			/			/			/			/

*/
/* *** NOTE for Latex table: ***

1. provide a table environment that encases the tabular environment
	\begin{table}
		\centering
		....			<<-- add here
		\end{tabular}
		\caption{table title} \label{tab:reference}
	\end{table}

2. add to Latex in 2nd line:
	\hline \textit{}&      \textit{Top 5\%}& \textit{Top 2.5\%}&        \textit{Top 1\%}& \textit{Top 0.1\%}\\ \hline
	
3. add title and label:
	\caption{Estimated net wealths for selected top percentages}

4. add note section:
	insert right after last \hline of table and before \end{tabular}
	...
	\hline
	
	\multicolumn{5}{l}{%
	\begin{minipage}{10cm}%
    \vspace{.1cm}
		Note: We estimated the Top percentages of the SOEP with $\hat{\alpha}_{Pretest}$ and a threshold at the 95th percentile of the net wealth of the SOEP.
	\end{minipage}%
	}\\
	
	\end{tabular}
	...
	
5. save tex-file to overleaf-folder

7. to place table accurately on page: 
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/estimated_net_wealth_top5to001_p99_edited.tex}}

	DONE!

*/








***

