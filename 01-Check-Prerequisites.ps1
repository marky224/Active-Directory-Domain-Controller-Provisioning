# 01-Check-Prerequisites.ps1
# Verifies server readiness for AD DS installation

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Log file
$logFile = "C:\ADSetup\AD_Prereq_Log.txt"
if (-not (Test-Path "C:\ADSetup")) { New-Item -ItemType Directory -Path "C:\ADSetup" }
"Starting prerequisite checks at $(Get-Date)" | Out-File -FilePath $logFile

# Check OS version
$os = Get-CimInstance -ClassName Win32_OperatingSystem
if ($os.Caption -notlike "*Windows Server 2025*") {
    Write-Error "This script is designed for Windows Server 2025 only."
    "ERROR: Unsupported OS - $($os.Caption)" | Out-File -FilePath $logFile -Append
    exit 1
}

# Check admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with administrative privileges."
    "ERROR: Not running as admin" | Out-File -FilePath $logFile -Append
    exit 1
}

# Check disk space (minimum 20 GB free recommended)
$disk = Get-Disk | Get-Partition | Where-Object { $_.DriveLetter -eq 'C' } | Get-Volume
if ($disk.SizeRemaining -lt 20GB) {
    Write-Warning "Less than 20 GB free space on C: drive. Proceed with caution."
    "WARNING: Low disk space - $($disk.SizeRemaining / 1GB) GB free" | Out-File -FilePath $logFile -Append
}

"Prerequisites check completed successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Prerequisites verified successfully." -ForegroundColor Green
