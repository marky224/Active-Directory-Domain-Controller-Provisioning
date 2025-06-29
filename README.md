# Active Directory Domain Controller Provisioning and Management

This repository contains PowerShell scripts to automate the provisioning of an Active Directory Domain Controller (DC) on **Windows Server 2025** in an IT-MSP production environment. These scripts streamline the initial setup of a new AD forest and promotes a server to a DC with best practices, designed for Managed Service Providers (MSPs).

## Project Overview

This repository focuses solely on the provisioning (initial setup) of an Active Directory Domain Controller.

## ADDC Setup Verification

Below is a screenshot verifying the successful setup of the ADDC (`ADDC01-msp`) with the `msp.local` domain:

![ADDC Setup Screenshot](https://github.com/marky224/Active-Directory-Domain-Controller-Provisioning/raw/main/images/ad_dc_setup_screenshot.jpg)

## Features

- **End-to-End Automation**: Fully provisions a DC from initial checks to post-configuration.
- **Production-Ready**: Secure password handling, static IP configuration, and AD best practices.
- **Flexible**: Dynamic network adapter and gateway detection for varied environments (any `255.255.255.0` internal subnet).
- **Logging**: Detailed logs in `C:\ADSetup\` for troubleshooting and auditing.

## The AD DC Provisioning Process and Automation

Manually provisioning an Active Directory Domain Controller involves several steps that are time-consuming and prone to human error. These scripts automate the entire process, ensuring consistency and efficiency. Here’s what happens at each stage and how the scripts handle it:

1. **System Preparation**:
   - **Manual Task**: Install Windows Updates and reboot to ensure the server is current.
   - **Automation**: `00-Install-Updates.ps1` (optional) checks for updates, installs them, and reboots if necessary, saving manual intervention.

2. **Prerequisite Validation**:
   - **Manual Task**: Verify the OS version, admin privileges, and sufficient disk space.
   - **Automation**: `01-Check-Prerequisites.ps1` runs automated checks and exits with clear error messages if conditions aren’t met, preventing downstream failures.

3. **Network Configuration**:
   - **Manual Task**: Set a static IP address (e.g., `192.168.1.10`), configure DNS to an external provider (e.g., `8.8.8.8`), and ensure network connectivity.
   - **Automation**: `02-Set-StaticIP.ps1` detects the active network adapter, assigns the static IP, sets Google DNS, and validates connectivity—all without manual input.

4. **AD DS Role Installation**:
   - **Manual Task**: Install the Active Directory Domain Services (AD DS) role and management tools via Server Manager or PowerShell.
   - **Automation**: `03-Install-ADDSRole.ps1` installs the AD DS role and tools silently, logging progress for transparency.

5. **DC Promotion**:
   - **Manual Task**: Promote the server to a Domain Controller, create a new forest (e.g., `msp.local`), set a Directory Services Restore Mode (DSRM) password, and reboot.
   - **Automation**: `04-Promote-DomainController.ps1` handles the promotion, securely manages the DSRM password, creates the forest, and triggers a reboot—all in one step.

6. **Post-Configuration**:
   - **Manual Task**: Update DNS to point to the DC itself (e.g., `192.168.1.10`), add external DNS forwarders, and apply security hardening (e.g., disable SMBv1).
   - **Automation**: `05-Post-Configuration.ps1` reconfigures DNS, adds forwarders (e.g., `8.8.8.8`, `8.8.4.4`), and applies security settings tailored for MSP environments, reducing manual hardening effort.

**How Automation Helps**:
- **Speed**: Cuts provisioning time from hours to minutes.
- **Consistency**: Eliminates variability from manual configuration.
- **Error Reduction**: Pre-checks and logging catch issues early.
- **Scalability**: Easily repeatable across multiple servers or environments.

## Prerequisites

- **Operating System**: Fresh installation of Windows Server 2025.
- **Privileges**: Scripts must run with administrative rights (Run as Administrator).
- **Network**: 
  - Server in bridged mode (e.g., VMware Workstation) or on a physical network.
  - Static IP reserved (e.g., `192.168.1.10`) outside DHCP scope on a `255.255.255.0` subnet.
  - Internet access with Google DNS (`8.8.8.8`) required during parts of the provisioning process.
- **Disk Space**: At least 20 GB free.

## Sample Dataset for Testing

The `ad-sample-dataset` folder contains a sample Active Directory dataset from [Active Directory Pro](https://activedirectorypro.com/downloads/ActiveDirectory_Lab_Scripts.zip), including 3,000 users, 20 groups, and 21 organizational units (OUs). This dataset simulates a corporate IT environment, enabling:
- Testing of DC provisioning scripts with realistic data.
- Automation practice for bulk user imports, group management, and OU structuring.
- Validation of group policies and security settings in a large-scale AD setup.

See `ad-sample-dataset/README.md` for usage instructions and integration details.

## Domain Join Automation

The `ad-domain-join` folder contains scripts to automate joining Windows and Red Hat Enterprise Linux (RHEL) 9 PCs to the AD domain (e.g., `msp.local`). The scripts include:
- `Join-ADWindows.ps1`: Joins Windows 10/11 PCs to the domain.
- `join_ad_rhel9.sh`: Joins RHEL 9 systems to the domain using tools like `realmd` and `sssd`.

These scripts streamline workstation integration for MSPs, supporting:
- Rapid domain joins with minimal manual configuration.
- Compatibility with diverse client environments (Windows and RHEL 9).
- Testing with the `ad-sample-dataset` user accounts for realistic scenarios (e.g., logging in as a domain user).

See `ad-domain-join/README.md` for script details, prerequisites, and usage.

## Ensuring Proper Licensing

To use these scripts in a production environment, ensure all tools and software involved are properly licensed. Here’s what you need to verify:

## Scripts Overview

| File Name                 | Purpose                                      |
|---------------------------|----------------------------------------------|
| `01-Check-Prerequisites.ps1` | Verifies OS and prerequisites.         |
| `02-Set-StaticIP.ps1`     | Configures static IP and DNS.                |
| `03-Install-ADDSRole.ps1` | Installs AD DS role and tools.               |
| `04-Promote-DomainController.ps1` | Promotes server to DC.            |
| `05-Post-Configuration.ps1` | Finalizes DNS, hostname (`ADDC01-msp`), and security. |
| `ad-sample-dataset/` | Contains scripts and CSV files for populating AD with sample data (3,000 users, 20 groups, 21 OUs): <br> - `create_users.ps1`: Imports users from `users.csv`. <br> - `create_groups.ps1`: Creates groups from `groups.csv`. <br> - `create_ous.ps1`: Sets up OUs from `ous.csv`. <br> See `ad-sample-dataset/README.md` for details. |
| `ad-domain-join/` | Contains scripts for joining client PCs to the AD domain: <br> - `Join-ADWindows.ps1`: Joins Windows 10/11 PCs to `msp.local`. <br> - `join_ad_rhel9.sh`: Joins RHEL 9 systems to `msp.local` using `realmd`/`sssd`. <br> See `ad-domain-join/README.md` for details. |

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/marky224/Active-Directory-Domain-Controller-Provisioning.git
   cd Active-Directory-Domain-Controller-Provisioning
    ```
2. **Ensure Prerequisites Are Met**: See above.

3. **Open PowerShell as Administrator**.

4. **Run Scripts in Sequence**:
  - Copy scripts to C:\Configuration\ on the target server.
  ```powershell
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
