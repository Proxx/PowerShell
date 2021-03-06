﻿function Install-WindowsUpdate {
<#
.SYNOPSIS
Downloads and installs updates via Windows Update

.DESCRIPTION
This uses the windows update service to search, download and install updates. By default, only critical updates are included and a reboot will be induced if required.

.PARAMETER GetUpdatesFromMS
If this switch is set, the default windows update server, if any, is bypassed and windows update requests go to the public Microsoft Windows update service.

.PARAMETER AcceptEula
If any update requires a Eula acceptance, setting this switch will accept the Eula and allow the update to be installed.

.PARAMETER SuppressReboots
Setting this switch will suppress a reboot in the event that any update requires one.

.PARAMETER Criteria
The criteria used for searching updates. The default criteria is "IsHidden=0 and IsInstalled=0 and Type='Software'" which is effectively just critical updates.

.LINK
http://boxstarter.org

#>    
    param(
        [switch]$getUpdatesFromMS, 
        [switch]$acceptEula, 
        [switch]$SuppressReboots,
        [string]$criteria="IsHidden=0 and IsInstalled=0 and Type='Software' and BrowseOnly=0"
    )

    try{
        $updateSession =new-object -comobject "Microsoft.Update.Session"
        $Downloader =$updateSession.CreateUpdateDownloader()
        $Installer =$updateSession.CreateUpdateInstaller()
        $Searcher =$updatesession.CreateUpdateSearcher()
        if($getUpdatesFromMS) {
            $Searcher.ServerSelection = 2 #2 is the Const for the Windows Update server
        }
        $wus=Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'"
        $origStatus=$wus.State
        $origStartupType=$wus.StartMode
        Write-Message "Update service is in the $origStatus state and its startup type is $origStartupType" -verbose
        if($origStartupType -eq "Auto"){
            $origStartupType = "Automatic"
        }
        if($origStatus -eq "Stopped"){
            if($origStartupType -eq "Disabled"){
                Set-Service wuauserv -StartupType Automatic
            }
            Start-Service -Name wuauserv
        }
        else {
            # Restart in case updates are running in the background
        }

        $Result = $Searcher.Search($criteria)
        $totalUpdates = $Result.updates.count

        If ($totalUpdates -ne 0)
        {
            $currentCount = 0
            foreach($update in $result.updates) {
                ++$currentCount
                if(!($update.EulaAccepted)){
                    if($acceptEula) {
                        $update.AcceptEula()
                    }
                    else {
                        continue
                    }
                }

                $Result= $null
                if ($update.isDownloaded -eq "true" -and ($update.InstallationBehavior.CanRequestUserInput -eq $false )) {
                    $result = install-Update $update $currentCount $totalUpdates
                }
                elseif($update.InstallationBehavior.CanRequestUserInput -eq $true) {
                }
                else {
                    Download-Update $update
                    $result = Install-Update $update $currentCount $totalUpdates
                }
            }

            if($result -ne $null -and $result.rebootRequired) {
                if($SuppressReboots) {
                } else {
                    Stop-TimedSection $installSession
                    if(test-path function:\Invoke-Reboot) {
                        return Invoke-Reboot
                    } else {
                        Restart-Computer -force
                    }
                }
            }
        }
        else{}    
    }
    catch {
        Out-BoxstarterLog "There were problems installing updates: $($_.ToString())"
        throw
    }
    finally {
        if($origAUVal){
            Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWuServer -Value $origAUVal -ErrorAction SilentlyContinue
        }
        if($origStatus -eq "Stopped")
        {
            Out-BoxstarterLog "Stopping win update service and setting its startup type to $origStartupType" -verbose
            Set-Service wuauserv -StartupType $origStartupType
            Remove-BoxstarterError { stop-service wuauserv -WarningAction SilentlyContinue }
        }
    }
}

function Download-Update($update) {
    $downloadSession=Start-TimedSection "Download of $($update.Title)"
    $updates= new-Object -com "Microsoft.Update.UpdateColl"
    $updates.Add($update) | out-null
    $Downloader.Updates = $updates
    $Downloader.Download() | Out-Null
    Stop-TimedSection $downloadSession
}

function Install-Update($update, $currentCount, $totalUpdates) {
    $installSession=Start-TimedSection "Install $currentCount of $totalUpdates updates: $($update.Title)"
    $updates= new-Object -com "Microsoft.Update.UpdateColl"
    $updates.Add($update) | out-null
    $Installer.updates = $Updates
    try { $result = $Installer.Install() } catch {
        if(!($SuppressReboots) -and (test-path function:\Invoke-Reboot)){
            if(Test-PendingReboot){
                $global:error.RemoveAt(0)            
                Invoke-Reboot
            }
        }
        # Check for WU_E_INSTALL_NOT_ALLOWED  
        if($_.Exception.HResult -eq -2146233087) {
            Out-BoxstarterLog "There is either an update in progress or there is a pending reboot blocking the install."
            $global:error.RemoveAt(0)
        }
        else { throw }
    }
    Stop-TimedSection $installSession
    return $result
}

Install-WindowsUpdate -acceptEula -SuppressReboots