Function Start-Tests {
    <#
        .Synopsis
            Test with PSSCriptAnalyzer And Pester.
        .NOTES
            Author: Proxx
            Web:	www.Proxx.nl 
            Date:	27-08-2015
    #>
    Begin {
        $TempPath = Join-Path -Path $ENV:TEMP -ChildPath $([guid]::NewGuid()).Guid
        New-Item -Path "$TempPath\" -ItemType Directory | Out-Null

        if (! ($ENV:APPVEYOR))
        {
            #Initializing APPVEYOR variables when working offline for testing
            $Environment = @{}
            $Environment.APPVEYOR_BUILD_FOLDER = "D:\PowerShell\Module\Proxx.SQLite\"
            $Environment.APPVEYOR_PROJECT_NAME = Split-Path $Environment.APPVEYOR_BUILD_FOLDER -Leaf
            $Environment.APPVEYOR_BUILD_VERSION = Test-ModuleManifest -Path (Join-Path $Environment.APPVEYOR_BUILD_FOLDER -ChildPath $($Environment.APPVEYOR_PROJECT_NAME + ".psd1")) | Select-Object -ExpandProperty Version
            $Environment.access_token = $api
            Write-Host "Initializing Environment..."
            ForEach($Var in $Environment.GetEnumerator()) { 
                Set-Item -Path ("ENV:" + $Var.Name)  -Value $Var.Value
            }
        }
    }
    Process {
    "START PSScriptAnalyzer"
    Import-Module -Name PSScriptAnalyzer


    #Get longes rule name
    $RuleCount = 0
    $SeverityCount = 0
    Get-ScriptAnalyzerRule | select -ExpandProperty RuleName | %{ if ($_.ToCharArray().Count -gt $RuleCount) { $RuleCount = $_.ToCharArray().Count }}
    Get-ScriptAnalyzerRule | select -Unique -ExpandProperty Severity | %{ if ($_.ToString().TocharArray().Count -gt $SeverityCount) { $SeverityCount = $_.ToString().TocharArray().Count }}

    $RuleTotal = $RuleCount + 1
    $SeverityTotal = $SeverityCount + 1
    $LineTotal = 7

    #Write-Object function with colors

    " "
    "{0}{1}{2}{3}" -f "RuleName".PadRight($RuleTotal),"Severity".PadRight($SeverityTotal),"Line".PadRight($LineTotal),"FileName"
    "{0}{1}{2}{3}" -f "--------".PadRight($RuleTotal),"--------".PadRight($SeverityTotal),"----".PadRight($LineTotal),"--------"
    $SB = New-Object System.Text.StringBuilder
    Invoke-ScriptAnalyzer -Path $($ENV:APPVEYOR_BUILD_FOLDER + '\') -Recurse | ForEach {
        [Void] $SB.Clear()
        [Void] $SB.Append($_.RuleName.ToString().PadRight($RuleTotal))
        [Void] $SB.Append($_.Severity.toString().PadRight($SeverityTotal))
        [Void] $SB.Append($_.Line.ToString().PadRight($LineTotal))
        [Void] $SB.Append($_.ScriptName)
        Switch ($_.Severity) {
            "Information" { $Color = "White"; $Outcome = "Failed"; $throw = $true  }
            "Warning" { $Color = "Yellow"; $Outcome = "Ignored"   }
            "Error" { $Color = "Red"; $Outcome = "Ignored"   }
        }
        Add-AppveyorTest -Name $_.RuleName -FileName $_.ScriptName -Outcome $Outcome -ErrorMessage $_.Message -ErrorStackTrace $_.Extent
        Write-Host -ForegroundColor $Color $SB.ToString()
    }


    if (Test-Path -Path "$($ENV:APPVEYOR_BUILD_FOLDER)\Tests") {
        "START PESTER"
        Import-Module -Name $($ENV:APPVEYOR_PROJECT_NAME)
        Import-Module -Name Pester
        $Pester = Invoke-Pester -Path "$($ENV:APPVEYOR_BUILD_FOLDER)\Tests" -OutputFormat NUnitXml -OutputFile $TempPath\PesterResults.xml -PassThru
        if ($Pester.FailedCount -gt 0) { $throw = $true }
            
    }


    }

    End {
        if (!($ENV:APPVEYOR))
        {
            Write-Host "Cleaning Environment..."
            ForEach($Var in $Environment.GetEnumerator()) { 
                Remove-Item -Path ("ENV:" + $Var.Name)
            }
        }
        else
        {
            Get-ChildItem  -Path "$TempPath\*.xml" | Sort LastWriteTime -Descending | Foreach-Object {
        
                $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
                $Source = $_.FullName

                "UPLOADING FILES: $Address $Source"
                (New-Object 'System.Net.WebClient').UploadFile($Address, $Source)
            }
        }
        if ($throw) { Exit 1 }
    }
}
Start-Tests