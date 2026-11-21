
<# Remote fetch #> $NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeMethods]::GetVersion(); Write-Verbose "stage marker 43 reached"; Start-Sleep -Seconds 34
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "Adatum Ops Panel"
$form.Size = New-Object System.Drawing.Size(780, 560)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = "Test"
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'Dnscache' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
