# 05-Post-Configuration.ps1
# Performs post-DC promotion configuration

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Log file
$logFile = "C:\ADSetup\AD_PostConfig_Log.txt"
if (-not (Test-Path "C:\ADSetup")) { New-Item -ItemType Directory -Path "C:\ADSetup" | Out-Null }
"Starting post-configuration at $(Get-Date)" | Out-File -FilePath $logFile

# Set hostname to ADDC01-msp
$NewComputerName = "ADDC01-msp"
$currentName = $env:COMPUTERNAME
if ($currentName -ne $NewComputerName) {
    Write-Host "Setting computer name to $NewComputerName..." -ForegroundColor Yellow
    try {
        Rename-Computer -NewName $NewComputerName -Force -Verbose | Out-File -FilePath $logFile -Append
        "Computer name set to $NewComputerName" | Out-File -FilePath $logFile -Append
        Write-Host "Computer name updated to $NewComputerName." -ForegroundColor Green
    } catch {
        Write-Error "Failed to set computer name: $_"
        "ERROR: Failed to set computer name - $_" | Out-File -FilePath $logFile -Append
        exit 1
    }
} else {
    Write-Host "Computer name is already $NewComputerName." -ForegroundColor Green
    "Computer name already $NewComputerName" | Out-File -FilePath $logFile -Append
}

# Verify AD DS is running
try {
    $adService = Get-Service -Name "ADWS"
    if ($adService.Status -ne "Running") {
        Write-Error "Active Directory Web Services is not running."
        "ERROR: ADWS not running" | Out-File -FilePath $logFile -Append
        exit 1
    }
    "ADWS is running" | Out-File -FilePath $logFile -Append
    Write-Host "AD services verified." -ForegroundColor Green
} catch {
    Write-Error "Failed to verify AD services: $_"
    "ERROR: AD service verification failed - $_" | Out-File -FilePath $logFile -Append
    exit 1
}

# Update DNS to the DC itself
$interfaceName = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).Name
$dnsServers = "192.168.0.10"
Write-Host "Updating DNS server to $dnsServers (DC itself) for AD functionality..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $dnsServers -Verbose | Out-File -FilePath $logFile -Append
"Updated DNS to $dnsServers for AD" | Out-File -FilePath $logFile -Append
Write-Host "DNS updated successfully." -ForegroundColor Green

# Configure DNS forwarders (e.g., Google's public DNS for internet)
try {
    Write-Host "Configuring DNS forwarders..." -ForegroundColor Yellow
    $ExistingForwarders = Get-DnsServerForwarder | Select-Object -ExpandProperty IPAddress
    $NewForwarders = @("8.8.8.8", "8.8.4.4")
    $ForwardersToAdd = $NewForwarders | Where-Object { $_ -notin $ExistingForwarders.ToString() }
    if ($ForwardersToAdd) {
        Add-DnsServerForwarder -IPAddress $ForwardersToAdd -Verbose | Out-File -FilePath $logFile -Append
        "Added DNS forwarders: $($ForwardersToAdd -join ', ')" | Out-File -FilePath $logFile -Append
        Write-Host "DNS forwarders ($($ForwardersToAdd -join ', ')) configured successfully." -ForegroundColor Green
    } else {
        "All specified DNS forwarders ($($NewForwarders -join ', ')) already configured" | Out-File -FilePath $logFile -Append
        Write-Host "DNS forwarders already configured: $($NewForwarders -join ', ')" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to configure DNS forwarders: $_"
    "ERROR: DNS forwarder configuration failed - $_" | Out-File -FilePath $logFile -Append
    exit 1
}

# Basic security hardening (disable SMBv1)
try {
    Write-Host "Disabling SMBv1 for security..." -ForegroundColor Yellow
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -Verbose | Out-File -FilePath $logFile -Append
    "SMBv1 disabled" | Out-File -FilePath $logFile -Append
    Write-Host "SMBv1 disabled successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to disable SMBv1: $_"
    "ERROR: SMBv1 disable failed - $_" | Out-File -FilePath $logFile -Append
    exit 1
}

# Prompt user to restart for hostname change
if ($currentName -ne $NewComputerName) {
    Write-Host "=============================================================" -ForegroundColor Yellow
    Write-Host "RESTART REQUIRED" -ForegroundColor Red
    Write-Host "The computer name has been changed to $NewComputerName." -ForegroundColor Yellow
    Write-Host "A restart is required to apply this change." -ForegroundColor Yellow
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Write-Log "User chose to restart now"
        Write-Host "Restarting computer..." -ForegroundColor Green
        Restart-Computer -Force
    } else {
        Write-Log "User chose not to restart now"
        Write-Host "Please restart the computer manually to complete the hostname update." -ForegroundColor Yellow
    }
    Write-Host "=============================================================" -ForegroundColor Yellow
}

"Post-configuration completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Post-configuration completed successfully." -ForegroundColor Green
