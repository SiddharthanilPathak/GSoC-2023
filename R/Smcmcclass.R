## usethis namespace: start
#' @importFrom grDevices adjustcolor dev.interactive
#' @importFrom graphics boxplot par polygon segments boxplot.matrix mtext lines abline points
#' @importFrom stats cov density qnorm quantile ts var qchisq rnorm sd IQR acf na.fail
#' @importFrom mcmcse mcse.multi batchSize
## usethis namespace: end

#' @title Smcmc class
#'
#' @description Smcmc class for simulated data using Markov chain Monte Carlo
#'
#' @name Smcmc
#' @aliases Smcmc as.Smcmc as.Smcmc.default is.mcmc 
#' @usage Smcmc(data, batch.size = TRUE, stacked = TRUE, varnames = NULL)
#' @param data : a list of MCMC output matrices each with `nsim` rows and `p` columns
#' @param batch.size : logical argument, if true, calculates the batch size appropriate for this Markov chain. Setting to TRUE saves time in future steps.
#' @param stacked : recommended to be `TRUE`. logical argument, if true, stores a carefully stacked version of the MCMC output for use later.
#' @param varnames : a character string equal to the number of columns in \code{data}
#'
#' @return an Smcmc class object
#' @examples
#' # Producing Markov chain
#' chain <- matrix(0, nrow = 1e3, ncol = 1)
#' chain[1,] <- 0
#' err <- rnorm(1e3)
#' for(i in 2:1e3)
#' {
#'   chain[i,] <- .3*chain[i-1,] + err[i]
#' }
#' smcmc.obj <- Smcmc(chain)
#' @export
Smcmc <- function(data,
                    batch.size = TRUE, 
                    stacked = TRUE,
                    varnames = NULL) # make Smcmc object
{
  if(missing(data))
    stop("Data must be provided.")
  
  
  if(!is.list(data))
  {
    data = as.matrix(data)
    data <- list(data)
  }else
  {
    for(i in 1:length(data))
    {
      data[[i]] = as.matrix(data[[i]])
    }
  }
  
  nsim <- dim(data[[1]])[1]
  if(is.null(varnames))
  {
    for(i in 1:length(data)){if(!is.null(colnames(data[[i]]))){varnames = colnames(data[[i]]);break }}
  }
  
  if(stacked == TRUE)
  {
    foo <- chain_stacker(data)
    stacked.chain <- foo$stacked.data
    
    if(batch.size == TRUE)
    {
      size <- foo$b.size
    }
    else{
      size <- NULL
    }
  }
  
  out <- list( chains = data,
               stacked  = stacked.chain,
               b.size   = size,
               nsim     = nsim,
               varnames = varnames)
  
  class(out) <- "Smcmc"
  return(out)
}

"is.Smcmc" <- function (x) 
{
  if (inherits(x, "Smcmc")) 
    return(TRUE)
  return(FALSE)
}

#' @export
"as.Smcmc" <- function (x, ...) 
  UseMethod("as.Smcmc")

#' @export
"as.Smcmc.default" <- function (x, ...) 
  if (is.Smcmc(x)) x else Smcmc(x)




#' @title density plot form Smcmc class
#'
#' @description Density plots with simultaenous error bars around means and quantiles
#'  for MCMC data. The error bars account for the correlated nature of the process.
#'
#'
#' @name densityplot
#' @usage densityplot(x, Q = c(0.1, 0.9), alpha = 0.05, thresh = 0.001, main = NA, iid = FALSE,
#'                             mean = TRUE, which = NULL, border = NA, mean.col = 'plum4', 
#'                             quan.col = 'lightsteelblue3',rug = FALSE, opaq = 0.7, ...)    
#' @param x : a `Smcmc' class object
#' @param Q : vector of quantiles
#' @param alpha : confidence level of simultaneous confidence intervals 
#' @param thresh : numeric typically less than .005 for the accuracy of the simulteaneous procedure
#' @param main : To add main heading
#' @param iid : logical argument for constructing density plot for iid samples. Defaults to \code{FALSE}
#' @param mean : logical argument whether the mean is to be plotted
#' @param which : A vector of components, if you want plots of specific components.
#' @param border : whether a border is required for the simultaneous confidence intervals
#' @param mean.col : color for the mean confidence interval
#' @param quan.col : color for the quantile confidence intervals
#' @param rug : logical indicating whether a rug plot is desired
#' @param opaq : opacity of \code{mean.col} and \code{quan.col}. A value of 0 is transparent and 1 is completely opaque.
#' @param ... : arguments passed on to the \code{density} plot in base R
#' @return returns a plot of the univariate density estimates with simultaneous
#'			confidence intervals wherever asked. If \code{plot == FALSE} a list of
#'			estimates and simultaneous confidence intervals.
#' @examples
#' # Producing Markov chain
#' chain <- matrix(0, ncol = 1, nrow = 1e3)
#' chain[1,] <- 0
#' err <- rnorm(1e3)
#' for(i in 2:1e3)
#' {
#'   chain[i,] <- .3*chain[i-1,] + err[i]
#' }
#' chain <- Smcmc(list(chain))
#' densityplot(chain)
#'
#' @references
#' Robertson, N., Flegal, J. M., Vats, D., and Jones, G. L., 
#' “Assessing and Visualizing Simultaneous Simulation Error”, 
#' Journal of Computational and Graphical Statistics,  2020. 
#'
#' @export


"densityplot" <- function(x, 
                          Q        = c(0.1, 0.9), 
                          alpha    = 0.05, 
                          thresh   = 0.001, 
                          main     = NA,
                          iid      = FALSE, 
                          mean     = TRUE,
                          which    = NULL,
                          border   = NA, 
                          mean.col = 'plum4', 
                          quan.col = 'lightsteelblue3',
                          rug      = FALSE, 
                          opaq     = 0.7, ...)
{
  
  x <- as.Smcmc(x)
  out <- getCI(x, Q, alpha, thresh = thresh, iid = iid, mean = mean)
  plot.CIs(x, CIs = out, bord = border, 
             mean.color = adjustcolor(mean.col, alpha.f = opaq), 
             quan.color = adjustcolor(quan.col, alpha.f = opaq), 
             mean = mean, rug = rug, main = main, which= which, ...)
  invisible(out)
}


#' @title Summary plot function for Smcmc objects
#'
#' @description Plots traceplot, acfplot and densityplot of all the dimensions of 
#' chains in  Smcmc object
#' @usage \method{plot}{Smcmc}(x, which = NULL, ...)
#' @name plot.Smcmc
#' @param x : a `Smcmc' class object
#' @param which : If you are intresetd in few components only
#' @param ... : Other arguments
#' @return return plot(s) of the all the dimensions of Smcmc object
#' @examples
#' # Producing Markov chain
#' chain <- matrix(0, ncol = 1, nrow = 1e3)
#' chain[1,] <- 0
#' err <- rnorm(1e3)
#' for(i in 2:1e3)
#' {
#'   chain[i,] <- .3*chain[i-1,] + err[i]
#' }
#' chain <- Smcmc(list(chain))
#' plot(chain)
#'
#'@export

"plot.Smcmc" <- function(x, which = NULL, ...)
{
  if(!("Smcmc"%in%class(x))){stop("Argument must be Smcmc object")}
  y = x$chains
  dimn <- dim(y[[1]])
  n <- dimn[1]
  p <- dimn[2]
  m <- length(x)
  p2 <- 0
  p3 <- 0
  if(!is.null(which)){p = length(which)}else{which = 1:p}
  if(p>12){stop("Maximum allowed dimension is 12")}
  if(p>4){p2 = p-4;p = 4}
  if(p2 >4)
  {
    p3 <- p2-4
    p2 <- 4
  }
  par(mfrow = c(3,p),oma = c(0,0,0,0),mar = c(2.2,4,1,1))
  traceplot(x,which = which[1:p],legend = F,xlab = NA,...)
  acfplot(x,which = which[1:p],xlab = NA,...)
  densityplot(x,which = which[1:p],...)
  
  if(p2>0)
  {
    par(mfrow = c(3,p2),mar = c(2,4,1,2))
    traceplot(x,which = which[5:(4+p2)],legend = F,xlab = NA)
    acfplot(x,which = which[5:(4+p2)],xlab = NA)
    densityplot(x,which = which[5:(4+p2)])
  }
  
  if(p3>0)
  {
    par(mfrow = c(3,p3),mar = c(2,4,1,2))
    traceplot(x,which = which[9:(8+p3)],legend = F,xlab = NA)
    acfplot(x,which = which[9:(8+p3)],xlab = NA)
    densityplot(x,which = which[9:(8+p3)])
  }
  on.exit(par(ask = FALSE,mfrow=c(1,1)))
  par(mar = c(5.1, 4.1, 4.1, 2.1))
  par(fig = c(0, 1, 0 , 1))
  par(oma = c(0, 0, 0, 0))
}


#' @title Summary function for Smcmc objects
#' @name summary.Smcmc
#' @description To show different statistics of the Smcmc object
#' @usage \method{summary}{Smcmc}(object, eps = 0.10, alpha = 0.05, Q = c(0.10, 0.90), ...)
#' @param object : a `Smcmc' class object
#' @param eps : desired volume of the confidence region
#' @param alpha : Type one error/threshold percentage error
#' @param Q : desired quantiles (vector of 2)
#' @param ... : Other arguments
#' @return return statistics of the all the dimensions(& chains) in Smcmc object
#' @examples
#' # Producing Markov chain
#' chain <- matrix(0, ncol = 1, nrow = 1e3)
#' chain[1,] <- 0
#' err <- rnorm(1e3)
#' for(i in 2:1e3)
#' {
#'   chain[i,] <- .3*chain[i-1,] + err[i]
#' }
#' chain <- Smcmc(list(chain))
#' summary(chain)
#'
#'@export

"summary.Smcmc" <- function (object,
                             eps = 0.10,
                             alpha = 0.05,
                             Q = c(0.10, 0.90), ...)
{
  object <- as.Smcmc(object)
  object.class <- class(object)
  Batch_Size <- object$b.size
  Smcmc_output <- object$chains[[1]]
  stacked <- as.matrix(object$stacked)
  
  chains <- object$chains
  n <- dim(chains[[1]])[1]
  p <- dim(chains[[1]])[2]
  m <- length(chains)
  dimen <- vector(length = p)
  if(!is.null(object$varnames)){dimen <- object$varnames }else{for(i in 1:p){dimen[i] <- paste("Component",i)}}
  colname <- c("Mean","MCSE","SD",paste("Q-",Q[1],sep=""),paste("Q-",Q[2],sep=""), "ESS","G-R"," ")
  c_batch = dim(stacked)[1]/m
  std = 0
  for(i in 1:m)
  {
    a = 1+(i-1)*c_batch
    b = i*c_batch
    std = std + apply(as.matrix(stacked[a:b, ]),2,var)
  }
  std = std/m
  mini_ess = floor(4*pi*qchisq(1-alpha, df = 1)/((gamma(0.5))^2*eps*eps))
  mini_multi_ess = floor(2^(2/p)*pi*qchisq(1-alpha, df = p)/((p*gamma(0.5*p))^(2/p)*eps*eps))
  statistics <-  matrix(0,ncol = 7, nrow = p)
  statistics[ ,1] <- round(apply(stacked,2,mean),4)
  statistics[ ,3] <- round(sqrt(std),4)
  statistics[ ,2] <- (round(mcmcse::mcse.mat(stacked,size = Batch_Size), 5))[ ,2]
  mp_ess <- mcmcse::multiESS(stacked, size = Batch_Size)
  foo <- p*log(mp_ess/n)
  ms <- cov(chains[[1]])
  if(m>1)
  {
    for(i in 2:m)
    {
      ms <- ms + cov(chains[[i]])
    }
  }
  ms <- ms/m
  correction <- sum(log(eigen(ms, symmetric = TRUE, 
                              only.values = TRUE)$values)) - sum(log(eigen(cov(stacked), symmetric = TRUE, 
                                                                           only.values = TRUE)$values))
  foo <- (foo + correction)/p
  n_ess <- n*exp(foo)
  multiess <- floor(n_ess)
  multigelmann <- round(sqrt((n-1)/n + m/n_ess),5)
  
  s <- vector(length = p)
  for(i in 1:p)
  {
    ms <- var(chains[[1]][,i])
    if(m>1)
    {
      for(j in 2:m)
      {
        ms <- ms + var(chains[[j]][,i])
      }
    }
    s[i] <- ms
  }
  varquant <- round(rbind(t(apply(stacked, 2, quantile, Q))), 3)
  
  s <- s/m
  statistics[ ,4] <- varquant[ ,1]
  statistics[ ,5] <- varquant[ ,2]
  statistics[ ,6] <- s/(statistics[ ,2]^2)
  statistics[ ,7] <- round(sqrt(1 + m/statistics[ ,6]),5)
  statistics[ ,6] <- floor(statistics[ ,6])
  statistics <- as.data.frame(statistics)
  Signif.= ifelse( test = statistics[,6] >= mini_ess, yes = '*', no = '')
  statistics = cbind(statistics, Signif.)
  stacked_rows <- dim(stacked)[1]
  colnames(statistics) <- colname
  rownames(statistics) <- dimen
  statistics <- drop(statistics)
  summary_list <- list(nsim = n,
                       Dimensions = p,
                       no.chains = m,
                       Batch_Size = Batch_Size,
                       stacked_rows = stacked_rows,
                       nbatch = stacked_rows/Batch_Size,
                       nbatch_per_chain = stacked_rows/(Batch_Size*m),
                       Statistics = statistics,
                       MultiESS = multiess,
                       MultiGelmann = multigelmann,
                       mini_ESS = mini_ess,
                       mini_multi_ESS = mini_multi_ess)
  class(summary_list) <- "summary.Smcmc"
  return(summary_list)
}




#'@rdname summary.Smcmc
#' @param x : summary.Smcmc output
#' @param ... : Other arguments
#'@export

"print.summary.Smcmc" <-function (x, ...) 
{
  cat("\n", "No. of Iterations = ",x$nsim,"\n", sep = "")
  cat("No. of Components = ",x$Dimensions,"\n", sep = "")
  cat("No. of Chains = ",x$no.chains,"\n", sep = "")
  cat("Number of Iterations Considered =",x$stacked_rows, "\n" )
  cat("\nNote : ESS calculations are based on estimation of means.","\n",sep = "")
  cat("       There is a one-to-one relationship between ESS and Gelman-Rubin.","\n",sep = "")
  cat("       Reporting either is equivalent to the other, we recommend ESS.", "\n", sep = "")
  cat("\nSummary for Each Variable :\n")
  print(x$Statistics, ...)
  cat("\n")
  cat("Multivariate ESS =", x$MultiESS)
  a = x$mini_multi_ESS
  b = x$MultiESS
  if(b >= a){cat(" ***\n")}else{cat("\n")}
  cat("Multivariate Gelman-Rubin =", x$MultiGelmann)
  cat("\nNote : * indicates desired quality for this component has been achieved\n")
  cat("       *** indicates desired multivariate quality has been achieved.\n")
  cat("\n")
  cat("For Given alpha & epsilon :","\n",sep="")
  cat("Minimum ESS for Each Component =",x$mini_ESS)
  cat("\nMinimum Mutltivariate ESS =",x$mini_multi_ESS)
  cat("\n")
  invisible(x)
}





#' @title Covert to Smcmc Object
#'
#' @description To covert different MCMC objects to Smcmc object
#'
#' @name convert2Smcmc
#' @usage convert2Smcmc(x)    
#' @param x : a object belongs from any of "mcmc.list", "stanfit", "rstan", "array", "matrix" classes.
#' @return return Smcmc object having same chain(s)
#'
#'@export

convert2Smcmc <- function(x)
{
  if("mcmc.list"%in%class(x))
  {
    temp = list(as.matrix(x[[1]]))
    
    for(i in 2:length(x))
    {
      append(temp,as.matrix(x[[i]]))
    }
    return(as.Smcmc(temp))
  }
  
  else if("stanfit"%in%class(x) || "rstan"%in%class(x))
  {
    foo <- x@sim$samples
    f1 <- foo[[1]]
    s <- length(f1)
    f1 <- f1[-s]
    samp <- Reduce('cbind', f1)
    dim(foo[[1]])[1]
    n = dim(Reduce('cbind',(foo[[1]])))[1]
    perm = x@sim$permutation
    chains = list()
    for(i in 1:length(perm))
    {
      chain =  as.matrix(Reduce('cbind',(foo[[i]]))[(n-length(perm[[i]])):n, ])
      chains[[i]] = chain
    }
    return(as.Smcmc(chains))
  }
  
  else if("array"%in%class(x) || "matrix"%in%class(x) ||"list"%in%class(x))
  {
    return(as.Smcmc(x))
  }
}


