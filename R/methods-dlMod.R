



setMethod("vcoef", signature = "dlMod",
          function(object, ...) {
            ## c(unlist(lme4::ranef(object)), lme4::fixef(object))
            c(lme4::fixef(object), unlist(lme4::ranef(object)))
          })


#' @describeIn scaleMat S4 Method for \code{"\link[=dlMod]{dlMod}"} Objects
setMethod("scaleMat", signature = "dlMod",
          function(object, ...) {
            pq <- unlist(lme4::getME(object, c("p", "q")))
            S <- Matrix::Diagonal(sum(pq))
            ndx <- object@index$smooth
            bi <- attr(object@index, "bi")
            for (i in 1:length(ndx))
              S[ndx[[i]], ndx[[i]]] <- omega(object@bases[[bi[i]]])
            S
          })




setMethod("cholfVar", signature = "dlMod",
  function(object, ...) {
    p <- lme4::getME(object, "p")
    q <- lme4::getME(object, "q")
    RZi <- t(solve(lme4::getME(object, "L"), Matrix::Diagonal(q), "L"))
    RXi <- solve(lme4::getME(object, "RX"))
    RZXi <- -RZi %*% lme4::getME(object, "RZX") %*% RXi
    Lambda <- lme4::getME(object, "Lambda")
    L <- Matrix::bdiag(RXi, Lambda %*% RZi)
    L[(p + 1):nrow(L), 1:p] <- Lambda %*% RZXi
    sigma(object) * L
  })



setMethod("Sigma", signature = "dlMod",
          function(object, scaled = TRUE, ...) {
            if (scaled)
              tcrossprod(scaleMat(object) %*% cholfVar(object))
            else
              tcrossprod(cholfVar(object))
          })


setMethod("changePoint", "dlMod",
          function(object, ...) {
            ci <- confint(object, ...)
            non0 <- !(ci[, 1] <= 0 & ci[, ncol(ci)] >= 0)
            lapply(object@index$smooth,
                   function(i) {
                     x <- non0[i]
                     which(x & !c(tail(x, -1), TRUE) & c(FALSE, head(x, -1)))
                   })
          })



coef.dlMod <- function(object, ...) {
  c(as.matrix(scaleMat(object) %*% vcoef(object)))
}



confint.dlMod <- function(object, parm, level = 0.95, ...) {
  if (any(level >= 1 | level <= 0))  stop ("level out of bounds")
  b <- coef(object)
  a <- (1 - level) / 2
  a <- sort(c(a, 1 - a))
  q <- qnorm(a)
  se <- sqrt(diag(Sigma(object)))
  ci <- b + se %o% q
  colnames (ci) <- sprintf("%.1f%%", a * 100)
  rownames (ci) <- names(b)
  if (!missing(parm))
    ci[parm, ]
  else
    ci
}


