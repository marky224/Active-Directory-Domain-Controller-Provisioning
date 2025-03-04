# 04-Promote-DomainController.ps1
# Promotes server to a DC and creates a new forest with dynamic Administrator password handling

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration variables (customize these as needed)
$domainName = "msp.local"               # Your domain name
$netbiosName = "MSP"                    # NetBIOS name
$logFile = "C:\ADSetup\AD_Promotion_Log.txt"

# Logging function
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

# Ensure log directory exists
if (-not (Test-Path "C:\ADSetup")) {
    New-Item -Path "C:\ADSetup" -ItemType Directory -Force | Out-Null
    Write-Log "Created C:\ADSetup directory."
}

# Display warning about password importance
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "PASSWORD SECURITY NOTICE" -ForegroundColor Red
Write-Host "You will now set or verify the 'Administrator' password." -ForegroundColor Yellow
Write-Host "This password is CRITICAL for production:" -ForegroundColor Yellow
Write-Host "- Becomes the domain Administrator password post-promotion." -ForegroundColor Yellow
Write-Host "- Also used for Safe Mode (DSRM) recovery." -ForegroundColor Yellow
Write-Host "SAVE IT SECURELY (e.g., in a password manager like LastPass or Bitwarden)." -ForegroundColor Red
Write-Host "Loss of this password may lock you out of the domain!" -ForegroundColor Red
Write-Host "=============================================================" -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Check if local 'Administrator' account exists
$adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
if (-not $adminAccount) {
    Write-Host "Local 'Administrator' account not found. Creating it now..." -ForegroundColor Yellow
    Write-Log "Creating 'Administrator' account..."
    $password = Read-Host -Prompt "Enter a strong password for 'Administrator'.`nThis becomes the domain Administrator password post-promotion and Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
    New-LocalUser -Name "Administrator" -Password $password -FullName "Administrator" -Description "Domain Administrator" -ErrorAction Stop
    Add-LocalGroupMember -Group "Administrators" -Member "Administrator" -ErrorAction Stop
    Write-Log "'Administrator' account created."
} else {
    Write-Log "'Administrator' account exists."
    $reset = Read-Host "Reset 'Administrator' password? (Y/N)"
    if ($reset -eq "Y" -or $reset -eq "y") {
        $password = Read-Host -Prompt "Enter a new strong password for 'Administrator'.`nThis becomes the domain Administrator password post-promotion and Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
        Set-LocalUser -Name "Administrator" -Password $password -ErrorAction Stop
        Write-Log "'Administrator' password reset."
    } else {
        $password = Read-Host -Prompt "Enter existing 'Administrator' password (required for Safe Mode).`nMust match current password!`nPassword" -AsSecureString
        Write-Log "'Administrator' password not reset."
    }
}

# Start promotion process
Write-Log "Starting DC promotion at $(Get-Date)"
try {
    Write-Host "Promoting server to Domain Controller..." -ForegroundColor Yellow
    Install-ADDSForest `
        -DomainName $domainName `
        -DomainNetbiosName $netbiosName `
        -SafeModeAdministratorPassword $password `
        -InstallDns `
        -Force `
        -Verbose | Out-File -FilePath $logFile -Append

    Write-Log "DC promotion completed at $(Get-Date)"
    Write-Host "Server promoted to Domain Controller successfully. Rebooting..." -ForegroundColor Green
} catch {
    Write-Error "Failed to promote server to DC: $_"
    Write-Log "ERROR: DC promotion failed - $_"
    exit 1
}

# Final reminder
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "REMINDER: Ensure you have saved the Administrator password!" -ForegroundColor Red
Write-Host "This is now the domain Administrator and Safe Mode (DSRM) password." -ForegroundColor Red
Write-Host "The server will now reboot to complete the setup." -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Yellow