# 02-Set-StaticIP.ps1
# Configures a static IP address with DNS set to Google for pre-promotion internet access

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Log file
$logFile = "C:\ADSetup\StaticIP_Log.txt"
if (-not (Test-Path "C:\ADSetup")) { New-Item -ItemType Directory -Path "C:\ADSetup" | Out-Null }

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

# Get the active network adapter dynamically
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $adapter) {
    Write-Error "No active network adapter found."
    Write-Log "ERROR: No active network adapter found."
    exit 1
}
$interfaceName = $adapter.Name
Write-Log "Found active network adapter: $interfaceName"

# Set network profile to Private early
$profile = Get-NetConnectionProfile -InterfaceAlias $interfaceName -ErrorAction SilentlyContinue
if ($profile -and $profile.NetworkCategory -ne "Private") {
    Write-Host "Setting network profile to Private..." -ForegroundColor Yellow
    Set-NetConnectionProfile -InterfaceAlias $interfaceName -NetworkCategory Private -Verbose
    Write-Log "Network profile set to Private."
} else {
    Write-Log "Network profile already Private or not applicable yet."
}

# Get the current gateway dynamically
$currentConfig = Get-NetIPConfiguration -InterfaceAlias $interfaceName -ErrorAction SilentlyContinue
$gateway = $currentConfig.IPv4DefaultGateway.NextHop
if (-not $gateway) {
    Write-Warning "No default gateway detected. Assuming 192.168.0.1 (UniFi Express possible default). Adjust if incorrect."
    $gateway = "192.168.0.1"
    Write-Log "WARNING: Gateway not detected. Defaulting to $gateway."
} else {
    Write-Log "Detected gateway: $gateway"
}

# Static IP settings
$staticIP = "192.168.0.10"
$prefixLength = 24  # Equivalent to 255.255.255.0
$dnsServers = "8.8.8.8"  # Using Google DNS for internet access pre-promotion

# Check if IP is already static
$ipConfig = Get-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4 -ErrorAction SilentlyContinue
$ipInterface = Get-NetIPInterface -InterfaceAlias $interfaceName -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($ipConfig -and $ipConfig.IPAddress -eq $staticIP -and $ipConfig.PrefixLength -eq $prefixLength) {
    Write-Host "IP is already set to $staticIP with prefix $prefixLength. No changes needed." -ForegroundColor Green
    Write-Log "IP already configured as $staticIP with prefix $prefixLength."
} else {
    # Check if DHCP is enabled and disable it
    if ($ipInterface -and $ipInterface.Dhcp -eq "Enabled") {
        Write-Log "Removing DHCP configuration from $interfaceName."
        Set-NetIPInterface -InterfaceAlias $interfaceName -Dhcp Disabled -Verbose
        # Remove existing DHCP-assigned IP if present
        if ($ipConfig) {
            Write-Log "Removing existing IP: $($ipConfig.IPAddress)"
            Remove-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $ipConfig.IPAddress -Confirm:$false -Verbose -ErrorAction SilentlyContinue
        }
    }

    # Set static IP
    Write-Host "Configuring static IP $staticIP on $interfaceName..." -ForegroundColor Yellow
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $staticIP -AddressFamily IPv4 -PrefixLength $prefixLength -DefaultGateway $gateway -Verbose | Out-Null
    Write-Log "Set static IP: $staticIP with prefix $prefixLength and gateway $gateway."
}

# Set DNS servers
Write-Host "Setting DNS server to $dnsServers (Google DNS for pre-promotion internet access)..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $dnsServers -Verbose | Out-Null
Write-Log "Set DNS server to $dnsServers."

Write-Host "Static IP configuration completed successfully." -ForegroundColor Green
Write-Log "Static IP configuration completed."

# Confirmation and note about DNS
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "DNS CONFIGURATION NOTE" -ForegroundColor Yellow
Write-Host "DNS is set to $dnsServers (Google DNS) for internet access before AD promotion." -ForegroundColor Yellow
Write-Host "Post-promotion, update DNS to 192.168.0.10 (the DC itself) for AD functionality." -ForegroundColor Yellow
Write-Host "This will be adjusted in 05-Post-Configuration.ps1." -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow