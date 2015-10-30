Function Repair-WindowsUpdate {
    [cmdletbinding()]
    Param(
        [String[]] $ComputerName,
        [Switch] $DisableWSUS,
        
        [Switch] $Force,
        [int] $ServiceTimeOut = 180
    ) 

    Begin {
        [int] $pad = 50
        [String[]] $Service = 'CryptSvc', 'wuauserv', 'BITS', 'appidsvc'
        [String[]] $Folders = '\\{0}\admin$\SoftwareDistribution', '\\{0}\admin$\system32\catroot2'
        [String]   $BitsTMP = '\\{0}\c$\ProgramData\Application Data\Microsoft\Network\Downloader\qmgr*.dat'
        [String]   $UpdateLog = '\\{0}\admin$\WindowsUpdate.log'
        [Array]    $regsvr32 = @("atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll","jscript.dll","vbscript.dll","scrrun.dll","msxml.dll","msxml3.dll","msxml6.dll","actxprxy.dll","softpub.dll","wintrust.dll","dssenh.dll","rsaenh.dll","gpkcsp.dll","sccbase.dll","slbcsp.dll","cryptdlg.dll","oleaut32.dll","ole32.dll","shell32.dll","initpki.dll","wuapi.dll","wuaueng.dll","wuaueng1.dll","Regsvr32.exe-wucltui.dll","wups.dll","wups2.dll","wuweb.dll","qmgr.dll","qmgrprxy.dll","wuweb.dll","muweb.dll","wuwebv.dll")
    }


    Process {
        ForEach($Node in $ComputerName) {
            if (Test-Connection -Count 1 -Quiet -ComputerName $Node) {
                
                # Stop Services used by Windows Update
                Get-Service -ComputerName $Node | Where-Object { $Service -contains $_.Name -and $_.Status -ne "Stopped" } | ForEach {
                     Write-Host "Stopping $($_.Name) ...".PadRight($pad) -NoNewline
                     try { $_.Stop() } Catch {} Finally { $_.WaitForStatus("Stopped",'00:00:20') }
                     $_.WaitForStatus("Stopped",'00:00:20') 
                     Write-Host "Stopped"
                }


                # Rename WU Folders
                ForEach($Path in $Folders) 
                {
                    $Location = $Path -f $Node  
                    if (Test-Path $Location) {
                        Write-Verbose "$Location Exists"
                        $Parent = Split-Path -Path $Location -Parent
                        $Leaf = Split-Path -Path $Location -Leaf
                        $NewName = $Leaf + ".old"
                        $NewPath = Join-Path -Path $Parent -ChildPath $NewName
                        if (Test-Path -Path $newPath -IsValid) {
                            if (Test-Path -Path $NewPath) {
                                Write-Host "Removing old: $Leaf ...".PadRight(50) -NoNewline
                                Remove-Item -Path $NewPath -Force -Recurse
                                Write-Host "Done"
                            }
                            Write-Host "Renaming $Leaf ...".PadRight(50) -NoNewline
                            Rename-Item -Path "$Location" -NewName $NewName -Force
                            Write-Host "Done"
                        }
                        else { Write-Error "$NewPath is not valid" }
                    } 
                    else { Write-Verbose "Skipping $Location" }
                }

                #Delete Bits Tmp files
                Resolve-Path -Path ($BitsTMP -f $node) | Remove-Item -Force
                Resolve-Path -Path ($UpdateLog -f $node) | Remove-item -Force

                #Reset WU and BITS to default security descriptor
                Invoke-Command -ComputerName $Node -ScriptBlock { 
                    $win = [System.Environment]::GetEnvironmentVariable("windir")
                    Write-host "Reset BITS Security discr ...".PadRight(50) -NoNewline
                    Start-Process -FilePath (Join-Path -Path $win -ChildPath "\System32\sc.exe") -WorkingDirectory (Join-Path -Path $win -ChildPath "\System32\") -ArgumentList "sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" -WindowStyle Hidden -Wait
                    Write-Host "Done"
                    Write-host "Reset WU Security discr ...".PadRight(50) -NoNewline
                    Start-Process -FilePath (Join-Path -Path $win -ChildPath "\System32\sc.exe") -WorkingDirectory (Join-Path -Path $win -ChildPath "\System32\") -ArgumentList "sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" -WindowStyle Hidden -Wait
                    Write-Host "Done"
                }

                #Re-Register DLL's
                Invoke-Command -ComputerName $Node -ArgumentList (,$regsvr32) -ScriptBlock {
                    Param([Array] $regsvr32)

                    $win = [System.Environment]::GetEnvironmentVariable("windir")
                    $regsvr32 | ForEach { 
                        Write-Host "Registering $_ ...".PadRight(50) -NoNewline
                        Start-Process -FilePath (Join-Path -Path $win -ChildPath "\System32\regsvr32.exe") -WorkingDirectory (Join-Path -Path $win -ChildPath "\System32\") -ArgumentList ($_ + " /s") -WindowStyle Hidden -Wait -ErrorVariable $err
                        if ($err) { Write-Host "Failed"; Remove-Variable -Name err } else { Write-Host "Done" }
                    }
                }

                if ($DisableWSUS) {
                    Invoke-Command -ComputerName $Node -ScriptBlock {
                        if ((Get-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name UseWUserver) -eq 1) 
                        {
                            Write-Host "Disable WSUS ...".PadRight(50) -NoNewline
                            Set-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name UseWUServer -Value 0
                            Write-Host "Done"
                        } else { Write-Host ("Disable WSUS ...".PadRight(50) + "Skipped") }
                        if (Test-Path -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer) 
                        {
                            Write-Host "Removing WSUS Server ...".PadRight(50) -NoNewline
                            Remove-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\ -Name WUServer
                            Write-Host "Done"
                        } else { Write-Host ("Removing WSUS Server ...".PadRight(50) + "Skipped") } 
                        if (Test-Path -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUStatusServer) 
                        {
                            Write-Host "Removing Stats Server ...".PadRight(50) -NoNewline
                            Remove-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\ -Name WUStatusServer
                            Write-Host "Done"
                        } else {  Write-Host ("Removing Stats Server ...".PadRight(50) + "Skipped") }
                    }
                }



                # Starting all Services
                Get-Service -ComputerName $Node | Where-Object { $Service -contains $_.Name -and $_.Status -ne "Running" } | ForEach {
                     Write-Host "Starting $($_.Name) ...".PadRight($pad) -NoNewline
                     try { $_.Start() } Catch {} Finally { $_.WaitForStatus("Running",'00:00:20') }
                     Write-Host "Running"
                }

                Invoke-Command -ComputerName $Node -ScriptBlock { 
                    $win = [System.Environment]::GetEnvironmentVariable("windir")
                    Write-Host "Start Windows Update!".PadRight(50) -NoNewline
                    Start-Process (Join-path -Path $win -ChildPath "\System32\wuauclt.exe") -ArgumentList "/resetauthorization" -WorkingDirectory (Join-path -Path $win -ChildPath "\System32\") -WindowStyle Hidden -Wait
                    Start-Process (Join-path -Path $win -ChildPath "\System32\wuauclt.exe") -ArgumentList "/detectnow" -WorkingDirectory (Join-path -Path $win -ChildPath "\System32\") -WindowStyle Hidden -Wait
                    Write-Host "Done"
                }


            }
            Else { "$node offline" }
        }
    }
}
clear
Repair-WindowsUpdate -ComputerName mirjam-pc, styling2-pc, wms0001