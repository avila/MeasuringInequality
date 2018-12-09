# distribution, cdf, quantile and random functions for Pareto distributions
dpareto <- function(x, xm, alpha) ifelse(x > xm , alpha*xm**alpha/(x**(alpha+1)), 0)
ppareto <- function(q, xm, alpha) ifelse(q > xm , 1 - (xm/q)**alpha, 0 )
qpareto <- function(p, xm, alpha) ifelse(p < 0 | p > 1, NaN, xm*(1-p)**(-1/alpha))
rpareto <- function(n, xm, alpha) qpareto(runif(n), xm, alpha)

pareto.mle <- function(x)
{
  xm <- min(x)
  alpha <- length(x)/(sum(log(x))-length(x)*log(xm))
  return( list(xm = xm, alpha = alpha))
}


pareto.test <- function(x, B = 1e3)
{
  a <- pareto.mle(x)
  
  # KS statistic
  D <- ks.test(x, function(q) ppareto(q, a$xm, a$alpha))$statistic
  
  # estimating p value with parametric bootstrap
  B <- 1e5
  n <- length(x)
  emp.D <- numeric(B)
  for(b in 1:B)
  {
    xx <- rpareto(n, a$xm, a$alpha);
    aa <- pareto.mle(xx)
    emp.D[b] <- ks.test(xx, function(q) ppareto(q, aa$xm, aa$alpha))$statistic
  }
  
  return(list(xm = a$xm, alpha = a$alpha, D = D, p = sum(emp.D > D)/B))
}

# generating 100 values from Pareto distribution
x <- rpareto(100, 0.5, 2)
pt <- pareto.test(x, B = 500)


x <- rpareto(100, 0.5, 2)
pareto.mle(x)


pretest <- readstata13::read.dta13(file = "./data/pretest_topw.dta")

duplicated(pretest)

pretest[!duplicated(lapply(pretest, c))]

library(dplyr)


pretest$mean <- round(rowMeans(pretest[,2:6]))
pretest

pretest$sd <- -999
pretest$impFlag <- -999
for (i in 1:nrow(pretest)) {
  sdRow <- sd(as.numeric(pretest[i,2:6]))
  cat(paste("Row:", i, "| sd:", sdRow, "\n"))
  pretest$sd[i] <- sdRow
  pretest$impFlag[i] <- ifelse(sdRow == 0, 0, 1)
}
head(pretest, 30)
mean(pretest$impFlag)

sd(pretest$mean)
mean(pretest$mean)/10^6


x <- pretest$mean[pretest$mean>0]
x <- sort(x)

pareto.mle <- function(x)
{
  xm <- min(x)
  alpha <- length(x)/(sum(log(x))-length(x)*log(xm))
  return( list(xm = xm, alpha = alpha))
}

n <- length(x)
pMLE <- list()
for (i in 1:n) {
  y <- x[i:length(x)]
  pMLE[[i]] <- pareto.mle(x = y)
}

dfpMLE <- data.frame(matrix(unlist(pMLE), nrow = n, byrow = TRUE))
plot(head(dfpMLE$X2, 100))




