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

try {
    # Generate a self-signed certificate for WinRM HTTPS
    Write-Host "Generating self-signed certificate for WinRM HTTPS..."
    $Cert = New-SelfSignedCertificate -DnsName "win2025.msp.local" -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(5)
    $Thumbprint = $Cert.Thumbprint

    # Export the certificate for RHEL trust
    Write-Host "Exporting certificate to C:\win2025_cert.cer..."
    Export-Certificate -Cert $Cert -FilePath "C:\win2025_cert.cer" -Type CERT

    # Configure WinRM for HTTPS
    Write-Host "Configuring WinRM for HTTPS on port 5986..."
    winrm quickconfig -quiet
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"win2025.msp.local`";CertificateThumbprint=`"$Thumbprint`"}"

    # Configure firewall rule for WinRM HTTPS (port 5986)
    Write-Host "Opening WinRM port 5986 in firewall..."
    New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP

    Write-Host "Post-configuration complete. Certificate exported to C:\win2025_cert.cer."
    Write-Host "Convert to PEM on RHEL with: openssl x509 -inform der -in win2025_cert.cer -out win2025_cert.pem"
}
catch {
    Write-Host "Error during post-configuration: $_"
    exit 1
}

"Post-configuration completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Post-configuration completed successfully." -ForegroundColor Green
