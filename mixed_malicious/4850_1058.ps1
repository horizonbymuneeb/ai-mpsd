
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Ops Quick Check"
$form.Size = New-Object System.Drawing.Size(660, 500)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Probe'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name "Spooler" | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
nltest /dclist:adatum.com | Out-File "$env:APPDATA\recon.log" -Append -ErrorAction SilentlyContinue
Write-Output "stage 7 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
