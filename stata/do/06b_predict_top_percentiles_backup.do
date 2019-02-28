
*** 6b. predict top percentiles ***

********************************************************************************
*
* Calculating example values for Top 5%, 1%, 0.1%
*
********************************************************************************

* NOTE: Calculate the min. net wealth that the Top x% richest population has.
*		We use the fitted Pareto's Alpha of the Pretest and predict the Top 
*		net nwealths of the SOEP.

* use: 	threshold = exp(`=thres_1_p95'), 
*		alpha = sc_alpha_1_p95_sp

* calculation: 	F = 1-(y_thres/y)^sc_alpha
* 				y_predict = ((1-quantile)^(-1/sc_alpha)) * y_thres

set matsize 11000
scalar m=5
local pctile p95 p99

* Define Top (Top 5%, 2.5%, 1% and Top 0.1%) percentiles for predictions
scalar sc_top005 = .95
scalar sc_top025 = .975
scalar sc_top010 = .99
scalar sc_top001 = .999


foreach pct of local pctile {

	* prepare a matrix where scalars will be saved to
	capture matrix drop `pct'
	matrix `pct' = J(7, 5 ,.)
	matrix colnames `pct' = var P_top_95 P_top_975 P_top_99 P_top_999
	matrix rownames `pct' = nw1 nw2 nw3 nw4 nw5 nw_mean N
	matrix list `pct'

	use "${outpath}soep_pretest_2.dta", clear


	* Define local with all scalars sc_predtop* (needed for sc_meanpredtop*)
	local mean_pred_top005_`pct' ""
	local mean_pred_top025_`pct' ""
	local mean_pred_top010_`pct' ""
	local mean_pred_top001_`pct' ""
	
	forval imp=1(1)`=m' {
		
		* Simplify scalars
		* (negative alpha -> absolute alpha; ln(net wealth) -> absolute net wealth)
		scalar sc_absalpha_`imp'_`pct'_pt 	= `=sc_alpha_`imp'_`pct'_pt'*(-1)
		*scalar sc_thresabs_`imp'_`pct' 		= exp(`=thres_`imp'_`pct'')

		* Generate F
		*sort _`imp'_nw D_pretest
		*gen sc_F_`imp'_`pct'_sp = 1-(`=sc_absthres_`imp'_`pct''/ _`imp'_nw)^(`=sc_absalpha_`imp'_`pct'_pt') if D_pretest == 0
		* gibt es schon: cum_pop_share_pt_`imp'_

		* Predictions Top Percentiles
		scalar sc_predtop005_`imp'_`pct'_sp = round(((1-`=sc_top005')^(-1/`=sc_absalpha_`imp'_`pct'_pt'))*`=sc_thresabs_`imp'_`pct'',.01)
		scalar sc_predtop025_`imp'_`pct'_sp = round(((1-`=sc_top025')^(-1/`=sc_absalpha_`imp'_`pct'_pt'))*`=sc_thresabs_`imp'_`pct'',.01)
		scalar sc_predtop010_`imp'_`pct'_sp = round(((1-`=sc_top010')^(-1/`=sc_absalpha_`imp'_`pct'_pt'))*`=sc_thresabs_`imp'_`pct'',.01)
		scalar sc_predtop001_`imp'_`pct'_sp = round(((1-`=sc_top001')^(-1/`=sc_absalpha_`imp'_`pct'_pt'))*`=sc_thresabs_`imp'_`pct'',.01)
		
		
		* Calculate the Mean of the Predictions across all imputations
		* mean = 1/5 * (sc_predtop005_1_`pct'_sp + sc_predtop005_2_`pct'_sp + ... + sc_predtop005_5_`pct'_sp)
		if (`imp' != `=m') {
			local mean_pred_top005_`pct' "`mean_pred_top005_`pct'' `=sc_predtop005_`imp'_`pct'_sp' + "
			local mean_pred_top025_`pct' "`mean_pred_top025_`pct'' `=sc_predtop025_`imp'_`pct'_sp' + "
			local mean_pred_top010_`pct' "`mean_pred_top010_`pct'' `=sc_predtop010_`imp'_`pct'_sp' + "
			local mean_pred_top001_`pct' "`mean_pred_top001_`pct'' `=sc_predtop001_`imp'_`pct'_sp' + "
		}
		if (`imp' == `=m') {
			local mean_pred_top005_`pct' "`mean_pred_top005_`pct'' `=sc_predtop005_`imp'_`pct'_sp'"
			local mean_pred_top025_`pct' "`mean_pred_top025_`pct'' `=sc_predtop025_`imp'_`pct'_sp'"
			local mean_pred_top010_`pct' "`mean_pred_top010_`pct'' `=sc_predtop010_`imp'_`pct'_sp'"
			local mean_pred_top001_`pct' "`mean_pred_top001_`pct'' `=sc_predtop001_`imp'_`pct'_sp'"
			scalar sc_meanpredtop005_`pct'_sp = 1/`=m'*(`mean_pred_top005_`pct'')
			scalar sc_meanpredtop025_`pct'_sp = 1/`=m'*(`mean_pred_top025_`pct'')
			scalar sc_meanpredtop010_`pct'_sp = 1/`=m'*(`mean_pred_top010_`pct'')
			scalar sc_meanpredtop001_`pct'_sp = 1/`=m'*(`mean_pred_top001_`pct'')
		}
		
		* Write scalars to matrix for table
		matrix `pct'[`imp',2] = `=sc_predtop005_`imp'_`pct'_sp'
		matrix `pct'[`imp',3] = `=sc_predtop025_`imp'_`pct'_sp'
		matrix `pct'[`imp',4] = `=sc_predtop010_`imp'_`pct'_sp'
		matrix `pct'[`imp',5] = `=sc_predtop001_`imp'_`pct'_sp'
		if (`imp' == `=m') {
			matrix `pct'[`imp'+1,2] = `=sc_meanpredtop005_`pct'_sp'		
			matrix `pct'[`imp'+1,3] = `=sc_meanpredtop025_`pct'_sp'		
			matrix `pct'[`imp'+1,4] = `=sc_meanpredtop010_`pct'_sp'		
			matrix `pct'[`imp'+1,5] = `=sc_meanpredtop001_`pct'_sp'		
			matrix `pct'[`imp'+2,2] = 60000000*0.05
			matrix `pct'[`imp'+2,3] = 60000000*0.025
			matrix `pct'[`imp'+2,4] = 60000000*0.01
			matrix `pct'[`imp'+2,5] = 60000000*0.001
		}

		
		* Display all Predictions (for all pct, all imputations)
		if "$show_all" == "TRUE" {
		di "++++++++++++ Predictions of Top Percentiles ++++++++++++" _newline "  (with alpha based on Pretest, threshold at `pct', imp. `imp')" _newline "  threshold: `=sc_thresabs_`imp'_`pct''" _newline " alpha: `=sc_absalpha_`imp'_`pct'_pt'"
		di in red "Top 5% has min.:   `=sc_predtop005_`imp'_`pct'_sp' Euro"
		di in red "Top 2.5% has min.: `=sc_predtop025_`imp'_`pct'_sp' Euro"
		di in red "Top 1% has min.:   `=sc_predtop010_`imp'_`pct'_sp' Euro"
		di in red "Top 0.1% has min.: `=sc_predtop001_`imp'_`pct'_sp' Euro"
		di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		}
		
	}
		
	* Display all Means of Predictions
	if "$show_all" == "TRUE" {
	di _newline "++++++++++ Means of Predicted Top Percentiles ++++++++++" _newline " (with alpha based on Pretest, threshold at `pct', mean of all imp.)" _newline "  threshold: `=sc_thresabs_`imp'_`pct''"  _newline " alph: `=sc_absalpha_`imp'_`pct'_pt'"
	di in red "Mean Top 5%:   `=sc_meanpredtop005_`pct'_sp'"	
	di in red "Mean Top 2.5%: `=sc_meanpredtop025_`pct'_sp'"	
	di in red "Mean Top 1%:   `=sc_meanpredtop010_`pct'_sp'"	
	di in red "Mean Top 0.1%: `=sc_meanpredtop001_`pct'_sp'"
	di "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	}


	* transform matrix to Stata-file and process
	matrix list `pct'
	drop _all
	svmat double `pct'
	matrix drop `pct'

	* rename and label
	ren (`pct'2 `pct'3 `pct'4 `pct'5) (pred_top_95 pred_top_975 pred_top_99 pred_top_999)	
	cap qui label drop pred_top_pct
	label define pred_top_pct 1 "net wealth 1" 2 "net wealth 2" 3 "net wealth 3" 4 "net wealth 4" 5 "net wealth 5" 6 "mean" 7 "N"
	replace `pct'1 = _n
	label values `pct'1 pred_top_pct
	label variable `pct'1 ""

	* check
	if "$show_all" == "TRUE" {
	l
	}
		
	*** Latex table ***
	listtex * using "${tables}predict_top_percentiles_`pct'.tex", replace type rstyle(tabular) missnum() ///
			head("\begin{table} \centering \begin{tabular}{ccccc}" `"\hline \textit{}&	\textit{Top 5\%}&	\textit{Top 2.5\%}&	\textit{Top 1\%}&	\textit{Top 0.1\%}\\ \hline"') ///
			foot("\hline \multicolumn{5}{l}{% \begin{minipage}{10cm}%  \vspace{.1cm} Note: We estimated the Top percentages of the SOEP with $\hat{\alpha}_{Pretest}$ and a threshold at the 95th percentile of the net wealth of the SOEP. \end{minipage}% } \\  \end{tabular} \caption{table title} \label{tab:reference} \end{table}")

	
}


/*	*** template ***
	
	/ y_top_95	/ y_top_975	/ y_top_99	/ y_top_99.9/
nw1	/			/			/			/			/
nw2	/			/			/			/			/
nw3	/			/			/			/			/
nw4	/			/			/			/			/
nw5	/			/			/			/			/
mean/			/			/			/			/
N	/			/			/			/			/

*/
/* *** NOTE for Latex table: ***

add packages:
	\usepackage[euler]{textgreek}
	\usepackage{graphicx}
	\usepackage{makecell}

Add note section:
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
	
To place table accurately on page:
	\resizebox{.5\width}{!}{\input{Seminararbeit/img/estimated_net_wealth_top5to001_p99_edited.tex}}

*/


***
