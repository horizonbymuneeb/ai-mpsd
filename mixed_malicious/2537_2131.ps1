
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\payload.ps1
#>
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $ResultObject)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$StageMarker = "stage-6"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Infra Status Board"
$form.Size = New-Object System.Drawing.Size(740, 520)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Test'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'MSSQLSERVER' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
