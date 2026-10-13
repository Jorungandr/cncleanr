# Shared by current audit entry points; run from the repository root.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[[1L]], mustWork = TRUE), .libPaths()))
library(cncleanr)
version <- as.character(packageVersion('cncleanr'))
expected_version <- read.dcf('DESCRIPTION')[1L, 'Version']
if (version != expected_version)
  stop('Audit loaded cncleanr ', version, '; checkout requires ', expected_version,
       '. Install this checkout and pass its library path explicitly.')
cat('Auditing cncleanr', version, 'from', find.package('cncleanr'), '\n')
