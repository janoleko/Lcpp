#' Calculate all transition probability matrices
#' 
#' In an HMM, we can model the influence of covariates on the state process, by linking them to the transition probabiltiy matrix. 
#' Most commonly, this is done by specifying a linear predictor \cr \cr
#' \eqn{ \eta_{ij}^{(t)} = \beta^{(ij)}_0 + \beta^{(ij)}_1 z_{t1} + \dots + \beta^{(ij)}_p z_{tp} } \cr \cr
#' for each off-diagonal element (\eqn{i \neq j}) and then applying the inverse multinomial logistic link to each row.
#' This function efficiently calculates all transition probabilty matrices for a given design matrix \eqn{Z} and parameter matrix.
#'
#' @param Z Covariate design matrix (excluding intercept column) of dimension c(n, p)
#' @param beta matrix of coefficients for the off-diagonal elements of the transition probability matrix.
#' Needs to be of dimension c(N*(N-1), p+1), where the first column contains the intercepts.
#'
#' @return Array of transition probability matrices of dimension c(N,N,n)
#' @export
#'
#' @examples
#' n = 1000
#' Z = matrix(runif(n*2), ncol = 2)
#' beta = matrix(c(-1, 1, 2, -2, 1, -2), nrow = 2, byrow = TRUE)
#' Gamma = tpm_g(Z, beta)
tpm_g = function(Z, beta){
  Z = cbind(1, Z) # adding intercept column
  K = nrow(beta)
  # for N > 1: N*(N-1) is bijective with solution
  N = as.integer(0.5 + sqrt(0.25+K), 0)
  tpm_g_cpp(Z, beta, N)
}

