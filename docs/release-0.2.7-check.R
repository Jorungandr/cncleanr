# Rscript --vanilla docs/release-0.2.7-check.R
.libPaths(c('outputs/release-0.2.7/library', .libPaths()))
library(cncleanr)
stopifnot(as.character(packageVersion('cncleanr')) == '0.2.7')
result <- parse_cn_quantity('约15％左右', strict=TRUE)
stopifnot(result$value == .15, result$qualifier == 'approx')
for (input in c('约超过15%', '约约15%左右', '31%±16%')) {
  stopifnot(nrow(cn_problems(suppressWarnings(parse_cn_quantity(input)))) == 1L)
}
rd <- tools::Rd_db('cncleanr')[['parse_cn_quantity.Rd']]
stopifnot(grepl('approximation suffix', paste(capture.output(tools::Rd2txt(rd)),
                                           collapse='\n'), fixed=TRUE))
for (function_name in c('parse_cn_number', 'parse_cn_quantity', 'parse_cn_range')) {
  example(function_name, package='cncleanr', ask=FALSE, character.only=TRUE)
}
cat('PASS: installed 0.2.7 behavior, help and examples\n')
