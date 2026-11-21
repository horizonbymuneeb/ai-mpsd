
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Adatum Ops Panel'
$form.Size = New-Object System.Drawing.Size(860, 540)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = "Probe"
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'WinRM' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
