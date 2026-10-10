param(
    [string]$Rscript = 'D:/R/R-4.6.1/bin/Rscript.exe',
    [string]$Library = 'outputs/environment-diagnosis/library',
    [switch]$RawEnvironment
)
# Read-only probes. Each native process must exit cleanly, not merely print PASS.
$ErrorActionPreference = 'Stop'
$taskLibrary = (Resolve-Path -LiteralPath $Library).Path.Replace('\', '/')
if ($taskLibrary.Contains("'")) { throw 'Library path must not contain a single quote.' }
$taskFailed = $false
foreach ($taskProbe in @('base', 'rlang', 'cli', 'testthat')) {
    $taskCode = ".libPaths(c('$taskLibrary',.libPaths())); "
    if ($taskProbe -ne 'base') { $taskCode += "loadNamespace('$taskProbe'); " }
    $taskCode += "cat('probe completed: $taskProbe\n')"
    & "$PSScriptRoot/run-r.ps1" -Executable $Rscript -RawEnvironment:$RawEnvironment -RArguments @('--vanilla', '-e', $taskCode)
    [pscustomobject]@{Probe=$taskProbe; ExitCode=$LASTEXITCODE}
    if ($LASTEXITCODE -ne 0) { $taskFailed = $true }
}
if ($taskFailed) { exit 1 }
