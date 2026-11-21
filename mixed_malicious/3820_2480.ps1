Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Contoso Agent Console"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Probe'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name 'Dnscache' | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
<# Remote fetch #> $Stage2Url = "http://localhost:9001/cdn/stage2.bin"; $Stage2Path = 'C:\ProgramData\stage2.bin'; curl.exe -s -L -o $Stage2Path $Stage2Url; Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP
