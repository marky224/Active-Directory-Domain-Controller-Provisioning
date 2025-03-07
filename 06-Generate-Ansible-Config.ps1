# 06-Generate-Ansible-Config.ps1
# Script to gather AD information and generate an Ansible JSON configuration file

# Enable strict error handling
$ErrorActionPreference = "Stop"

try {
    # Variables
    $DomainName = "msp.local"
    $AdminUser = "Administrator@$DomainName"
    $OutputFile = "C:\ansible_config.json"
    $PasswordFile = "C:\ansible_secrets\ad_password.txt"
    $SecretsDir = "C:\ansible_secrets"

    # Prompt for AD admin password securely
    $AdminPassword = Read-Host -Prompt "Enter AD Administrator password" -AsSecureString
    $AdminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))

    # Create secure directory for password storage if it doesn't exist
    if (-not (Test-Path $SecretsDir)) {
        New-Item -Path $SecretsDir -ItemType Directory | Out-Null
        Write-Host "Created directory $SecretsDir for secure storage."
    }

    # Save the password to a file securely
    Write-Host "Saving AD password securely to $PasswordFile..."
    $AdminPasswordPlain | Out-File -FilePath $PasswordFile -Encoding UTF8

    # Set NTFS permissions to restrict access to Administrator only
    $Acl = Get-Acl $PasswordFile
    $Acl.SetAccessRuleProtection($true, $false)  # Disable inheritance, remove existing rules
    $AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator", "FullControl", "Allow")
    $Acl.SetAccessRule($AdminRule)
    Set-Acl -Path $PasswordFile -AclObject $Acl
    Write-Host "Password file permissions set to Administrator only."

    # Gather AD computer objects
    Write-Host "Gathering AD computer information..."
    $Computers = Get-ADComputer -Filter * -Properties IPv4Address, OperatingSystem | Select-Object Name, IPv4Address, OperatingSystem

    # Initialize JSON structure
    $AnsibleConfig = @{
        "linux_nodes" = @()
        "windows_nodes" = @()
    }

    # Populate JSON structure
    foreach ($Computer in $Computers) {
        $Node = @{
            "ansible_host" = $Computer.IPv4Address
            "ansible_user" = $AdminUser
            "ansible_password" = $AdminPasswordPlain
        }

        if ($Computer.OperatingSystem -like "*Linux*") {
            $Node["ansible_connection"] = "ssh"
            $AnsibleConfig["linux_nodes"] += ,$Node
        } else {
            $Node["ansible_connection"] = "winrm"
            $Node["ansible_winrm_transport"] = "ntlm"
            $Node["ansible_port"] = 5986
            $Node["ansible_winrm_scheme"] = "https"
            $AnsibleConfig["windows_nodes"] += ,$Node
        }
    }

    # Convert to JSON and save to file
    Write-Host "Generating Ansible configuration file at $OutputFile..."
    $AnsibleConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputFile

    Write-Host "Ansible configuration generation complete. File saved to $OutputFile."
    Write-Host "Password saved to $PasswordFile for future automation. Transfer C:\addc01_msp_cert.cer to RHEL and specify ansible_winrm_ca_trust_path in inventory."
}
catch {
    Write-Host "Error generating Ansible config or saving password: $_"
    exit 1
}
