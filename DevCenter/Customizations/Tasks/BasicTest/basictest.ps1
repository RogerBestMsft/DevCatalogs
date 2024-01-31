[System.Security.Principal.WindowsIdentity]::GetCurrent().Name  | Out-File -FilePath "C:\Users\Public\CustomA.txt"
#Get-Process | Out-File -FilePath "C:\Users\Public\DEFProcess.txt"
Get-WmiObject -Class Win32_Product | Out-File -FilePath "C:\Users\Public\CustomB.txt"