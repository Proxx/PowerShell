Function Get-RemoteDesktop {
    Param($ComputerName)

     Switch(Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace root\cimv2\terminalservices -Property AllowTSConnections | Select-Object -ExpandProperty AllowTSConnections) {
        1 { $true }
        0 { $false }
    }

}
Function Set-RemoteDesktop {
    Param(
       [String[]] $ComputerName,
       [Switch] $Enable,
       [Switch] $Disable
    )

    $obj = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace root\cimv2\terminalservices -ErrorAction SilentlyContinue

    if ($obj) 
    {
        if ($Enable) { $x = 1 }
        if ($Disable) { $x = 0 }
        Try {
            if (($obj.SetAllowTSConnections($x,$x) | Select-Object -ExpandProperty ReturnValue) -eq 0) { $true }
            else { $false }
        } catch { throw "There was a problem changing remote desktop. Make sure your operating system supports remote desktop and there is no group policy preventing you from enabling it." }
    }
    else 
    {
        throw "Unable to locate terminalservices namespace. Remote Desktop is not enabled"
    }
}
