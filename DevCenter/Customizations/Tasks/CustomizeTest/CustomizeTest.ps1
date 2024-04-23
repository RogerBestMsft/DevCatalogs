
gpresult /r /scope:computer | Out-File -FilePath "C:\Users\Public\CustomAA3.txt"

Start-Sleep -Seconds 180
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name  | Out-File -FilePath "C:\Users\Public\CustomA3.txt"
#Get-Process | Out-File -FilePath "C:\Users\Public\DEFProcess.txt"
Get-WmiObject -Class Win32_Product | Out-File -FilePath "C:\Users\Public\CustomB3.txt"

Get-AppxPackage -AllUsers | Out-File -FilePath "C:\Users\Public\CustomC3.txt"

Get-Date | Out-File -FilePath "C:\Users\Public\CustomD3.txt"

gpresult /r /scope:computer | Out-File -FilePath "C:\Users\Public\CustomBB3.txt"