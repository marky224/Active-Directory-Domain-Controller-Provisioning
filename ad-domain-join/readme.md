# Active Directory Domain Join Automation

This folder contains PowerShell and shell scripts to automate the process of joining Windows and Linux PCs to the Active Directory (AD) domain created by the main project (e.g., `msp.local`). These scripts are designed for Managed Service Providers (MSPs) to streamline client workstation integration into a newly provisioned AD environment.

## Contents

- **Scripts** (assumed, adjust based on actual files):
  - `Join-WindowsDomain.ps1`: Automates joining a Windows PC to the AD domain.
  - `Join-LinuxDomain.sh`: Configures a Linux PC to join the AD domain using tools like `realmd` or `sssd`.
- **Configuration Files** (if applicable): Any supporting files for domain join settings (e.g., `krb5.conf` for Linux).

*Note*: Update this section with specific script names and descriptions once confirmed.

## Purpose

These scripts extend the main project’s Active Directory Domain Controller (DC) provisioning by automating the client-side process of joining workstations to the domain. They enable:
- Rapid integration of Windows and Linux PCs into the `msp.local` domain.
- Consistent domain join configurations with minimal manual intervention.
- Support for MSPs managing diverse client environments with both Windows and Linux systems.
- Testing with the `ADLabDataset` folder’s sample data (e.g., users and groups).

## Prerequisites

- **Active Directory Environment**:
  - A provisioned DC running Windows Server 2025, set up using the main project’s scripts (`01-Check-Prerequisites.ps1` through `05-Post-Configuration.ps1`).
  - Domain (e.g., `msp.local`) active and accessible.
- **Windows PC**:
  - Operating System: Windows 10/11 Pro or Enterprise.
  - Network: Connectivity to the DC (e.g., IP `192.168.0.10`, DNS set to DC’s IP).
  - Privileges: Local administrative rights and domain credentials (e.g., `msp\Administrator`).
- **Linux PC**:
  - Operating System: A supported distribution (e.g., Ubuntu 20.04+, CentOS 8+, or RHEL).
  - Packages: `realmd`, `sssd`, `krb5-user`, and `samba-common` installed.
  - Network: Connectivity to the DC and DNS resolution for `msp.local`.
- **Scripts**:
  - Run with administrative/root privileges (PowerShell for Windows, `sudo` for Linux).
- **Disk Space**: Minimal (<10 MB for scripts and logs).

## Usage

1. **Ensure DC is Provisioned**:
   - Complete the DC setup using the main project’s scripts (up to `05-Post-Configuration.ps1`).
   - Verify DNS resolution (e.g., `nslookup msp.local` resolves to `192.168.0.10`).

2. **Prepare the Client PC**:
   - **Windows**: Ensure the PC is on the same network as the DC and has a static or DHCP-assigned IP.
   - **Linux**: Install required packages:
     ```bash
     sudo apt update && sudo apt install -y realmd sssd krb5-user samba-common
