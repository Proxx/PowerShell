Function Get-Software {
	Param (
		[Parameter(Mandatory=$true)]
		[String[]] $ComputerName = [System.Net.Dns]::GetHostName(),
		[int] $ThrottleLimit = 20,
		[Switch] $Progress
	)

	$RunspacePool = [RunspaceFactory ]::CreateRunspacePool(1, $ThrottleLimit)
	$RunspacePool.Open()

[ScriptBlock] $ScriptBlock = {
    Param ([string]	$ComputerName)

	#vars
	$Result = @()
	$UninstallKeys= @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
	
	if (Test-Connection -Count 1 -ComputerName $ComputerName -Quiet) {
		Try { $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$ComputerName) }
		Catch { 
			$RegError = "Failed"
			$Object = New-Object PSObject -Property @{
				ComputerName = $ComputerName
		        Name = $null
		        Version = [Version]$null
		        Location = $null
		        Publisher = $null
				UninstallString = $null
				GUID = $null
				Status = "Failed"
				Error = [String]$_.Exception.InnerException
			}
			$Result += $Object	
		}
		if ($reg) {
			ForEach ($Item in $UninstallKeys) {
				$SubKeyNames = $reg.OpenSubKey($Item).GetSubKeyNames()
				ForEach($SubKey in $SubKeyNames) {
					if ($SubKey -like "{*}") { $GUID = $SubKey } else { $GUID = $null }
					$FullKey = $Item+"\\"+$SubKey
					$key = $reg.OpenSubKey($FullKey) 
					if ($Key.GetValue("DisplayName")) {
						$Object = New-Object PSObject -Property @{
					        ComputerName = $ComputerName
					        Name = $Key.GetValue("DisplayName")
					        Version = $Key.GetValue("DisplayVersion")
					        Location = $Key.GetValue("InstallLocation")
					        Publisher = $Key.GetValue("Publisher")
							UninstallString = $Key.GetValue("UninstallString")
							GUID = $GUID
							Status = "OK"
							Error = ""
						}
						$Result += $Object
					}
				}
			}
		}
	} Else {
		$Result = New-Object PSObject -Property @{
			ComputerName = $ComputerName
	        Name = $null
	        Version = [Version]$null
	        Location = $null
	        Publisher = $null
			UninstallString = $null
			GUID = $null
			Status = "Offline"
			Error = [String]"Connection failed"
		}
	}
	Return $Result
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
	While($Queue){
		Foreach($Job in $Queue.ToArray()){
			If($Job.Status.IsCompleted){
				$x++
				if ($Progress) { Write-Progress -activity "Fetching Software" -status "Computers: ($x/$($ComputerName.count))" -PercentComplete (($x / $ComputerName.Count)  * 100) }
				$Results += $Job.Items.EndInvoke($Job.Status)
				$Job.Items.Dispose()
				$Queue.Remove($Job)
			}
		}
	}
	Write-Progress -activity "Fetching Software" -status "Computers: ($x/$($ComputerName.count))"  -Completed
	Return ($Results | Get-Unique -AsString | ?{ $_ })
}
