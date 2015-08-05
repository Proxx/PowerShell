Function Get-ProductKey {
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory=$true)][String[]] $ComputerName = [System.Net.Dns]::GetHostName(),
		[int] $ThrottleLimit = 20,
		[Switch] $Progress
	)

	$RunspacePool = [RunspaceFactory ]::CreateRunspacePool(1, $ThrottleLimit)
	$RunspacePool.Open()


[ScriptBlock] $ScriptBlock = {
	Param(
		[string]$Computer,
		[Switch]$Progress
	)
	$Result = @()
	$map="BCDFGHJKMPQRTVWXY2346789" 
	if (Test-Connection -Count 1 -ComputerName $Computer -Quiet) {
		Try {
            $OS = Get-WmiObject -ComputerName $Computer Win32_OperatingSystem -ErrorAction Stop                
        } Catch { }
        Try {
            $remoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            If ($OS.OSArchitecture -eq '64-bit') {
                $value = $remoteReg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DigitalProductId4')[0x34..0x42]
            } Else {                        
                $value = $remoteReg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DigitalProductId')[0x34..0x42]
            }
            $ProductKey = ""  
            for ($i = 24; $i -ge 0; $i--) { 
              $r = 0 
              for ($j = 14; $j -ge 0; $j--) { 
                $r = ($r * 256) -bxor $value[$j] 
                $value[$j] = [math]::Floor([double]($r/24)) 
                $r = $r % 24 
              } 
              $ProductKey = $map[$r] + $ProductKey 
              if (($i % 5) -eq 0 -and $i -ne 0) { 
                $ProductKey = "-" + $ProductKey 
              } 
            }
			$Object = New-Object PSObject -Property @{
	            ComputerName = $Computer
	            ProductKey = $ProductKey
	            OS = $os.Caption
	            Version = $os.Version
			}
			$Result += $Object
        } Catch { }        
	}
    return $Result
}

	[Collections.Arraylist] $Queue = @()
	ForEach($Computer in $ComputerName) {
		$Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($Computer)
		$Job.RunspacePool = $RunspacePool
		$Queue += New-Object PSObject -Property @{
			Items = $Job
			Status = $Job.BeginInvoke()
		}
	}

	$x = 0
	$Results = @()
	$Count = $ComputerName.Count
	While($Queue){
		Foreach($Job in $Queue.ToArray()){
			If($Job.Status.IsCompleted){
				$x++
				if ($Progress) { Write-Progress -Activity "Fetching Disks information from Computers" -Status "Computers: ($x/$Count)" -PercentComplete (($x / $Count)  * 100) }
				$Results += $Job.Items.EndInvoke($Job.Status)
				$Job.Items.Dispose()
				$Queue.Remove($Job)
			}
		}
	}
    if ($Progress) { Write-Progress -Activity "Fetching Disks information from Computers" -Status "Computers: ($x/$Count)" -Completed }
	Return $Results | ? {$_}
}
