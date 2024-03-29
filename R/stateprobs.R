#' Calculate conditional local state probabilities for homogeneous HMMs
#' 
#' Computes \cr \cr
#' \eqn{\Pr(S_t = j \mid X_1, ..., X_T)} \cr \cr
#'
#' @param delta Initial or stationary distribution of length N
#' @param Gamma Transition probability matrix of dimension c(N,N)
#' @param allprobs Matrix of state-dependent probabilities/ density values of dimension c(n, N)
#'
#' @return Matrix of conditional state probabilities of dimension c(n,N)
#' @export
#'
#' @examples
#' Gamma = tpm(c(-1,-2))
#' delta = stationary(Gamma)
#' allprobs = matrix(runif(200), nrow = 100, ncol = 2)
#' 
#' probs = stateprobs(delta, Gamma, allprobs)
stateprobs = function(delta, Gamma, allprobs){
  n = nrow(allprobs)
  N = ncol(allprobs)
  Gammanew = array(Gamma, dim = c(N,N,n-1))
  
  lalpha = logalpha_cpp(allprobs, delta, Gammanew)
  lbeta = logbeta_cpp(allprobs, Gammanew)

  c = max(lalpha[n,])
  llk = c + log(sum(exp(lalpha[n,]-c)))
  
  probs = exp(lalpha + lbeta - llk)

  # rowsums should already be one
  probs = probs / rowSums(probs)
  return(probs)
}