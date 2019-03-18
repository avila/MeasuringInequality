a <- 1.7
lb <- 550 * 10^3
ptmp <- c(.95, .99, .999)
p <-  (ptmp - .95) * 20
lb <- 550000
tops<-(lb)/(1-p)^(1/a) / 10^3; tops
tops2 <- (1 - p)^(-1/a) * lb; tops2
tops_avg <- tops * (a/(a-1)); tops_avg

Hh = 410000
props <- (1-ptmp) * Hh  
(props * tops_avg) / 10^3


6 * 1e6 * 1e6

F <- (-10:10)/10
F
a <- 3
((1 - p)^(-1/a)) * 100

#################
LowerBound <- 550000
I_want <- c(.95, .99, .999)  # those are the pcts we want to estimate
I_want
th <- 0.99 # lower bound is set at the 95th percentile
I_need <- (I_want - th) * (1/(1-th)) # those are the pcts we actually need. 
                                    # this formulation "blows" up the fraction 
                                    # we are interested in (>th) by multiplying
                                    # with the inverse of (1 - th). 
I_need 
est_want <- ((1 - I_want)^(-1/a)) * LowerBound
est_need <- ((1 - I_need)^(-1/a)) * LowerBound
est_want / 1e3  # if we estimate with the "want" pcts, we get the jump. 
                # because we estimating the 95th, 96th, ... 99th percentile 
                # of a distribution that starts at 550.000 lower bound. 
                # Therefore, it starts at the 0th percentile 

est_need / 1e3  # if we estimate with the "need" pcts, we get the numbers we
                # actually wanted. 
###################

library("VGAM")
qpareto(p = I_want, LowerBound, a) / 1e3
qpareto(p = I_need, LowerBound, a) / 1e3
qpareto(p = 0:10/10, LowerBound, a) / 1e3
qpareto(p = 0.8, 100, a)
((1 - p)^(-1/a)) * 100
p


I_want
I_need
