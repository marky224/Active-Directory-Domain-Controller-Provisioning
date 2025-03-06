# Post-configuration tasks for AD DC

# Enable strict error handling
$ErrorActionPreference = "Stop"

try {
    # Generate a self-signed certificate for WinRM HTTPS
    Write-Host "Generating self-signed certificate for WinRM HTTPS..."
    $Cert = New-SelfSignedCertificate -DnsName "ADDC01-msp.msp.local" -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(5)
    $Thumbprint = $Cert.Thumbprint

    # Export the certificate for RHEL trust
    Write-Host "Exporting certificate to C:\addc01_msp_cert.cer..."
    Export-Certificate -Cert $Cert -FilePath "C:\addc01_msp_cert.cer" -Type CERT

    # Configure WinRM for HTTPS
    Write-Host "Configuring WinRM for HTTPS on port 5986..."
    winrm quickconfig -quiet
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"ADDC01-msp.msp.local`";CertificateThumbprint=`"$Thumbprint`"}"

    # Configure firewall rule for WinRM HTTPS (port 5986)
    Write-Host "Opening WinRM port 5986 in firewall..."
    New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP

    Write-Host "Post-configuration complete. Certificate exported to C:\addc01_msp_cert.cer."
    Write-Host "Convert to PEM on RHEL with: openssl x509 -inform der -in addc01_msp_cert.cer -out addc01_msp_cert.pem"
}
catch {
    Write-Host "Error during post-configuration: $_"
    exit 1
}
