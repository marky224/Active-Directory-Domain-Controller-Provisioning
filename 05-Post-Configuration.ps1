# 05-Post-Configuration.ps1
# Performs post-DC promotion configuration

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Log file
$logFile = "C:\ADSetup\AD_PostConfig_Log.txt"
"Starting post-configuration at $(Get-Date)" | Out-File -FilePath $logFile

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
    Add-DnsServerForwarder -IPAddress "8.8.8.8", "8.8.4.4" -Verbose | Out-File -FilePath $logFile -Append
    "DNS forwarders configured" | Out-File -FilePath $logFile -Append
    Write-Host "DNS forwarders configured successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to configure DNS forwarders: $_"
    "ERROR: DNS forwarder configuration failed - $_" | Out-File -FilePath $logFile -Append
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
}

"Post-configuration completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Post-configuration completed successfully." -ForegroundColor Green