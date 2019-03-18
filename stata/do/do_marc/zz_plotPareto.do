/* Plot Pareto distributions */

global out_path "/home/avila/Documents/Projects/WS1819_FU/MeasuringInequality/slides/graphs"

local a1 = 2
local a2 = 3
local a3 = 5
local rl = 1000
local rh = 3000

local ylow  = 1000
local ylow2 = `ylow'/2
local ylow3 = `ylow' - 100

local yhig1 = 1000000
local yhig2 = 100000
local yhig3 = 10000 * 1.6
local plotLowBound = 0.01

* test comment
gen a * b

*** generate obs
drop _all
set obs 2000
egen x = seq(), from(0)
gen x1 = x + `ylow'

gen y1 = (`a1' * `ylow'^`a1') / (x1^(`a1' + 1))
gen y2 = (`a2' * `ylow'^`a2') / (x1^(`a2' + 1))
gen y3 = (`a3' * `ylow'^`a3') / (x1^(`a3' + 1))

gen y4 = (1 - (x1 / `ylow')^(-`a1'))
gen y5 = (1 - (x1 / `ylow')^(-`a2'))
gen y6 = (1 - (x1 / `ylow')^(-`a3'))

*** plot 
#delimit ;
graph twoway (line y1 x1 if x < `rh', lw(medthick))
             (line y2 x1 if x < `rh', lw(medthick))
             (line y3 x1 if x < `rh', lw(medthick)),
  xscale(range(`ylow3'))
  xlabel(,angle(90))

  bgcolor(white) graphregion(color(white))
  xline(`ylow', lpattern(dash) lcolor(grey))

  legend(order( 1 "{&alpha} = `a1'" 2 "{&alpha} = `a2'" 3 "{&alpha} = `a3'") rows(1))
  title("Probability Distribution Function")    xtitle("y")
  ytitle("f(y|{&alpha}, m=`ylow')")
  
  saving(paretoCDF, replace);
#delimit cr 

#delimit ;
graph twoway (line y4 x1, lw(medthick))
             (line y5 x1, lw(medthick))
             (line y6 x1, lw(medthick)), 
  xscale(range(`ylow3'))
  xlabel(,angle(90))
  
  xline(`ylow', lpattern(dash) lcolor(grey))
  bgcolor(white) graphregion(color(white))                                         
  legend(order( 1 "{&alpha} = `a1'" 2 "{&alpha} = `a2'" 3 "{&alpha} = `a3'") rows(1))
  title("Cumulative Distribution Function")  xtitle("y")
  ytitle("F(y|{&alpha}, m=`ylow')")
  
  saving(paretoPDF, replace);
#delimit cr

gr combine paretoCDF.gph paretoPDF.gph,  xsize(7) ///
  graphregion(color(white))

graph export ${out_path}/04_paretoDistGraphs.pdf, replace
