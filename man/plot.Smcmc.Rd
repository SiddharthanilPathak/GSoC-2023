% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Smcmcclass.R
\name{plot.Smcmc}
\alias{plot.Smcmc}
\title{Summary plot function for Smcmc objects}
\usage{
\method{plot}{Smcmc}(x, which = NULL, ...)
}
\arguments{
\item{x}{: a `Smcmc' class object}

\item{which}{: If you are intresetd in few components only}

\item{...}{: Other arguments}
}
\value{
return plot(s) of the all the dimensions of Smcmc object
}
\description{
Plots traceplot, acfplot and densityplot of all the dimensions of 
chains in  Smcmc object
}
\examples{
# Producing Markov chain
chain <- matrix(0, ncol = 1, nrow = 1e3)
chain[1,] <- 0
err <- rnorm(1e3)
for(i in 2:1e3)
{
  chain[i,] <- .3*chain[i-1,] + err[i]
}
chain <- Smcmc(list(chain))
plot(chain)

}
