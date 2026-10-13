param(
    [string]$Executable = '',
    [switch]$RawEnvironment,
    [string[]]$RArguments = @()
)
$ErrorActionPreference = 'Stop'
if (!$Executable) {
    $taskRscript = Get-Command Rscript.exe -ErrorAction SilentlyContinue
    if (!$taskRscript) { throw 'Rscript.exe is not on PATH. Pass -Executable with its full path.' }
    $Executable = $taskRscript.Source
}
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
