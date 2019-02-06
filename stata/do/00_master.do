
********************************************************************************
*** Master
********************************************************************************

clear all
set more off
set graph off
*ssc install paretofit

* define project-path
if "`c(username)'" == "Fabian" {
	global mypath	"/Users/Fabian/OneDrive/Studium/Seminar/"
	global datapath	"/Users/Fabian/Documents/DATA/STATA/"
}
else if "`c(username)'" == "avila" {
	global mypath	"/home/avila/Documents/Projects/WS1819_FU/MeasuringInequality/stata/" // <-- define
	global datapath	"/data/DatasetsSOEP"
}
else if "`c(username)'" == "Tobias?" {
	global mypath	"define path accordingly"
	global datapath	"define path accordingly"
}
else if "`c(username)'" == "Sebastian?" {
	global mypath	"define path accordingly"
	global datapath	"define path accordingly"
}

* define globals
global soep 	"${datapath}/SOEP_v33.1/SOEP_wide/"
global pretest	"${datapath}/pretest/"

global do		"${mypath}/do/"
global outpath	"${mypath}outpath/"

global graphs	"${outpath}graphs/"
global tables	"${outpath}/tables/"


* create folders if not exists
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

* display all generated scalars
global show_all "TRUE"

***

* 1. data preparation
do "${do}01_prep_data.do"

* 2. preparation of weights (SOEP, Pretest, SOEP+Pretest)
do "${do}02_prep_weights.do"

* 3. preparation of variables used for pareto distribution
do "${do}03_prep_pareto.do"

* 4. descriptive statistics
do "${do}04_descriptive_stats.do"

* 5. additional graphs
do "${do}05_additional_graphs.do"

* 6. fitting pareto distribution
do "${do}06_fitting_pareto.do"

* 7. Pareto Graphs
do "${do}07_pareto_graphs.do"

* 8. threshold-alhpa-relation
do "${do}08_threshold_alpha.do"

set graph on

***

