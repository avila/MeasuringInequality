
********************************************************************************
*** Master
********************************************************************************

clear all
set more off
set graph off
*ssc install paretofit

*** define folder structure
* Data (SOEP and Pretest) e
global data_path "/Users/sebastiankahl/Desktop/Maschinenraum/FreieUniversitaet/PublicEconomicsMaster/Ungleichheitsmessung/Seminar/Stataanalyse/Data"

* Do files
global do_path "/Users/sebastiankahl/Desktop/Maschinenraum/FreieUniversitaet/PublicEconomicsMaster/Ungleichheitsmessung/Seminar/Stataanalyse/Do"

* Output folder for final data
global out_path "/Users/sebastiankahl/Desktop/Maschinenraum/FreieUniversitaet/PublicEconomicsMaster/Ungleichheitsmessung/Seminar/Stataanalyse/Out"

* Results
global results_path "/Users/sebastiankahl/Desktop/Maschinenraum/FreieUniversitaet/PublicEconomicsMaster/Ungleichheitsmessung/Seminar/Stataanalyse/Results"

*log 
global log_path "/Users/sebastiankahl/Desktop/Maschinenraum/FreieUniversitaet/PublicEconomicsMaster/Ungleichheitsmessung/Seminar/Stataanalyse/Log"

/*

* define project-path
global mypath "/Users/sebastiankahl/Desktop/Maschinenraum/Freie Universität/Public Economics Master/Ungleichheitsmessung/Seminar/Analyse mit Stata" // <-- define
global datapath	"/Users/sebastiankahl/Desktop/Maschinenraum/Freie Universität/Public Economics Master/Ungleichheitsmessung/Seminar/Analyse mit Stata/Data"

* define globals
global soep 	"${datapath}/pwealth.dta"
global pretest	"${datapath}/pretest/"
global do		"${mypath}/do/"

global outpath	"${mypath}outpath/"

global graphs	"${outpath}graphs/"
global tables	"${outpath}/tables/"


 create folders if not exists
foreach dir in outpath graphs tables {
	if "`dir'" == "outpath" {
		capture confirm file "${mypath}`dir'"
		if _rc mkdir "${mypath}`dir'/"
	}
	else { 
		capture confirm file "${outpath}`dir'"
		if _rc mkdir "${outpath}`dir'/"
	}
}
*/
* display all generated scalars
global show_all "TRUE"

*** 

* 1. data preparation
do "$do_path/01_prep_data.do"

* 2. preparation of weights (SOEP, Pretest, SOEP+Pretest)
do "$do_path/02_prep_weights.do"

* 3. preparation of variables used for pareto distribution
do "$do_path/03_prep_pareto.do"

* 4.Seb -> short cut descriptive statistics and Pareto fit 

do "$do_path/04_Seb_descriptive_stats.do"

* 4. descriptive statistics

do "$do_path/04_descriptive_stats_paretofit.do"

* 5. additional graphs
do "$do_path/05_additional_graphs.do"

* 6. fitting pareto distribution
do "$do_path/06_fitting_pareto.do"

* 7. Pareto Graphs
do "$do_path/07_pareto_graphs.do"

* 8. threshold-alhpa-relation
do "$do_path/08_threshold_alpha.do"


set graph on

***

