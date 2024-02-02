[System.Security.Principal.WindowsIdentity]::GetCurrent().Name  | Out-File -FilePath "C:\Users\Public\CustomA.txt"
throw "You've got to be joking"