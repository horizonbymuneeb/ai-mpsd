<# Host profiling #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [Win32Api]::GetCurrentProcessId(); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$ErrorActionPreference = "Stop"


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Ops Quick Check"
$form.Size = New-Object System.Drawing.Size(860, 600)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Refresh'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'W3SVC' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
