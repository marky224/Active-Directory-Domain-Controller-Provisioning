# Active Directory Lab Dataset

This folder contains a sample Active Directory dataset and scripts from [Active Directory Pro](https://activedirectorypro.com/downloads/ActiveDirectory_Lab_Scripts.zip), designed to simulate a corporate IT environment for testing and automation. It complements the main project's automation scripts for provisioning an Active Directory Domain Controller (DC) by providing realistic data for user, group, and organizational unit (OU) management.

## Contents

- **CSV Files**:
  - `users.csv`: 3,000 user accounts with attributes like `sAMAccountName`, `DisplayName`, `OU`, etc.
  - `groups.csv`: 20 security groups with properties like `GroupName` and `Scope`.
  - `ous.csv`: 21 organizational units with defined paths and names.
- **PowerShell Scripts**:
  - `create_users.ps1`: Imports users from `users.csv` into Active Directory.
  - `create_groups.ps1`: Creates groups from `groups.csv`.
  - `create_ous.ps1`: Sets up OUs from `ous.csv`.

## Purpose

This dataset enables testing of AD automation scripts in a realistic corporate environment. Use it to:
- Practice bulk user creation, group assignments, and OU structuring.
- Test the DC provisioning scripts in the main project with a large, pre-populated dataset.
- Develop and validate custom automation workflows (e.g., reporting, user management).

## Prerequisites

- **Active Directory Environment**: A provisioned DC (e.g., using the main project’s scripts: `04-Promote-DomainController.ps1`).
- **PowerShell**: Administrative privileges to run the scripts.
- **Disk Space**: Minimal (CSV files and scripts are small, <10 MB).
- **Network**: The DC should be configured with a static IP and DNS, as set up by `02-Set-StaticIP.ps1` and `05-Post-Configuration.ps1`.

## Usage

1. **Ensure DC is Provisioned**:
   - Complete the DC setup using the main project’s scripts (`01-Check-Prerequisites.ps1` through `05-Post-Configuration.ps1`).
   - Verify the domain (e.g., `msp.local`) is active.

2. **Copy Files**:
   - Place the contents of this folder (`ADLabDataset`) into `C:\Configuration\` on the target DC, alongside the main project’s scripts, or keep them in a separate directory.

3. **Run Scripts**:
   - Open PowerShell as Administrator.
   - Execute the scripts in sequence to populate the AD environment:
     ```powershell
     .\create_ous.ps1
     .\create_groups.ps1
     .\create_users.ps1
