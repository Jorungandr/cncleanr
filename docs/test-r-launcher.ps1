param([string]$Rscript = 'D:/R/R-4.6.1/bin/Rscript.exe')
$ErrorActionPreference = 'Stop'
$taskOriginalArchitecture = $env:PROCESSOR_ARCHITECTURE
try {
    Remove-Item Env:PROCESSOR_ARCHITECTURE -ErrorAction SilentlyContinue
    & "$PSScriptRoot/run-r.ps1" -Executable $Rscript -RArguments @('--vanilla', '-e', 'stopifnot(nzchar(Sys.getenv("PROCESSOR_ARCHITECTURE")))')
    if ($LASTEXITCODE -ne 0 -or (Test-Path Env:PROCESSOR_ARCHITECTURE)) { throw 'Missing environment repair/restoration failed.' }
    $env:PROCESSOR_ARCHITECTURE = 'preserve-existing-value'
    & "$PSScriptRoot/run-r.ps1" -Executable $Rscript -RArguments @('--vanilla', '-e', 'stopifnot(Sys.getenv("PROCESSOR_ARCHITECTURE") == "preserve-existing-value"); quit(status=7)')
    if ($LASTEXITCODE -ne 7 -or $env:PROCESSOR_ARCHITECTURE -ne 'preserve-existing-value') { throw 'Exit code or existing environment was not preserved.' }
    Remove-Item Env:PROCESSOR_ARCHITECTURE
    & "$PSScriptRoot/run-r.ps1" -Executable $Rscript -RawEnvironment -RArguments @('--vanilla', '-e', 'stopifnot(Sys.getenv("PROCESSOR_ARCHITECTURE") == "")')
    if ($LASTEXITCODE -ne 0 -or (Test-Path Env:PROCESSOR_ARCHITECTURE)) { throw 'Raw environment mode failed.' }
} finally {
    $env:PROCESSOR_ARCHITECTURE = $taskOriginalArchitecture
}
Write-Output 'R launcher checks passed.'
