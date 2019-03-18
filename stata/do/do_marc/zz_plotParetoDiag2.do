/* Plot Pareto distributions */

global out_path "/home/avila/Documents/Projects/WS1819_FU/MeasuringInequality/slides/graphs"

local a1 = 2
local a2 = 3
local a3 = 5
local rl = 1000
local rh = 2000
local ylow  = 1000
local ylow1 = `ylow' - 600
local ylow2 = `ylow' - 150

local yhig1 = 1000000
local yhig2 = 100000
local yhig3 = 10000 * 1.6
local plotLowBound = 0.01

drop _all
set obs 10000
egen x = seq(), from(0)

gen x1 = `ylow' + (x * 100)
gen x2 = `ylow' + (x * 10)
gen x3 = x + `ylow'

gen y1 = (1 - (1 - (`ylow' / x1)^(`a1')))
gen y2 = (1 - (1 - (`ylow' / x2)^(`a2')))
gen y3 = (1 - (1 - (`ylow' / x3)^(`a3')))


*** PLOTS

* plot 1 (level)
#delimit ;
graph twoway (line y1 x1 if y1 > `plotLowBound', lw(medthick)) 
             (line y2 x2 if y2 > `plotLowBound', lw(medthick))  
	     (line y3 x3 if y3 > `plotLowBound', lw(medthick)),  
  xscale(range(`ylow1'))
  ylabel(0.05 0.2(0.2)1 1)
  xlabel(,angle(90))
  xline(`ylow', lpattern(dash) lcolor(grey))

  bgcolor(white) graphregion(color(white))                                         
  legend(order( 1 "{&alpha} = `a1'" 2 "{&alpha} = `a2'" 3 "{&alpha} = `a3'") rows(1))
  title("Pareto Diagram (linear)")  xtitle("y")
  ytitle("1 - F(y|{&alpha}, m=`ylow')")

  saving(paretoDiagram01, replace);
#delimit cr

* plot 2 (log)

replace y1 = log(y1)
replace y2 = log(y2)
replace y3 = log(y3)
replace x1 = log(x1)
replace x2 = log(x2)
replace x3 = log(x3)

#delimit ;
graph twoway (line y1 x1 if y1 > log(`plotLowBound'), lw(medthick)) 
             (line y2 x2 if y2 > log(`plotLowBound'), lw(medthick))  
	     (line y3 x3 if y3 > log(`plotLowBound'), lw(medthick)),  
  //xscale(log r(`ylow2')) yscale(log)
  //ylabel(0.05 0.2(0.2)1 1)
  //xlabel(,angle(90))
  
  xline(`ylow', lpattern(dash) lcolor(grey))

  bgcolor(white) graphregion(color(white))                                         
  legend(order( 1 "{&alpha} = `a1'" 2 "{&alpha} = `a2'" 3 "{&alpha} = `a3'") rows(1))
  title("Pareto Diagram (log-log)")  xtitle("y")
  ytitle("1 - F(y|{&alpha}, m=`ylow')")

  saving(paretoDiagram02, replace);
#delimit cr

gr combine paretoDiagram01.gph paretoDiagram02.gph,   xsize(7) ///
  graphregion(color(white))

graph export ${out_path}/04_paretoDiagram.pdf, replace


