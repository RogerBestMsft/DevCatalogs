#Get-Process | Out-File -FilePath "C:\Users\Public\DEFProcess.txt"
(New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1') | Out-File -FilePath "C:\Users\Public\installchoco.ps1"