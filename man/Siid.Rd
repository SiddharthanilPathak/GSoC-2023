% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Siidclass.R
\name{Siid}
\alias{Siid}
\alias{as.Siid}
\alias{as.Siid.default}
\alias{is.iid}
\title{Siid class}
\usage{
Siid(data, varnames = colnames(data))
}
\arguments{
\item{data}{: an iid output matrix with nsim rows and p columns}

\item{varnames}{: a character string equal to the number of columns in \code{data}}
}
\value{
an Siid class object
}
\description{
Class for independent and identically distributed (iid) samples
}
\examples{
# Generating iid data
chain <- matrix(rnorm(3*1e3), nrow = 1e3, ncol = 3)
siid.obj <- Siid(chain)

}
