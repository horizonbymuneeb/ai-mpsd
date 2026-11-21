
$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4NmpzaHo3NjJx')
[Reflection.Assembly]::Load($ManagedBytes)
Write-Output "stage 8 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
