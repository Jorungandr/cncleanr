param(
    [string]$Executable = 'D:/R/R-4.6.1/bin/Rscript.exe',
    [switch]$RawEnvironment,
    [string[]]$RArguments = @()
)
$ErrorActionPreference = 'Stop'
$taskOriginalArchitecture = $env:PROCESSOR_ARCHITECTURE
try {
    # cli 3.6.6 does not guard getenv() before strcmp() during Windows cleanup.
    if (!$RawEnvironment -and !$env:PROCESSOR_ARCHITECTURE) {
        $taskArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        $env:PROCESSOR_ARCHITECTURE = switch ($taskArchitecture) {
            'X64' { 'AMD64' }
            'X86' { 'x86' }
            'Arm64' { 'ARM64' }
            default { throw "Unsupported Windows architecture: $taskArchitecture" }
        }
    }
    & $Executable @RArguments
    $taskExitCode = $LASTEXITCODE
} finally {
    $env:PROCESSOR_ARCHITECTURE = $taskOriginalArchitecture
}
exit $taskExitCode
