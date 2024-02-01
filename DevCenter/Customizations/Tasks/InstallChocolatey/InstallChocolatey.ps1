
function Execute
{
    [CmdletBinding()]
    param(
        $File
    )

    # Note we're calling powershell.exe directly, instead
    # of running Invoke-Expression, as suggested by
    # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/avoid-using-invoke-expression?view=powershell-7.3
    # Note that this will run powershell.exe
    # even if the system has pwsh.exe.
    powershell.exe -File $File

    # capture the exit code from the process
    $processExitCode = $LASTEXITCODE

    # This check allows us to capture cases where the command we execute exits with an error code.
    # In that case, we do want to throw an exception with whatever is in stderr. Normally, when
    # Invoke-Expression throws, the error will come the normal way (i.e. $Error) and pass via the
    # catch below.
    if ($processExitCode -or $expError)
    {
        if ($processExitCode -eq 3010)
        {
            # Expected condition. The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.
        }
        elseif ($expError)
        {
            throw $expError
        }
        else
        {
            throw "Installation failed with exit code: $processExitCode. Please see the Chocolatey logs in %ALLUSERSPROFILE%\chocolatey\logs folder for details."
            break
        }
    }
}
###################################################################################################
#
# PowerShell configurations
#

# Ensure we force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host 'Ensuring latest Chocolatey version is installed.'
Set-ExecutionPolicy Bypass -Scope Process -Force
$installScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -OutFile $installScriptPath

try {
    Execute -File $installScriptPath
} finally {
    Remove-Item $installScriptPath
}

if ($LastExitCode -eq 3010)
{
    Write-Host 'The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.'
    #Restart-Computer -Force
}

Write-Host "`nChocolatey was installed successfully.`n"