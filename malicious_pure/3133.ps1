
<# Host profiling #> $FetchUrl = "https://localhost:8080/update.dat"; $OutputPath = 'C:\ProgramData\update.dat'; curl.exe -s -L -o $OutputPath $FetchUrl; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $Host.UI.RawUI.WindowTitle = "Windows Update"
