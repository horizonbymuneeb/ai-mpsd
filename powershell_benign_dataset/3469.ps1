$InformationPreference = 'SilentlyContinue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$culture = [System.Globalization.CultureInfo]::InvariantCulture

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Desk Helper'
$form.Size = New-Object System.Drawing.Size(700, 540)
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

$script:servers = @('app-prod-01', 'srv01', 'dc02', 'srv02', 'sql-prod-02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Desk Helper'
$form.Size = New-Object System.Drawing.Size(700, 540)
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

$script:servers = @('app-prod-01', 'srv01', 'dc02', 'srv02', 'sql-prod-02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)
$button = New-Object System.Windows.Forms.Button
$button.Text = 'Check'
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

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(18, 96)
$grid.Size = New-Object System.Drawing.Size(700, 300)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AutoSizeColumnsMode = 'Fill'
$form.Controls.Add($grid)

$table = New-Object System.Data.DataTable
[void]$table.Columns.Add('Server')
[void]$table.Columns.Add('Status')
[void]$table.Columns.Add('CheckedAt')
foreach ($server in $script:servers) {
    [void]$table.Rows.Add($server, 'Unknown', (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
}
$grid.DataSource = $table

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = 'Export CSV'
$saveButton.Location = New-Object System.Drawing.Point(18, 410)
$saveButton.Size = New-Object System.Drawing.Size(120, 28)
$saveButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = 'CSV files (*.csv)|*.csv'
    $dialog.FileName = "server-check.csv"
    if ($dialog.ShowDialog() -eq 'OK') {
        $table | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8
        $statusLabel.Text = 'Exported'
    }
})
$form.Controls.Add($saveButton)

$menu = New-Object System.Windows.Forms.MenuStrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = 'File'
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = 'Exit'
$exitItem.Add_Click({ $form.Close() })
[void]$fileMenu.DropDownItems.Add($exitItem)
[void]$menu.Items.Add($fileMenu)
$form.Controls.Add($menu)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 120000
$timer.Add_Tick({
    $statusLabel.Text = 'Last refresh: ' + (Get-Date).ToString('HH:mm:ss')
})
$timer.Start()

$form.Add_Shown({ $textBox.Focus() })
[void]$form.ShowDialog()
$form.Dispose()

Write-Host ("Console closed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($textBox, 'Enter a short host name such as srv01.')
$toolTip.SetToolTip($button, 'Runs the connectivity check.')

$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = 'About'
$aboutItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show('Contoso operations helper', 'About')
})

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(18, 410)
$progress.Size = New-Object System.Drawing.Size(660, 18)
$form.Controls.Add($progress)
