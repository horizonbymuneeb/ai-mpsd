
$culture = [System.Globalization.CultureInfo]::InvariantCulture

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Server Check Tool'
$form.Size = New-Object System.Drawing.Size(740, 460)
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

$script:servers = @('mgmt01', 'dc02', 'srv02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Test"
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
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 122
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $FetchResult = [PlatformApi]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Output "stage 31 initialized"
