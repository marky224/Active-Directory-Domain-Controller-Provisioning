# 03-Install-ADDSRole.ps1
# Installs AD DS role and tools

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Log file
$logFile = "C:\ADSetup\AD_Role_Log.txt"
"Starting AD DS role installation at $(Get-Date)" | Out-File -FilePath $logFile

# Install AD DS role and management tools
try {
    Write-Host "Installing AD-Domain-Services and tools..." -ForegroundColor Yellow
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Verbose | Out-File -FilePath $logFile -Append
    "AD DS role installed successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
    Write-Host "AD DS role installed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to install AD DS role: $_"
    "ERROR: AD DS role installation failed - $_" | Out-File -FilePath $logFile -Append
    exit 1
}
