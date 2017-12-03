



plot.dlMod <- function(x, y, geom = c("pointrange", "line"), ...) {
  geom <- match.arg(geom)
  ci <- confint(x, ...)
  ci <- ci[, c(1, ncol(ci))]
  invisible (0)
}
