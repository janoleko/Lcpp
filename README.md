
# {Lcpp}: Forward algorithm in C++ <img src="man/figures/Lcpp_logo_new.png" align="right" height=170>

This package provides convenient **R** wrapper functions for the
**forward algorithm** used to fit **hidden Markov models** (HMMs),
**hidden semi-Markov models** (HSMMs) and **state space models** (SSMs)
via **direct numerical maximum likelihood estimation**. The algorithm
calculates the log-likelihood recursively as a matrix product and uses a
scaling strategy to avoid numerical underflow (for details see [Zucchini
et
al. 2016](https://www.taylorfrancis.com/books/mono/10.1201/b20790/hidden-markov-models-time-series-walter-zucchini-iain-macdonald-roland-langrock)).
Implementation in **C++** offers 10-20 times faster evaluation times,
thus substantially speeding up estimation by e.g. `nlm()` or `optim()`.
Current implementations include

- `forward()` for models with **homogeneous** transition probabilities,
- `forward_g()` for general (pre-calculated) **inhomogeneous**
  transition probabilities (including **continuous-time** HMMs),
- `forward_p()` which is more efficient than the general implementation,
  when transition probabilities only vary **periodically**, and
- `forward_s()` for fitting **HSMMs**.

The functions are built to be included in the **negative log-likelihood
function**, after parameters have been transformed and the *allprobs*
matrix (containing all state-dependent probabilities) has been
calculated.

In addition to providing fast and easy to use versions of the **forward
algorithm**, this package is supposed to be a toolbox for flexible and
fast model building. Thus, it contains auxiliary functions for building
HMM-like models. Currently these include:

- The `tpm` family with

  - `tpm()` for calculating a homogeneous transition probability matrix
    via the multinomial logistic link,
  - `tpm_g()` for calculating general inhomogeneous transition
    probabilty matrices,
  - `tpm_p()` for calculating transition matrices of periodically
    inhomogeneous HMMs,
  - `tpm_cont()` for calculating the transition probabilites of a
    continuous-time Markov chain,
  - `tpm_hsmm()` for calculating the transition matrix of an
    HSMM-approximating HMM, and
  - `tpm_phsmm()` for calculating transition matrices of a
    periodic-HSMM-approximating HMM.

- The `stationary()` family to compute stationary and periodically
  stationary distributions.

- `trigBasisExp()` for efficient computation of a trigonometric basis
  expansion.

Further functionalities will be added as needed. Have fun!

## Installation

To install and use the package, you need to have a functional C++
compiler. For details click
[here](https://teuder.github.io/rcpp4everyone_en/020_install.html). Then
you can use:

``` r
# install.packages("devtools")
devtools::install_github("janoleko/Lcpp", build_vignettes = TRUE)
```

Feel free to use

``` r
browseVignettes("Lcpp")
```

for detailed examples on how to use the package.

## Example: Homogeneous HMM

#### Loading the package

``` r
library(Lcpp)
```

#### Generating data from a 2-state HMM

Here we can use `stationary()` to compute the stationary distribution.

``` r
# parameters
mu = c(0, 6)
sigma = c(2, 4)
Gamma = matrix(c(0.95, 0.05, 0.15, 0.85), nrow = 2, byrow = TRUE)
delta = stationary(Gamma) # stationary HMM

# simulation
n = 10000 # rather large
set.seed(123)
s = x = rep(NA, n)
s[1] = sample(1:2, 1, prob = delta)
x[1] = stats::rnorm(1, mu[s[1]], sigma[s[1]])
for(t in 2:n){
  s[t] = sample(1:2, 1, prob = Gamma[s[t-1],])
  x[t] = stats::rnorm(1, mu[s[t]], sigma[s[t]])
}

plot(x[1:200], bty = "n", pch = 20, ylab = "x", 
     col = c("orange","deepskyblue")[s[1:200]])
```

<img src="man/figures/README-data-1.png" width="75%" style="display: block; margin: auto;" />

#### Writing the negative log-likelihood function

Here, we build the transition probability matrix using the `tpm()`
function, compute the stationary distribution using `stationary()` and
calculate the log-likelihood using `forward()` in the last line.

``` r
mllk = function(theta.star, x){
  # parameter transformations for unconstraint optimization
  Gamma = tpm(theta.star[1:2])
  delta = stationary(Gamma) # stationary HMM
  mu = theta.star[3:4]
  sigma = exp(theta.star[5:6])
  # calculate all state-dependent probabilities
  allprobs = matrix(1, length(x), 2)
  for(j in 1:2){ allprobs[,j] = stats::dnorm(x, mu[j], sigma[j]) }
  # return negative for minimization
  -forward(delta, Gamma, allprobs)
}
```

#### Fitting an HMM to the data

``` r
theta.star = c(-1,-1,1,4,log(1),log(3)) 
# initial transformed parameters: not chosen too well
s = Sys.time()
mod = stats::nlm(mllk, theta.star, x = x)
Sys.time()-s
#> Time difference of 0.1084609 secs
```

Really fast for 10.000 data points!

#### Visualizing results

Again, we use `tpm()` and `stationary()` to tranform the unconstraint
parameters to working parameters.

``` r
# transform parameters to working
Gamma = tpm(mod$estimate[1:2])
delta = stationary(Gamma) # stationary HMM
mu = mod$estimate[3:4]
sigma = exp(mod$estimate[5:6])

hist(x, prob = TRUE, bor = "white", breaks = 40, main = "")
curve(delta[1]*dnorm(x, mu[1], sigma[1]), add = TRUE, lwd = 2, col = "orange", n=500)
curve(delta[2]*dnorm(x, mu[2], sigma[2]), add = TRUE, lwd = 2, col = "deepskyblue", n=500)
curve(delta[1]*dnorm(x, mu[1], sigma[1])+delta[2]*dnorm(x, mu[2], sigma[2]),
      add = TRUE, lwd = 2, lty = "dashed", n=500)
legend("topright", col = c("orange", "deepskyblue", "black"), lwd = 2, bty = "n",
       lty = c(1,1,2), legend = c("state 1", "state 2", "marginal"))
```

<img src="man/figures/README-visualization-1.png" width="75%" style="display: block; margin: auto;" />
