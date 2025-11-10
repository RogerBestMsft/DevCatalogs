# Test WinGet functionality and log source list output
param(
    [string]$LogPath = "C:\temp\winget-test.log"
)

# Function to write timestamped log entries
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console
    Write-Host $logEntry
    
    # Write to log file
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

try {
    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Write-Log "Starting WinGet source list test"
    
    # Check if winget is available
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Log "WinGet is not installed or not found in PATH" "ERROR"
        exit 1
    }
    
    Write-Log "WinGet found at: $($wingetPath.Source)"
    
    # Execute winget source list command
    Write-Log "Executing 'winget source list' command..."
    
    $sourceListOutput = & winget source list 2>&1
    $exitCode = $LASTEXITCODE
    
    # Log the exit code
    Write-Log "WinGet source list command completed with exit code: $exitCode"
    
    if ($exitCode -eq 0) {
        Write-Log "WinGet source list output:" "INFO"
        
        # Log each line of output
        foreach ($line in $sourceListOutput) {
            Write-Log "  $line"
        }
        
        # Count the number of sources
        $sourceCount = ($sourceListOutput | Where-Object { $_ -match "^[^-\s].*\s+https?://" }).Count
        Write-Log "Total sources found: $sourceCount"
        
    } else {
        Write-Log "WinGet source list command failed" "ERROR"
        foreach ($line in $sourceListOutput) {
            Write-Log "  ERROR: $line" "ERROR"
        }
    }
    
    Write-Log "WinGet source list test completed"
    
} catch {
    Write-Log "An error occurred: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}