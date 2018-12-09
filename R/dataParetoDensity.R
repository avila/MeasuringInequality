library(MASS)
library(fitdistrplus)
library(actuar)

dataPar <- EnvStats::rpareto(n = 10^3, location = 1000, shape =  9)
dataDens <- density(dataPar)
plot(dataDens)
hist(dataPar, breaks = 30)
plot(dataPar,1-CDF(dataPar), log = "xy")


df <- data.frame(c(x1 = dataPar, x2=(1-CDF(dataPar))))
