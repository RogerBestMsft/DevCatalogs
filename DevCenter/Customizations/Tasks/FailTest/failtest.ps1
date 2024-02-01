[System.Security.Principal.WindowsIdentity]::GetCurrent().Name  | Out-File -FilePath "C:\Users\Public\CustomA.txt"
return -1