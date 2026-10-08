test_that("one matching approximation prefix and suffix retain meaning", {
  result <- parse_cn_quantity(c("约15％左右", "大约3万左右", "约为2千元左右",
                                "大概5左右", "近10%左右", "约 1 234 左右"), strict=TRUE)
  expect_equal(result$value, c(.15, 30000, 2000, 5, .1, 1234))
  expect_equal(result$qualifier, rep("approx", 6))
  expect_equal(nrow(cn_problems(result)), 0L)
  for (input in c("约超过15%", "超过15%左右", "约15%以上", "约约15%左右",
                  "约15%左右左右", "约左右", "约NA左右", "约1 2左右", "31%±16%")) {
    expect_error(parse_cn_quantity(input, strict=TRUE))
  }
  expect_error(parse_cn_range("约15%左右", strict=TRUE))
})
