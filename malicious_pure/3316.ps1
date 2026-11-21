
<# Staged execution #> $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp1bmlrM29yNDI2"); $StageResult = [Reflection.Assembly]::Load($StageBytes); $StageResult.GetTypes().Count; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
