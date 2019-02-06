//    Estimate on completed data using logit
clear all
webuse mheart1s20
mi describe
mi estimate, dots: logit attack smokes age bmi hsgrad female

