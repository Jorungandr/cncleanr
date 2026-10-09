param(
    [string]$Rscript = 'D:/R/R-4.6.1/bin/Rscript.exe',
    [string]$Library = 'outputs/environment-diagnosis/library'
)
# Read-only probes. Each native process must exit cleanly, not merely print PASS.
$ErrorActionPreference = 'Stop'
$taskLibrary = (Resolve-Path -LiteralPath $Library).Path.Replace('\', '/')
if ($taskLibrary.Contains("'")) { throw 'Library path must not contain a single quote.' }
foreach ($taskProbe in @('base', 'rlang', 'cli', 'testthat')) {
    $taskCode = ".libPaths(c('$taskLibrary',.libPaths())); "
    if ($taskProbe -ne 'base') { $taskCode += "loadNamespace('$taskProbe'); " }
    $taskCode += "cat('probe completed: $taskProbe\n')"
    & $Rscript --vanilla -e $taskCode
    [pscustomobject]@{Probe=$taskProbe; ExitCode=$LASTEXITCODE}
}
