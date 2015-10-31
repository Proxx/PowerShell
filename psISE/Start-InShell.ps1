if ($psISE) {
    Function Start-InShell {
        [CmdletBinding()]
        Param(
            [String] $Path=$psISE.CurrentFile.FullPath,
            [Switch] $RunAs,
            [Switch] $Exit,
            [Switch] $Force
        )
        $Params = @{}
        if ($Exit) { $Arguments = '-File "{0}"' -f $Path }
        else { $Arguments = '-NoExit -File "{0}"' -f $Path }

        if ($RunAs) { $Params.Add("Verb","RunAs") }
        if ($Force) { $psISE.CurrentFile.Save() }
        if ($psISE.CurrentFile.IsSaved -AND $(Test-Path -Path $psISE.CurrentFile.FullPath)) {
            Start-Process @Params -FilePath "$PSHOME\powershell.exe" -ArgumentList $Arguments
        }
        else 
        {
            Write-Error -Message "Unsaved File!"
        }
    }

    if (-Not ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus  | Where-Object { $_.DisplayName -eq "Run In Shell" } )) {
        [Void] $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Run in Shell",{ Start-InShell},"ALT + S")
    }
    if (-Not ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus  | Where-Object { $_.DisplayName -eq "Run In Shell (Admin)" } )) {
        [Void] $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Run in Shell (Admin)",{ Start-InShell -RunAs },$null)
    }
}