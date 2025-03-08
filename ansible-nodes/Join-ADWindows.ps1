# PowerShell script to join a Windows machine to an Active Directory domain and enable WinRM with HTTPS
# Usage: Run as Administrator in PowerShell: .\Join-ADWindows.ps1

# Requires running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell with elevated privileges."
    exit 1
}

# Constants
$LogFile = "C:\Logs\AD_Join.log"
$Domain = "msp.local"
$DCIP = "192.168.0.10"
$GatewayIP = "192.168.0.1"
$AdminUser = "Administrator"
$HostnameBase = "win-ws-rn"
$IPBase = "192.168.0."
$WinRMPort = 5986  # Default HTTPS port for WinRM

# Ensure log directory exists
$LogDir = Split-Path $LogFile -Parent
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Functions
function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host "$Timestamp - $Message"
}

function Exit-WithError {
    param ([string]$Message)
    Write-Log "ERROR: $Message"
    Write-Error $Message
    exit 1
}

function Backup-Registry {
    param ([string]$Path)
    $BackupFile = "$Path-$(Get-Date -Format 'yyyyMMddHHmmss').reg"
    try {
        reg export $Path $BackupFile /y | Out-Null
        Write-Log "Backed up registry: $Path to $BackupFile"
    } catch {
        Exit-WithError "Failed to backup registry: $Path. Error: $_"
    }
}

function Get-NetworkInterface {
    Write-Log "Detecting active network interface..."
    try {
        $Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -like "Ethernet*" } | Select-Object -First 1
        if ($null -eq $Interface) {
            Exit-WithError "No active Ethernet interface found."
        }
        $Script:InterfaceAlias = $Interface.Name
        Write-Log "Detected network interface: $InterfaceAlias"
    } catch {
        Exit-WithError "Failed to detect network interface. Error: $_"
    }
}

function Prompt-HostnameSuffix {
    while ($true) {
        $Suffix = Read-Host "Enter hostname suffix (01-99)"
        if ($Suffix -match '^\d{2}$' -and [int]$Suffix -ge 1 -and [int]$Suffix -le 99) {
            $Script:NewHostname = "$HostnameBase$Suffix"
            Write-Log "Selected hostname: $NewHostname"
            break
        } else {
            Write-Host "Invalid input. Please enter a two-digit number between 01 and 99."
        }
    }
}

function Prompt-IPSuffix {
    while ($true) {
        $Suffix = Read-Host "Enter IP suffix (30-90)"
        if ($Suffix -match '^\d{2}$' -and [int]$Suffix -ge 30 -and [int]$Suffix -le 90) {
            $Script:NewIP = "$IPBase$Suffix"
            Write-Log "Selected IP address: $NewIP"
            break
        } else {
            Write-Host "Invalid input. Please enter a two-digit number between 30 and 90."
        }
    }
}

function Configure-Network {
    Write-Log "Configuring network settings on $InterfaceAlias..."
    try {
        # Set static IP, gateway, and DNS
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $NewIP -PrefixLength 24 -DefaultGateway $GatewayIP -ErrorAction Stop | Out-Null
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DCIP -ErrorAction Stop
        Write-Log "Network configured with IP: $NewIP, Gateway: $GatewayIP, DNS: $DCIP"
    } catch {
        Exit-WithError "Failed to configure network. Error: $_"
    }
}

function Set-Hostname {
    Write-Log "Setting hostname to $NewHostname..."
    try {
        Rename-Computer -NewName $NewHostname -Force -ErrorAction Stop
        Write-Log "Hostname set successfully. Reboot required to apply."
    } catch {
        Exit-WithError "Failed to set hostname. Error: $_"
    }
}

function Join-Domain {
    Write-Log "Joining domain $Domain..."
    try {
        $Credential = Get-Credential -UserName "$AdminUser@$Domain" -Message "Enter password for $AdminUser@$Domain"
        Add-Computer -DomainName $Domain -Credential $Credential -OUPath "OU=Workstations,DC=msp,DC=local" -Force -ErrorAction Stop
        Write-Log "Successfully joined domain $Domain"
    } catch {
        Exit-WithError "Failed to join domain. Error: $_"
    }
}

function Configure-WinRM {
    Write-Log "Configuring WinRM with HTTPS..."
    try {
        # Enable PSRemoting
        Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null

        # Generate a self-signed certificate
        $Cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "$NewHostname.$Domain" -NotAfter (Get-Date).AddYears(5) -ErrorAction Stop
        $Thumbprint = $Cert.Thumbprint
        Write-Log "Generated self-signed certificate with thumbprint: $Thumbprint"

        # Create WinRM HTTPS listener
        $WinRMListener = "winrm/config/Listener?Address=*+Transport=HTTPS"
        & winrm create $WinRMListener "@{Hostname=`"$NewHostname.$Domain`";CertificateThumbprint=`"$Thumbprint`"}" | Out-Null
        Write-Log "WinRM HTTPS listener created on port $WinRMPort"

        # Open WinRM HTTPS port in firewall
        New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -LocalPort $WinRMPort -Action Allow -ErrorAction Stop | Out-Null
        Write-Log "Firewall rule added for WinRM HTTPS on port $WinRMPort"
    } catch {
        Exit-WithError "Failed to configure WinRM with HTTPS. Error: $_"
    }
}

function Verify-Join {
    Write-Log "Verifying domain join..."
    try {
        $DomainCheck = (Get-WmiObject -Class Win32_ComputerSystem).Domain
        if ($DomainCheck -eq $Domain) {
            Write-Log "Domain join verified: $DomainCheck"
        } else {
            Exit-WithError "Domain join verification failed. Current domain: $DomainCheck"
        }
    } catch {
        Exit-WithError "Failed to verify domain join. Error: $_"
    }
}

function Verify-WinRM {
    Write-Log "Verifying WinRM service with HTTPS..."
    try {
        $WinRMStatus = (Get-Service -Name WinRM).Status
        if ($WinRMStatus -ne "Running") {
            Exit-WithError "WinRM service is not running. Status: $WinRMStatus"
        }
        Test-WSMan -ComputerName $NewHostname -UseSSL -Port $WinRMPort -ErrorAction Stop | Out-Null
        Write-Log "WinRM HTTPS connectivity verified on port $WinRMPort"
    } catch {
        Exit-WithError "Failed to verify WinRM with HTTPS. Error: $_"
    }
}

# Main execution
Write-Log "Starting AD join process for $Domain..."

Get-NetworkInterface
Prompt-HostnameSuffix
Prompt-IPSuffix
Configure-Network
Set-Hostname
Join-Domain
Configure-WinRM
Verify-Join
Verify-WinRM

Write-Log "AD join and WinRM HTTPS setup completed successfully!"
Write-Host "Machine joined as $NewHostname with IP $NewIP"
Write-Host "WinRM is enabled with HTTPS and accessible on port $WinRMPort"
Write-Host "A reboot is required to apply all changes. Restarting in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force
