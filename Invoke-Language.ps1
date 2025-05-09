<#
.SYNOPSIS
   Win32App for setting the Language during Intune Autopilot ESP
.DESCRIPTION
   Target Devices to set the language during Intune Autopilot ESP Device phase
.AUTHOR
   Marco Sap
.VERSION
   1.0 - 08-05-2025
.EXAMPLE

    Create Win32App
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
#>
[CmdletBinding()]
 Param(
    [Parameter(
    Mandatory = $false)]
    [switch]$Install,

    [Parameter(
    Mandatory=$false)]
    [switch]$Uninstall,

    [Parameter(
    Mandatory=$false)]
    $Language='nl-NL'
 )

#region Helper Functions
Function Add-RegistryKey {
[CmdletBinding()]
    Param(
    [Parameter(Mandatory=$true)]
    $HKEY,

    [Parameter(Mandatory=$true)]
    $RegistryPath,

    [Parameter(Mandatory=$true)]
    $RegistryKey,

    [Parameter(Mandatory=$true)]
    $RegistryValue,

    [Parameter(Mandatory=$true)]
    $ValueType
    )

Switch ($HKEY)
    {
        "LOCAL_MACHINE" {$RegistryPath = "HKLM:\" + $RegistryPath}
        "CURRENT_USER" {$RegistryPath = "HKCU:\" + $RegistryPath}
        "DEFAULT_USER" {$RegistryPath = "HKLM:\MDU\" + $RegistryPath}
    }

    if(!(Test-Path $RegistryPath))
    {
        New-Item -Path $RegistryPath -Force 1>$null
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Path $($RegistryPath)"
    }
    else
    {
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [NoChange] $($RegistryPath)"
    }

    if(!([string]::IsNullOrEmpty($RegistryKey)))
    {
        if(!([string]::IsNullOrEmpty($(Get-ItemProperty -Path $RegistryPath))))
        {
            if([string]::IsNullOrEmpty($(Get-ItemProperty -Path $RegistryPath -Name $RegistryKey -ErrorAction SilentlyContinue))){
                New-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue -PropertyType $ValueType 1>$null
                Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Key $($RegistryKey) with value $($RegistryValue) of type $($ValueType)"}
            else{
                    if($(Get-ItemPropertyValue -Path $RegistryPath -Name $RegistryKey) -eq $RegistryValue)
                    {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [NoChange] $($RegistryKey) with $($RegistryValue) of type $($ValueType)"
                    }
                    else
                    {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Changed] Key $RegistryKey value $(Get-ItemPropertyValue -Path $RegistryPath -Name $RegistryKey) to value $RegistryValue"
                        Set-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue 1>$null
                    }
                }        
        }
        else {
            New-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue -PropertyType $ValueType 1>$null
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Key $($RegistryKey) with value $($RegistryValue) of type $($ValueType)"
        }
    }
}

Function Add-Detection() {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $errorlevel
)

# Write results to registry for Intune Detection
$key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Intune\' + $name
$installdate = Get-Date -Format "dd/MM/yyyy hh:mm:ss"

    if($errorlevel -eq "55"){
        [microsoft.win32.registry]::SetValue($key, "$version-Start", $installdate)
    }elseif($errorlevel -eq "0"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
    }elseif($errorlevel -eq "3010"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-Reboot", $errorlevel)
    }elseif($errorlevel -eq "1641"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-Reboot", $errorlevel)
    }else{
        [microsoft.win32.registry]::SetValue($key, "$version-Failure", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-ErrorCode", $errorlevel)
    }

}
#endregion

#Variables
$exitstatus=0
$name="Language"
$version="1.0"
$logFile=$name + "-" + $version + ".log"
$key='HKEY_LOCAL_MACHINE\SOFTWARE\Intune\' + $name

#Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logfile"
Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Start]"
Add-Detection -errorlevel 55

If($Install){
    try{
        #Language in Script (currently it doesn't use this variable and defaults to nl-NL
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Language is $($Language)"
        
        #Disable Language Pack Cleanup (do not re-enable)
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Disable Scheduled Task"
        Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup" #| Out-Null

        #Installs the langauage selected
        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] Install-language started"
        Install-Language nl-NL
        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] Install-language finished"

        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] Set-SystemPreferredUILanguage started"
        Set-SystemPreferredUILanguage nl-NL
        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] Set-SystemPreferredUILanguage finished"

        #Prepare Recovery
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] XML started"
        #Variables Language XML
        $InputLocale="0409:00020409"
        $SystemLocale="en-US"
        $TimeZone="W. Europe Standard Time"

        If (Test-Path "C:\Recovery\AutoApply"){}Else{
            New-Item -Path "C:\Recovery\" -Name "AutoApply" -ItemType "directory"
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] AutoApply Directory Created"
        }

        If (Test-Path "C:\Recovery\AutoApply\OOBE"){}Else{
            New-Item -Path "C:\Recovery\AutoApply" -Name "OOBE" -ItemType "directory"
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] OOBE Directory Created"
        }

        #Create & Set The Formatting with XmlWriterSettings class
        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] Unattend XML started"
        $xmlObjectsettings = New-Object System.Xml.XmlWriterSettings
        #Indent: Sets a value indicating whether to indent elements.
        $xmlObjectsettings.Indent = $true
        #Sets the character string to use when indenting. This setting is used when the Indent property is set to true.
        $xmlObjectsettings.IndentChars = "`t"
 
        #Set the File path & Create the unattend XML
        $XmlFilePath = "C:\Recovery\AutoApply\unattend.xml"
        $XmlObjectWriter = [System.XML.XmlWriter]::Create($XmlFilePath, $xmlObjectsettings)

        #Write the XML
        $XmlObjectWriter.WriteStartDocument()
        $XmlObjectWriter.WriteStartElement('unattend', "urn:schemas-microsoft-com:unattend")
        $XmlObjectWriter.WriteAttributeString("xmlns", "urn:schemas-microsoft-com:unattend")
            $XmlObjectWriter.WriteStartElement('settings')
            $XmlObjectWriter.WriteAttributeString("pass", "specialize")
                $XmlObjectWriter.WriteStartElement('component')
                $XmlObjectWriter.WriteAttributeString("language", "neutral")
                $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-International-Core")
                $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
                $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
                $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
                $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
                $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                    $XmlObjectWriter.WriteElementString("InputLocale",$InputLocale)
                    $XmlObjectWriter.WriteElementString("SystemLocale",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UILanguage",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UILanguageFallback",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UserLocale",$SystemLocale)
                $XmlObjectWriter.WriteEndElement()
                $XmlObjectWriter.WriteStartElement('component')
                $XmlObjectWriter.WriteAttributeString("language", "neutral")
                $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-Shell-Setup")
                $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
                $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
                $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
                $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
                $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                    $XmlObjectWriter.WriteElementString("TimeZone",$TimeZone)
                $XmlObjectWriter.WriteEndElement()
            $XmlObjectWriter.WriteEndElement()
            $XmlObjectWriter.WriteStartElement('settings')
            $XmlObjectWriter.WriteAttributeString("pass", "oobeSystem")
                $XmlObjectWriter.WriteStartElement('component')
                $XmlObjectWriter.WriteAttributeString("language", "neutral")
                $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-International-Core")
                $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
                $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
                $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
                $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
                $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                    $XmlObjectWriter.WriteElementString("InputLocale",$InputLocale)
                    $XmlObjectWriter.WriteElementString("SystemLocale",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UILanguage",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UILanguageFallback",$SystemLocale)
                    $XmlObjectWriter.WriteElementString("UserLocale",$SystemLocale)
                $XmlObjectWriter.WriteEndElement()
                $XmlObjectWriter.WriteStartElement('component')
                $XmlObjectWriter.WriteAttributeString("language", "neutral")
                $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-Shell-Setup")
                $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
                $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
                $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
                $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
                $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                    $XmlObjectWriter.WriteElementString("TimeZone",$TimeZone)
                $XmlObjectWriter.WriteEndElement()
            $XmlObjectWriter.WriteEndElement()
        $XmlObjectWriter.WriteEndElement()
        $XmlObjectWriter.WriteEndDocument()
        $XmlObjectWriter.Flush()
        $XmlObjectWriter.Close()
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend XML Created"

        #Create & Set The Formatting with XmlWriterSettings class
        Write-Output "$(Get-Date -Format "dd/MM HH:mm") [Info] OOBE XML started"
        $xmlObjectsettings2 = New-Object System.Xml.XmlWriterSettings
        #Indent: Sets a value indicating whether to indent elements.
        $xmlObjectsettings2.Indent = $true
        #Sets the character string to use when indenting. This setting is used when the Indent property is set to true.
        $xmlObjectsettings2.IndentChars = "`t"
 
        #Set the File path & Create the OOBE XML
        $XmlFilePath2 = "C:\Recovery\AutoApply\OOBE\OOBE.xml"
        $XmlObjectWriter2 = [System.XML.XmlWriter]::Create($XmlFilePath2, $xmlObjectsettings2)

        #Write the XML
        $XmlObjectWriter2.WriteStartDocument()
        $XmlObjectWriter2.WriteStartElement('FirstExperience')
            $XmlObjectWriter2.WriteStartElement('oobe')
                $XmlObjectWriter2.WriteStartElement('defaults')
                    $XmlObjectWriter2.WriteElementString("language",'1033')
                    $XmlObjectWriter2.WriteElementString("location",'176')
                    $XmlObjectWriter2.WriteElementString("keyboard",'0409:00000409')
                $XmlObjectWriter2.WriteEndElement()
            $XmlObjectWriter2.WriteEndElement()
        $XmlObjectWriter2.WriteEndElement()
        $XmlObjectWriter2.WriteEndDocument()
        $XmlObjectWriter2.Flush()
        $XmlObjectWriter2.Close()
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] OOBE XML Created"

        #Load Default User Hive to change language for all Users
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Load Hive and JSON started"
        Reg Load "HKEY_LOCAL_MACHINE\MDU" "C:\Users\Default\NTUser.dat"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Registry Hive DefaultUser loaded as MDU"

        #Load JSON
        $JSONFile = "$PSScriptRoot\Language\intlnl.json"
        $RegKeys = Get-Content -Raw $JSONFile | ConvertFrom-Json
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] JSON loaded"

        #Write Language Settings
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Write Registry Hive started"
        Foreach($Key in $RegKeys){
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Processing $($Key.Name)"
            Add-RegistryKey -HKEY $Key.HKEY -RegistryPath $Key.RegistryPath -RegistryKey $Key.RegistryKey -RegistryValue $Key.RegistryValue -ValueType $Key.ValueType
        }
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Write Registry Hive finished"

        #Unload Default User Hive
        [GC]::Collect()
        Start-Sleep -Seconds 3
        Reg Unload "HKEY_LOCAL_MACHINE\MDU"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Registry Hive DefaultUser unloaded as MDU"

        #Remove unattend.xml from Panther
        If (Test-Path "C:\Windows\Panther\unattend.xml"){
            Remove-Item -Path C:\Windows\Panther\unattend.xml -Force
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend removed"
        }Else{  
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend not found"
        }

        #set Exit
        Write-Output ""
        $exitstatus=0

    }Catch{
        Write-Output "[Error] $(Get-Date -Format "dd/MM HH:mm") Install $($Language) failed"
        Write-Output ""
        $exitstatus=1
    }
}

If($Uninstall){
    try{
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Start] Uninstall started"
    $Uninstallkey = $key.Replace('HKEY_LOCAL_MACHINE','HKLM:')
    Remove-Item -Path $Uninstallkey -Force
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [End] Uninstall finished"
    $exitstatus=0
    }Catch{
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Error] Uninstall failed"
    $exitstatus=1
    }
}

Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [End]"
#Stop logging
Stop-Transcript
#Exit Status
Add-Detection -errorlevel $exitstatus
EXIT $exitstatus