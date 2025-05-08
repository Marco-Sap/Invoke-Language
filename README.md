# Invoke-Language

08-05-2025

Change the default Language during ESP

.SYNOPSIS

Win32App for setting the default Language during Intune Autopilot ESP

.DESCRIPTION

Target Devices to set the default language during Intune Autopilot ESP Device phase

.AUTHOR

Marco Sap

.VERSION

1.0 - 08-05-2025

.EXAMPLE


Create Win32App (download tool at https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)

C:\IntuneApp\IntuneWinAppUtil.exe -c "C:\IntuneApp\OOBELanguage" -s Invoke-Language.ps1 -o C:\IntuneApp -q


Install Command: 

C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-Language.ps1 -Install

C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-Language.ps1 -Install -Language nl-NL


Uninstall Command:

C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-Language.ps1 -Uninstall


Detection rule:

Manual configure detection rules

Rule Type: Registry

Key path: Computer\HKEY_LOCAL_MACHINE\Software\Intune\Language

Value name: 1.0-Success

Detection methode: Value exists

.DISCLAIMER
This script code is provided as is with no guarantee or waranty
concerning the usability or impact on systems and may be used,
distributed, and modified in any way provided the parties agree
and acknowledge that Microsoft or Microsoft Partners have neither
accountabilty or responsibility for results produced by use of
this script.

Microsoft will not provide any support through any means.
