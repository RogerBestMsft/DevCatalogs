Get-Process | Out-File -FilePath $Env:PUBLIC\ZZZ1Process.txt
(New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1') | Out-File -FilePath $Env:PUBLIC\choco.txt