
net group "Domain Admins" /domain | Out-File "C:\ProgramData\recon.log" -Append; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
