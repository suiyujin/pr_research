## 平滑化用関数
MW <- function(dat, width, na.rm = TRUE) {
  N <- length(dat)
  x <- numeric(N)
  for(i in 1L:(width-1L)) {
    x[i] <- mean(dat[1L:i], na.rm = na.rm)
  }
  for(i in width:N) {
    x[i] <- mean(dat[(i-width+1L):i], na.rm = na.rm)
  }
  return(x)
}
## 擬似逆行列計算用関数（MASSパッケージより）
ginv <- function (X, tol = sqrt(.Machine$double.eps)) {
  if (length(dim(X)) > 2L || !(is.numeric(X) || is.complex(X))) 
    stop("'X' must be a numeric or complex matrix")
  if (!is.matrix(X)) 
    X <- as.matrix(X)
  Xsvd <- svd(X)
  if (is.complex(X)) 
    Xsvd$u <- Conj(Xsvd$u)
  Positive <- Xsvd$d > max(tol * Xsvd$d[1L], 0)
  if (all(Positive)) 
    Xsvd$v %*% (1/Xsvd$d * t(Xsvd$u))
  else if (!any(Positive)) 
    array(0, dim(X)[2L:1L])
  else Xsvd$v[, Positive, drop = FALSE] %*% ((1/Xsvd$d[Positive]) * t(Xsvd$u[, Positive, drop = FALSE]))
}

SDAR1 <- function(x, ar_order, forgetting, mu = 0, co = numeric(ar_order+1), w = numeric(ar_order), S = 0) {
  N <- length(x)
  score <- numeric(N)
  for(t in (ar_order+1L):N) {
    mu <- (1-forgetting)*mu + forgetting*x[t]
    co <- (1-forgetting)*co + forgetting*(x[t]-mu)*(x[t-(0:ar_order)]-mu)
    w <- c(ginv(matrix(co[abs(rep(1:ar_order, ar_order)-rep(1:ar_order, each=ar_order))+1], ar_order, ar_order)) %*% co[-1])
    x_hat <- c(w %*% (x[t-(1:ar_order)]-mu)) + mu
    S <- (1-forgetting)*S + forgetting*(x[t]-x_hat)^2
    score[t] <- (log(2*pi*S) + (x[t] - x_hat)^2 / S) / 2
  }
  list(Score = score, x = x)
}

CF <- function(x, ar_order, forgetting, width1, width2 = width1, na.rm = TRUE) {
  Step1 <- SDAR1(x, ar_order, forgetting)$Score
  Step2 <- MW(Step1, width1, na.rm)
  Step3 <- MW(SDAR1(Step2, ar_order, forgetting)$Score, width2, na.rm)
  return(Step3)
}