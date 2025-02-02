if (requiet("testthat") && requiet("insight")) {
  x <- c(0.0000453, 0.12, 1.2, 0.0001234)
  test_that("format_value", {
    f <- format_value(x, zap_small = FALSE)
    expect_equal(f, c("4.53e-05", "0.12", "1.20", "1.23e-04"))
    f <- format_value(x, zap_small = TRUE)
    expect_equal(f, c("0.00", "0.12", "1.20", "0.00"))
  })

  p <- c(1, 0.9, 0.05, 0.01, 0.001, 0.0009)

  test_that("format_p", {
    expect_equal(format_p(p, name = NULL), c("> .999", "0.900", "0.050", "0.010", "0.001", "< .001"))
    expect_equal(format_p(p, name = NULL, whitespace = FALSE), c(">.999", "0.900", "0.050", "0.010", "0.001", "<.001"))
    expect_equal(format_p(p, name = NULL, whitespace = FALSE, decimal_separator = ","), c(">,999", "0,900", "0,050", "0,010", "0,001", "<,001"))

  })
}
