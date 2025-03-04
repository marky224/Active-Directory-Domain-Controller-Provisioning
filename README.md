# Active Directory Domain Controller Provisioning

This repository contains PowerShell scripts to automate the provisioning of an Active Directory Domain Controller (DC) on **Windows Server 2025** in an IT-MSP production environment. These scripts streamline the initial setup of a new AD forest and promote a server to a DC with best practices, designed for Managed Service Providers (MSPs).

## Project Overview

This repository focuses solely on the provisioning (initial setup) of an Active Directory Domain Controller. Configuration (e.g., adding users, GPOs) and management (e.g., monitoring, backups) are out of scope and will be addressed in separate repositories as part of a broader network virtualization project.

## Features

- **End-to-End Automation**: Fully provisions a DC from initial checks to post-configuration.
- **Production-Ready**: Secure password handling, static IP configuration, and AD best practices.
- **Flexible**: Dynamic network adapter and gateway detection for varied environments (any `255.255.255.0` internal subnet).
- **Logging**: Detailed logs in `C:\ADSetup\` for troubleshooting and auditing.

## Prerequisites

- **Operating System**: Fresh installation of Windows Server 2025.
- **Privileges**: Scripts must run with administrative rights (Run as Administrator).
- **Network**: 
  - Server in bridged mode (e.g., VMware Workstation) or on a physical network.
  - Static IP reserved (e.g., `192.168.0.10`) outside DHCP scope on a `255.255.255.0` subnet.
  - Internet access with Google DNS (`8.8.8.8`) required during parts of the provisioning process.
- **Disk Space**: At least 20 GB free.

## Script Files

| File Name                     | Purpose                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| `00-Install-Updates.ps1`      | (Optional) Installs Windows Updates and reboots if needed.              |
| `01-Check-Prerequisites.ps1`  | Verifies OS, admin privileges, and disk space.                         |
| `02-Set-StaticIP.ps1`         | Configures static IP (e.g., `192.168.0.10`) and Google DNS (`8.8.8.8`).|
| `03-Install-ADDSRole.ps1`     | Installs AD Domain Services role and management tools.                 |
| `04-Promote-DomainController.ps1` | Promotes server to a DC, creates `msp.local` forest, and reboots.  |
| `05-Post-Configuration.ps1`   | Sets DNS to DC (e.g., `192.168.0.10`), adds forwarders, and hardens security.|

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/marky224/ad-dc-provisioning.git
   cd ad-dc-provisioning
  ```
2. **Ensure Prerequisites Are Met**: See above.

3. **Open PowerShell as Administrator**.

4. **Run Scripts in Sequence**:
  - Copy scripts to C:\Configuration\ on the target server.
powershell
```
.\00-Install-Updates.ps1      # Optional: Updates system
.\01-Check-Prerequisites.ps1  # Validates environment
.\02-Set-StaticIP.ps1         # Sets network config
.\03-Install-ADDSRole.ps1     # Installs AD DS role
.\04-Promote-DomainController.ps1  # Promotes to DC
.\05-Post-Configuration.ps1   # Finalizes setup
```
5. **Verify Logs**: Check `C:\ADSetup\` for detailed output.

## Configuration
  - Currently, configurations (e.g., IP address, forest name) follow standard AD defaults. Future updates will introduce a JSON configuration file for enhanced customization—stay tuned!

## Security Hardening
  - The 05-Post-Configuration.ps1 script includes security measures to prepare the DC to securely work alongside an Ansible control node in the same network:
    -Disables SMBv1 to prevent legacy vulnerabilities.
    - Enforces strong password policies for AD accounts.
    - Configures Windows Firewall to allow Ansible WinRM communication (ports 5985-5986).
    - Sets DNS forwarders (e.g., 8.8.8.8, 8.8.4.4) for reliable resolution.

## Future Roadmap
  - Add support for a JSON configuration file to customize IP, forest name, and other settings.
  - Expand provisioning scripts for additional network components (e.g., workstations, Ansible nodes).

## License
  - MIT License (LICENSE) - Feel free to use, modify, and distribute.

