<#
.SYNOPSIS
    ConfigMgr Client Health is a tool that validates and automatically fixes errors on Windows computers managed by Microsoft Configuration Manager.    
.EXAMPLE 
   .\ConfigMgrClientHealth.ps1 -Config .\Config.Xml
.EXAMPLE 
    \\cm01.rodland.lab\ClientHealth$\ConfigMgrClientHealth.ps1 -Config \\cm01.rodland.lab\ClientHealth$\Config.Xml -Webservice https://cm01.rodland.lab/ConfigMgrClientHealth
.ParamETER Config
    A single Parameter specifying the path to the configuration XML file.
.ParamETER Webservice
    A single Parameter specifying the URI to the ConfigMgr Client Health Webservice.
.DESCRIPTION
    ConfigMgr Client Health detects and fixes following errors:
        * ConfigMgr client is not installed.
        * ConfigMgr client is assigned the correct site code.
        * ConfigMgr client is upgraded to current version if not at specified minimum version.
        * ConfigMgr client not able to forward state messages to management point.
        * ConfigMgr client stuck in provisioning mode.
        * ConfigMgr client maximum log file size.
        * ConfigMgr client cache size.
        * Corrupt WMI.
        * Services for ConfigMgr client is not running or disabled.
        * Other services can be specified to start and run and specific state.
        * Hardware inventory is running at correct schedule
        * Group Policy failes to update regisTry.pol
        * Pending reboot blocking updates from installing
        * ConfigMgr Client Update Handler is working correctly with regisTry.pol
        * Windows Update Agent not working correctly, causing client not to receive patches.
        * Windows Update Agent missing patches that fixes known bugs.
.NOTES 
    You should run this with at least local administrator rights. It is recommended to run this script under the SYSTEM context.
    
    DO NOT GIVE USERS WRITE ACCESS TO THIS FILE. LOCK IT DOWN !
    
    Author: Anders Rødland
    Blog: https://www.andersrodland.com
    Twitter: @AndersRodland
.LINK
    Full documentation: https://www.andersrodland.com/configmgr-client-health/
#> 
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
Param(
    [Parameter(HelpMessage='Path to XML Configuration File')]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [ValidatePattern('.xml$')]
    [string]$Config,
    [Parameter(HelpMessage='URI to ConfigMgr Client Health Webservice')]
    [string]$Webservice
)
Begin{
    # ConfigMgr Client Health Version
    $Version='0.8.1'
    $PowerShellVersion=[int]$PSVersionTable.PSVersion.Major
    $global:ScriptPath=split-path -parent $MyInvocation.MyCommand.Definition
    #If no config file was passed in, use the default.
    If(!$Config){$Config=Join-Path($global:ScriptPath) "Config.xml"}
    Write-Verbose "Script version: $Version"
    Write-Verbose "PowerShell version: $PowerShellVersion"
    Function Test-XML{[CmdletBinding()]Param([Parameter(mandatory=$true)][ValidateNotNullorEmpty()][string]$xmlFilePath)
        If(!(Test-Path -Path $xmlFilePath)){throw "$xmlFilePath is not valid. Please provide a valid path to the .xml config file"}
        # Check for Load or Parse errors when loading the XML file
        $xml=New-Object System.Xml.XmlDocument
        Try{
            $xml.Load((Get-ChildItem -Path $xmlFilePath).FullName)
            Return $true
        }Catch [System.Xml.XmlException]{
            Write-Error "$xmlFilePath : $($_.toString())"
            Write-Error "Configuration file $Config is NOT valid XML. Script will not execute."
            Return $false
        }
    }
    # Read configuration from XML file
    If(Test-Path $Config){
        # Test if valid XML
        If((Test-XML -xmlFilePath $Config)-ne$true){Exit 1}
        # Load XML file into variable
        Try{
            $Xml=[xml](Get-Content -Path $Config)
        }Catch{
            $ErrorMessage=$_.Exception.Message
            $text="Error, could not read $Config. Check file location and share/ntfs permissions. Is XML config file damaged?"
            $text+="`nError message: $ErrorMessage"
            Write-Error $text
            Exit 1
        }
    }Else{
        $text="Error, could not access $Config. Check file location and share/ntfs permissions. Did you misspell the name?"
        Write-Error $text
        Exit 1
    }
    # Import Modules
    # Import BitsTransfer Module(Does not work on PowerShell Core(6), disable check if module failes to import.)    
    $BitsCheckEnabled=$false
    Try{
        Import-Module BitsTransfer -ErrorAction stop
        $BitsCheckEnabled=$true
    }Catch{
        $BitsCheckEnabled=$false
    }
    #region functions
    Function Get-DateTime{
        $format=(Get-XMLConfigLoggingTimeFormat).ToLower()
        # UTC Time
        If($format -like "utc"){
            $obj=([DateTime]::UtcNow).ToString("yyyy-MM-dd HH:mm:ss")
        # ClientLocal
        }Else{
            $obj=(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        Write-Output $obj
    }
    # Converts a DateTime object to UTC time.
    Function Get-UTCTime{Param([Parameter(Mandatory=$true)][DateTime]$DateTime)
        $obj=$DateTime.ToUniversalTime()
        Write-Output $obj
    }
    Function Get-Hostname{
        If($PowerShellVersion-ge6){
            $Obj=(Get-CimInstance Win32_ComputerSystem).Name
        }Else{
            $Obj=(Get-WmiObject Win32_ComputerSystem).Name
        }
        Write-Output $Obj
    }
    # Update-WebService use ClientHealth Webservice to update database. RESTful API.
    Function Update-Webservice{Param([Parameter(Mandatory=$true)][String]$URI, $Log)
        $Hostname=Get-Hostname
        $Obj=$Log|ConvertTo-Json
        $URI=$URI+"/Clients"
        $ContentType="application/json"
        # Detect if we use PUT or POST
        Try{
            Invoke-RestMethod -Uri "$URI/$Hostname"|Out-Null
            $Method="PUT"
            $URI=$URI+"/$Hostname"
        }Catch{
            $Method="POST"
        }
        Try{
            Invoke-RestMethod -Method $Method -Uri $URI -Body $Obj -ContentType $ContentType|Out-Null
        }Catch{
            $ExceptionMessage=$_.Exception.Message
            Write-Host "Error Invoking RestMethod $Method on URI $URI. Failed to update database using webservice. Exception: $ExceptionMessage"
        }
    }
    Function Get-LogFileName{
        #$OS=Get-WmiObject -class Win32_OperatingSystem
        #$OSName=Get-OperatingSystem
        $logshare=Get-XMLConfigLoggingShare
        #$obj="$logshare\$OSName\$env:computername.log"
        $obj="$logshare\$env:computername.log"
        Write-Output $obj
    }
    Function Get-ServiceUpTime{Param([Parameter(Mandatory=$true)]$Name)
        Try{
            $ServiceDisplayName=(Get-Service $Name).DisplayName
        }Catch{
            Write-Warning "The '$($Name)' service could not be found."
            Return
        }
        #First Try and get the service start time based on the last start event message in the system log.
        Try{
            [datetime]$ServiceStartTime=(Get-EventLog -LogName System -Source Service Control Manager -EnTryType Information -Message *$($ServiceDisplayName)*running* -Newest 1).TimeGenerated
            Return(New-TimeSpan -Start $ServiceStartTime -End(Get-Date)).Days
        }Catch{
            Write-Verbose "Could not get the uptime time for the '$($Name)' service from the event log.  Relying on the process instead."
        }
        #If the event log doesn't contain a start event then use the start time of the service's process.  Since processes can be shared this is less reliable.
        Try{
            If($PowerShellVersion-ge6){
                $ServiceProcessID=(Get-CimInstance Win32_Service -Filter "Name='$($Name)'").ProcessID
            }Else{
                $ServiceProcessID=(Get-WMIObject -Class Win32_Service -Filter "Name='$($Name)'").ProcessID
            }
            [datetime]$ServiceStartTime=(Get-Process -Id $ServiceProcessID).StartTime
            Return(New-TimeSpan -Start $ServiceStartTime -End(Get-Date)).Days
        }Catch{
            Write-Warning "Could not get the uptime time for the '$($Name)' service.  Returning max value."
            Return [int]::MaxValue
        }
    }
    #Loop backwards through a Configuration Manager log file looking for the latest matching message after the start time.
    Function Search-CMLogFile{Param([Parameter(Mandatory=$true)]$LogFile,[Parameter(Mandatory=$true)][String[]]$SearchStrings,[datetime]$StartTime=[datetime]::MinValue)
        #Get the log data.
        $LogData=Get-Content $LogFile        
        #Loop backwards through the log file.
        For($i=($LogData.Count-1);$i-ge0;$i--){
            #Parse the log line into its parts.
            Try{
                $LogData[$i]-match'\<\!\[LOG\[(?<Message>.*)?\]LOG\]\!\>\<time=\"(?<Time>.+)(?<TZAdjust>[+|-])(?<TZOffset>\d{2,3})\"\s+date=\"(?<Date>.+)?\"\s+component=\"(?<Component>.+)?\"\s+context="(?<Context>.*)?\"\s+type=\"(?<Type>\d)?\"\s+thread=\"(?<TID>\d+)?\"\s+file=\"(?<Reference>.+)?\"\>'|Out-Null
                $LogTime=[datetime]::ParseExact($("$($matches.date) $($matches.time)"),"MM-dd-yyyy HH:mm:ss.fff", $null)
                $LogMessage=$matches.message
            }Catch{
                Write-Warning "Could not parse the line $($i) in '$($LogFile)': $($LogData[$i])"
            }
            #If we have gone beyond the start time then stop searching.
            If($LogTime-lt$StartTime){
                Write-Verbose "No log lines in $($LogFile) matched $($SearchStrings) before $($StartTime)."
                Return
            }
            #Loop through each search string looking for a match.
            ForEach($String in $SearchStrings){
                If($LogMessage-match$String){
                    Return $LogData[$i]
                }
            }
        }
        #Looped through log file without finding a match.
        Return
    }
    Function Test-LocalLogging{
        $clientpath=Get-LocalFilesPath
        If((Test-Path -Path $clientpath)-eq$False){New-Item -Path $clientpath -ItemType Directory -Force|Out-Null}
    }
    Function Out-LogFile{Param([Parameter(Mandatory=$false)][xml]$Xml, $Text, $Mode)
        If($Mode -like "Local"){
            Test-LocalLogging
            $clientpath=Get-LocalFilesPath
            $Logfile="$clientpath\ClientHealth.log"
        }Else{
            $Logfile=Get-LogFileName
        }
        If($mode -like "ClientInstall"){
            $text="ConfigMgr Client installation failed. Agent not detected 10 minutes after triggering installation."
        }
        $obj='['+(Get-DateTime)+'] '+$text
        $obj|Out-File -Encoding utf8 -Append $logFile
    }
    Function Get-OperatingSystem{
        If($PowerShellVersion-ge6){
            $OS=Get-CimInstance Win32_OperatingSystem
        }Else{
            $OS=Get-WmiObject Win32_OperatingSystem
        }
        # Handles different OS languages
        $OSArchitecture=($OS.OSArchitecture-replace('([^0-9])(\.*)', ''))+'-Bit'
        Switch -Wildcard($OS.Caption){
            "*Embedded*"{$OSName="Windows 7 "+$OSArchitecture}
            "*Windows 7*"{$OSName="Windows 7 "+$OSArchitecture}
            "*Windows 8.1*"{$OSName="Windows 8.1 "+$OSArchitecture}
            "*Windows 10*"{$OSName="Windows 10 "+$OSArchitecture}
            "*Server 2008*"{
                If($OS.Caption -like "*R2*"){
                    $OSName="Windows Server 2008 R2 "+$OSArchitecture
                }Else{
                    $OSName="Windows Server 2008 "+$OSArchitecture
                }
            }
            "*Server 2012*"{
                If($OS.Caption -like "*R2*"){
                    $OSName="Windows Server 2012 R2 "+$OSArchitecture
                }Else{
                    $OSName="Windows Server 2012 "+$OSArchitecture
                }
            }
            "*Server 2016*"{$OSName="Windows Server 2016 "+$OSArchitecture}
        }
        Write-Output $OSName
    }
    Function Get-MissingUpdates{
        $UpdateShare=Get-XMLConfigUpdatesShare
        $OSName=Get-OperatingSystem
        $build=$null
        If($OSName -like "*Windows 10*"){
            $build=Get-CimInstance Win32_OperatingSystem|Select-Object -ExpandProperty BuildNumber
            Switch($build){
                10240{$OSName=$OSName+" 1507"}
                10586{$OSName=$OSName+" 1511"}
                14393{$OSName=$OSName+" 1607"}
                15063{$OSName=$OSName+" 1703"}
                16299{$OSName=$OSName+" 1709"}
                17134{$OSName=$OSName+" 1803"}
                Default{$OSName=$OSName+" Insider Preview"}
            }
        }
        $Updates=$UpdateShare+"\"+$OSName+"\"
        $obj=New-Object PSObject @{}
        If((Test-Path $Updates)-eq$true){
            $regex="\b(?!(KB)+(\d+)\b)\w+"
            $hotfixes=(Get-ChildItem $Updates|Select-Object -ExpandProperty Name)
            If($PowerShellVersion-ge6){
                $installedUpdates=(Get-CimInstance -ClassName Win32_QuickFixEngineering).HotFixID
            }Else{
                $installedUpdates=Get-Hotfix|Select-Object -ExpandProperty HotFixID
            }
            ForEach($hotfix in $hotfixes){
                $kb=$hotfix-replace$regex-replace"\."-replace"-"
                If($installedUpdates -like $kb){
                }Else{
                    $obj.Add('Hotfix', $hotfix)
                }
            }
        }
        Write-Output $obj
    }
    Function Get-RegisTryValue{Param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path,[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Name)
        Return(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    }
    Function Set-RegisTryValue{Param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path,[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Name,[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Value,[ValidateSet("String","ExpandString","Binary","DWord","MultiString","Qword")]$ProperyType="String")
        #Make sure the key exists
        If(!(Test-Path $Path)){
            New-Item $Path -Force|Out-Null
        }
        New-ItemProperty -Force -Path $Path -Name $Name -Value $Value -PropertyType $ProperyType|Out-Null        
    }
    Function Get-Sitecode{
        Try{
            <#
            If($PowerShellVersion-ge6){
                $obj=(Invoke-CimMethod -Namespace "ROOT\ccm" -ClassName SMS_Client -MethodName GetAssignedSite).sSiteCode
            }Else{
                $obj=$([WmiClass]"ROOT\ccm:SMS_Client").getassignedsite()|Select-Object -Expandproperty sSiteCode
            }
            #>
            $sms=new-object -comobject 'Microsoft.SMS.Client'
            $obj=$sms.GetAssignedSite()
        }Catch{
            $obj='...'
        }Finally{
            Write-Output $obj
        }
    }
    Function Get-ClientVersion{
        Try{
            If($PowerShellVersion-ge6){
                $obj=(Get-CimInstance -Namespace root/ccm SMS_Client).ClientVersion
            }Else{
                $obj=(Get-WmiObject -Namespace root/ccm SMS_Client).ClientVersion
            }
        }Catch{
            $obj=$false
        }Finally{
            Write-Output $obj
        }
    }
    Function Get-ClientCache{
        Try{
            $obj=(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize
            <#
            If($PowerShellVersion-ge6){
                $obj=(Get-CimInstance -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig -ErrorAction SilentlyContinue).Size
            }Else{
                $obj=(Get-WmiObject -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig -ErrorAction SilentlyContinue).Size
            }
            #>
        }Catch{
            $obj=0
        }Finally{
            If($null-eq$obj){$obj=0}
            Write-Output $obj
        }
    }
    Function Get-ClientMaxLogSize{
        Try{
            $obj=[Math]::Round(((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxSize)/1000)
        }Catch{
            $obj=0
        }Finally{
            Write-Output $obj
        }
    }
    Function Get-ClientMaxLogHistory{
        Try{
            $obj=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxHistory
        }Catch{
            $obj=0
        }Finally{
            Write-Output $obj
        }
    }
    Function Get-Domain{
        Try{
            If($PowerShellVersion-ge6){
                $obj=(Get-CimInstance Win32_ComputerSystem).Domain
            }Else{
                $obj=(Get-WmiObject Win32_ComputerSystem).Domain
            }
        }Catch{
            $obj=$false
        }Finally{
            Write-Output $obj
        }
    }
    Function Get-CCMLogDirectory{
        $obj=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
        If($null-eq$obj){$obj="$env:SystemDrive\windows\ccm\Logs"}
        Write-Output $obj
    }
    Function Get-CCMDirectory{
        $logdir=Get-CCMLogDirectory
        $obj=$logdir.replace("\Logs", "")
        Write-Output $obj
    }
    <#
    .SYNOPSIS
    Function to test if local database files are missing from the ConfigMgr client. 
    .DESCRIPTION
    Function to test if local database files are missing from the ConfigMgr client. Will tag client for reinstall if less than 7. Returns $True if compliant or $False if non-compliant
    .EXAMPLE
    An example
    .NOTES
    Returns $True if compliant or $False if non-compliant. Non.compliant computers require remediation and will be tagged for ConfigMgr client reinstall.
    #>    
    Function Test-CcmSDF{
        $ccmdir=Get-CCMDirectory
        $files=Get-ChildItem "$ccmdir\*.sdf"
        If($files.Count-lt7){
            $obj=$false
        }Else{
            $obj=$true
        }
        Write-Output $obj
    }
    Function Test-CcmSQLCELog{
        $logdir=Get-CCMLogDirectory
        $ccmdir=Get-CCMDirectory
        $logFile="$logdir\CcmSQLCE.log"
        $logLevel=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').logLevel
        If((Test-Path -Path $logFile)-and($logLevel-ne0)){
            # Not in debug mode, and CcmSQLCE.log exists. This could be bad.
            $LastWriteTime=(Get-ChildItem $logFile).LastWriteTime
            $CreationTime=(Get-ChildItem $logFile).CreationTime
            $FileDate=Get-Date($LastWriteTime)
            $FileCreated=Get-Date($CreationTime)
            $now=Get-Date
            If((($now - $FileDate).Days-lt7)-and((($now-$FileCreated).Days)-gt7)){
                $text="CM client not in debug mode, and CcmSQLCE.log exists. This is very bad. Cleaning up local SDF files and reinstalling CM client"
                Write-Host $text -ForegroundColor Red
                # Delete *.SDF Files
                $Service=Get-Service -Name ccmexec
                $Service.Stop()
                $seconds=0
                Do{
                    Start-Sleep -Seconds 1
                    $seconds++
                }While(($Service.Status-ne"Stopped")-and($seconds-le60))
                # Do another test to make sure CcmExec service really is stopped
                If($Service.Status-ne"Stopped"){Stop-Service -Name ccmexec -Force}
                Write-Verbose "Waiting 10 seconds to allow file locking issues to clear up"
                Start-Sleep -seconds 10
                Try{
                    $files=Get-ChildItem "$ccmdir\*.sdf"
                    $files|Remove-Item -Force|Out-Null
                    Remove-Item -Path $logFile -Force|Out-Null
                }Catch{
                    Write-Verbose "Obviously that wasn't enough time"
                    Start-Sleep -Seconds 30
                    # We Try again
                    $files=Get-ChildItem "$ccmdir\*.sdf"
                    $files|Remove-Item -Force|Out-Null
                    Remove-Item -Path $logFile -Force|Out-Null
                }
                $obj=$true
            # CcmSQLCE.log has not been updated for two days. We are good for now.
            }Else{
                $obj=$false
            }
        # we are good
        }Else{
            $obj=$false
        }
        Write-Output $obj
    }
    Function Test-CCMCertificateError{Param([Parameter(Mandatory=$true)]$Log)
        # More checks to come
        $logdir=Get-CCMLogDirectory
        $logFile1="$logdir\ClientIDManagerStartup.log"
        $error1='Failed to find the certificate in the store'
        $error2='[RegTask] - Server rejected registration 3'
        $content=Get-Content -Path $logFile1
        $ok=$true
        If($content-match$error1){
            $ok=$false
            $text='ConfigMgr Client Certificate: Error failed to find the certificate in store. Attempting fix.'
            Write-Warning $text
            Stop-Service -Name ccmexec -Force
            # Name is persistant across systems.
            $cert="$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\19c5cf9c7b5dc9de3e548adb70398402_50e417e0-e461-474b-96e2-077b80325612"
            # CCM creates new certificate when missing.
            Remove-Item -Path $cert -Force -ErrorAction SilentlyContinue|Out-Null
            # Remove the error from the logfile to avoid double remediations based on false positives
            $newContent=$content|Select-String -pattern $Error1 -notmatch
            Out-File -FilePath $logfile -InputObject $newContent -Encoding utf8 -Force
            Start-Service -Name ccmexec
            # Update log object
            $log.ClientCertificate=$error1
        }
        #$content=Get-Content -Path $logFile2
        If($content-match$error2){
            $ok=$false
            $text='ConfigMgr Client Certificate: Error! Server rejected client registration. Client Certificate not valid. No auto-remediation.'
            Write-Error $text
            $log.ClientCertificate=$error2
        }
        If($ok=$true){
            $text='ConfigMgr Client Certificate: OK'
            Write-Output $text
            $log.ClientCertificate='OK'
        }
    }
    Function Test-BITS{Param([Parameter(Mandatory=$true)]$Log)
        If($BitsCheckEnabled-eq$true){
            $Errors=Get-BitsTransfer -AllUsers|Where-Object{($_.JobState -like "TransientError")-or($_.JobState -like "Transient_Error")-or($_.JobState -like "Error")}
            If($null-ne$Errors){
                $fix=(Get-XMLConfigBITSCheckFix).ToLower()
                If($fix-eq"true"){
                    $text="BITS: Error. Remediating"
                    $Errors|Remove-BitsTransfer -ErrorAction SilentlyContinue
                    Invoke-Expression -Command 'sc.exe sdset bits "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"'|out-null
                    $log.BITS='Remediated'
                    $obj=$true
                }Else{
                    $text="BITS: Error. Monitor only"
                    $log.BITS='Error'
                    $obj=$false
                }
            }Else{
                $text="BITS: OK"
                $log.BITS='OK'
                $Obj=$false
            }
        }Else{
            $text="BITS: PowerShell Module BitsTransfer missing. Skipping check"
            $log.BITS="PS Module BitsTransfer missing"
            $obj=$false
        }
        Write-Host $text
        Write-Output $Obj
    }
    Function New-ClientInstalledReason{Param([Parameter(Mandatory=$true)]$Message,[Parameter(Mandatory=$true)]$Log)
        If($null-eq$log.ClientInstalledReason){
            $log.ClientInstalledReason=$Message
        }Else{
            $log.ClientInstalledReason+=" $Message"
        }
    }
    Function Get-PendingReboot{
        $result=@{
        CBSRebootPending=$false
        WindowsUpdateRebootRequired=$false
        FileRenamePending=$false
        SCCMRebootPending=$false
        }
        #Check CBS RegisTry
        $key=Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
        If($null-ne$key){$result.CBSRebootPending=$true}
        #Check Windows Update
        $key=Get-Item 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
        If($null-ne$key){$result.WindowsUpdateRebootRequired=$true}
        #Check PendingFileRenameOperations
        $prop=Get-ItemProperty 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
        If($null-ne$prop){
            #PendingFileRenameOperations is not *must* to reboot?
            #$result.FileRenamePending=$true
        }
        Try{
            $util=[wmiclass]'\\.\root\ccm\clientsdk:CCM_ClientUtilities'
            $status=$util.DetermineIfRebootPending()
            If(($null-ne$status)-and$status.RebootPending){$result.SCCMRebootPending=$true}
        }Catch{
        }
        #Return Reboot required
        If($result.ContainsValue($true)){
            #$text='Pending Reboot: YES'
            $obj=$true
            $log.PendingReboot='Pending Reboot'
        }Else{
            $obj=$false
            $log.PendingReboot='OK'
        }
        Write-Output $obj
    }
    Function Get-ProvisioningMode{
        $regisTryPath='HKLM:\SOFTWARE\Microsoft\CCM\CcmExec'
        $provisioningMode=(Get-ItemProperty -Path $regisTryPath).ProvisioningMode
        If($provisioningMode-eq'true'){
            $obj=$true
        }Else{
            $obj=$false
        }
        Write-Output $obj
    }
    Function Get-OSDiskFreeSpace{
        If($PowerShellVersion-ge6){
            $driveC=Get-CimInstance -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object FreeSpace, Size
        }Else{
            $driveC=Get-WmiObject -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object FreeSpace, Size
        }
        $freeSpace=(($driveC.FreeSpace/$driveC.Size)*100)
        Write-Output([math]::Round($freeSpace,2))
    }
    Function Get-Computername{
        If($PowerShellVersion-ge6){
            $obj=(Get-CimInstance Win32_ComputerSystem).Name
        }Else{
            $obj=(Get-WmiObject Win32_ComputerSystem).Name
        }
        Write-Output $obj
    }
    Function Get-LastBootTime{
        If($PowerShellVersion-ge6){
            $wmi=Get-CimInstance Win32_OperatingSystem
        }Else{
            $wmi=Get-WmiObject Win32_OperatingSystem
        }
        $obj=$wmi.ConvertToDateTime($wmi.LastBootUpTime)
        Write-Output $obj
    }
    Function Get-LastInstalledPatches{Param([Parameter(Mandatory=$true)]$Log)
        # Reading date from Windows Update COM object.
        $Session=New-Object -ComObject Microsoft.Update.Session
        $Searcher=$Session.CreateUpdateSearcher()
        $HistoryCount=$Searcher.GetTotalHistoryCount()
        $OS=Get-OperatingSystem
        Switch -Wildcard($OS){
            "*Windows 7*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'AutomaticUpdates'}|Select-Object -ExpandProperty Date|Measure-Latest}
            "*Windows 8*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'AutomaticUpdatesWuApp'}|Select-Object -ExpandProperty Date|Measure-Latest}
            "*Windows 10*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'UpdateOrchestrator'}|Select-Object -ExpandProperty Date|Measure-Latest}
            "*Server 2008*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'AutomaticUpdates'}|Select-Object -ExpandProperty Date|Measure-Latest}
            "*Server 2012*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'AutomaticUpdatesWuApp'}|Select-Object -ExpandProperty Date|Measure-Latest}
            "*Server 2016*"{$Date=$Searcher.QueryHistory(0,$HistoryCount)|Where-Object{$_.ClientApplicationID-eq'UpdateOrchestrator'}|Select-Object -ExpandProperty Date|Measure-Latest}
        }
        # Reading date from PowerShell Get-Hotfix
        #$now=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        #$Hotfix=Get-Hotfix|Where-Object{$_.InstalledOn-le$now}|Select-Object -ExpandProperty InstalledOn -ErrorAction SilentlyContinue
        #$Hotfix=Get-Hotfix|Select-Object -ExpandProperty InstalledOn -ErrorAction SilentlyContinue
        If($PowerShellVersion-ge6){
            $Hotfix=Get-CimInstance -ClassName Win32_QuickFixEngineering|Select-Object @{Name="InstalledOn";Expression={[DateTime]::Parse($_.InstalledOn,$([System.Globalization.CultureInfo]::GetCultureInfo("en-US")))}}
        }Else{
            $Hotfix=Get-Hotfix|Select-Object @{l="InstalledOn";e={[DateTime]::Parse($_.psbase.properties["installedon"].value,$([System.Globalization.CultureInfo]::GetCultureInfo("en-US")))}}
        }
        $Hotfix=$Hotfix|Select-Object -ExpandProperty InstalledOn
        $Date2=$null
        If($null-ne$hotfix){
            $Date2=Get-Date($hotfix|Measure-Latest) -ErrorAction SilentlyContinue
        }
        If(($Date-ge$Date2)-and($null-ne$Date)){
            $Log.OSUpdates=Get-SmallDateTime -Date $Date
        }ElseIf(($Date2-gt$Date)-and($null-ne$Date2)){
            $Log.OSUpdates=Get-SmallDateTime -Date $Date2
        }
    }
    Function Measure-Latest{
        BEGIN{
            $latest=$null
        }PROCESS{
            If(($null-ne$_)-and(($null-eq$latest)-or($_-gt$latest))){$latest=$_}
        }END{
            $latest
        }
    }
    Function Test-LogFileHistory{Param([Parameter(Mandatory=$true)]$Logfile)
        $startString='<--- ConfigMgr Client Health Check starting --->'
        $content=''
        # Handle the network share log file
        If(Test-Path $logfile -ErrorAction SilentlyContinue){
            $content=Get-Content($logfile)
        }
        $maxHistory=Get-XMLConfigLoggingMaxHistory
        $startCount=[regex]::matches($content,$startString).count
        # Delete logfile if more start and stop entries than max history
        If($startCount-ge$maxHistory){
            If((Test-Path -Path $logfile -ErrorAction SilentlyContinue)-eq$true){
                Remove-Item $logfile -Force
            }
        }
    }
    Function Test-DNSConfiguration{Param([Parameter(Mandatory=$true)]$Log)
        #$dnsdomain=(Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled='true'").DNSDomain
        $fqdn=[System.Net.Dns]::GetHostEnTry([string]"localhost").HostName
        If($PowerShellVersion-ge6){
            $localIPs=Get-CimInstance Win32_NetworkAdapterConfiguration|Where-Object{$_.IPEnabled-match"True"}|Select-Object -ExpandProperty IPAddress
        }Else{
            $localIPs=Get-WmiObject Win32_NetworkAdapterConfiguration|Where-Object{$_.IPEnabled-match"True"}|Select-Object -ExpandProperty IPAddress
        }
        $dnscheck=[System.Net.DNS]::GetHostByName($fqdn)
        $OSName=Get-OperatingSystem
        If(($OSName-notlike"*Windows 7*")-and($OSName-notlike"*Server 2008*")){
            # This method is supported on Windows 8/Server 2012 and higher. More acurate than using .NET object method
            Try{
                $AvtiveAdapters=(get-netadapter|Where-Object{$_.Status -like "Up"}).Name
                $dnsServers=Get-DnsClientServerAddress|Where-Object{$_.InterfaceAlias -like $AvtiveAdapters}|Where-Object{$_.AddressFamily-eq2}|Select-Object -ExpandProperty ServerAddresses
                $dnsAddressList=Resolve-DnsName -Name $fqdn -Server($dnsServers|Select-Object -First 1) -Type A -DnsOnly|Select-Object -ExpandProperty IPAddress
            }Catch{
                # Fallback to depreciated method
                $dnsAddressList=$dnscheck.AddressList|Select-Object -ExpandProperty IPAddressToString
                $dnsAddressList=$dnsAddressList-replace("%(.*)", "")
            }
        }Else{
            # This method cannot guarantee to only resolve against DNS sever. Local cache can be used in some circumstances.
            # For Windows 7 only
            $dnsAddressList=$dnscheck.AddressList|Select-Object -ExpandProperty IPAddressToString
            $dnsAddressList=$dnsAddressList-replace("%(.*)", "")
        }
        $dnsFail=''
        $logFail=''
        Write-Verbose 'Verify that local machines FQDN matches DNS'
        If($dnscheck.HostName -like $fqdn){
            $obj=$true
            Write-Verbose 'Checking if one local IP matches on IP from DNS'
            Write-Verbose 'Loop through each IP address published in DNS'
            ForEach($dnsIP in $dnsAddressList){
                #Write-Host "Testing if IP address: $dnsIP published in DNS exist in local IP configuration."
                ##If($dnsIP -notin $localIPs){## Requires PowerShell 3. Works fine :(
                If($localIPs-notcontains$dnsIP){
                    $dnsFail+="IP '$dnsIP' in DNS record do not exist locally`n"
                    $logFail+="$dnsIP "
                    $obj=$false
                }
            }
        }Else{
            $hn=$dnscheck.HostName
            $dnsFail='DNS name: '+$hn+' local fqdn: '+$fqdn+' DNS IPs: '+$dnsAddressList+' Local IPs: '+$localIPs
            $obj=$false
            Write-Host $dnsFail
        }
        $FileLogLevel=((Get-XMLConfigLogginLevel).ToString()).ToLower()
        Switch($obj){
            $false{
                $fix=(Get-XMLConfigDNSFix).ToLower()
                If($fix-eq"true"){
                    $text='DNS Check: FAILED. IP address published in DNS do not match IP address on local machine. Trying to resolve by registerting with DNS server'
                    If($PowerShellVersion-ge4){
                        Register-DnsClient|out-null
                    }Else{
                        ipconfig /registerdns|out-null
                    }
                    Write-Host $text
                    $log.DNS=$logFail
                    If(!($FileLogLevel -like "clientlocal")){
                        Out-LogFile -Xml $xml -Text $text
                        Out-LogFile -Xml $xml -Text $dnsFail
                    }
                }Else{
                    $text='DNS Check: FAILED. IP address published in DNS do not match IP address on local machine. Monitor mode only, no remediation'
                    $log.DNS=$logFail
                    If(!($FileLogLevel -like "clientlocal")){
                        Out-LogFile -Xml $xml -Text $text
                    }
                    Write-Host $text
                }
            }
            $true{
                $text='DNS Check: OK'
                Write-Output $text
                $log.DNS='OK'
            }
        }
        #Write-Output $obj
    }
    # Function to test that 'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\' is set to '%USERPROFILE%\AppData\Roaming'. CCMSETUP will fail if not.
    # Reference: https://www.systemcenterdudes.com/could-not-access-network-location-appdata-ccmsetup-log/
    Function Test-CCMSetup1{
        New-PSDrive -PSProvider RegisTry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue|Out-Null
        $correctValue='%USERPROFILE%\AppData\Roaming'
        $currentValue=(Get-Item 'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\').GetValue('AppData', $null, 'DoNotExpandEnvironmentNames')
        # Only fix if the value is wrong
        If($currentValue-ne$correctValue){
            Set-ItemProperty -Path  'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\' -Name 'AppData' -Value $correctValue
        }
    }
    Function Test-Update{Param([Parameter(Mandatory=$true)]$Log)
        #If(($Xml.Configuration.Option|Where-Object{$_.Name -like 'Updates'}|Select-Object -ExpandProperty 'Enable') -like 'True'){
        $UpdateShare=Get-XMLConfigUpdatesShare
        #$UpdateShare=$Xml.Configuration.Option|Where-Object{$_.Name -like 'Updates'}|Select-Object -ExpandProperty 'Share'
        Write-Verbose "Validating required updates is installed on the client. Required updates will be installed if missing on client."
        #$OS=Get-WmiObject -class Win32_OperatingSystem
        $OSName=Get-OperatingSystem
        $build=$null
        If($OSName -like "*Windows 10*"){
            $build=Get-CimInstance Win32_OperatingSystem|Select-Object -ExpandProperty BuildNumber
            Switch($build){
                10240{$OSName=$OSName+" 1507"}
                10586{$OSName=$OSName+" 1511"}
                14393{$OSName=$OSName+" 1607"}
                15063{$OSName=$OSName+" 1703"}
                16299{$OSName=$OSName+" 1709"}
                17134{$OSName=$OSName+" 1803"}
                Default{$OSName=$OSName+" Insider Preview"}
            }
        }
        $Updates=(Join-Path $UpdateShare $OSName)
        If((Test-Path $Updates)-eq$true){
            $regex="\b(?!(KB)+(\d+)\b)\w+"
            $hotfixes=(Get-ChildItem $Updates|Select-Object -ExpandProperty Name)
            If($PowerShellVersion-ge6){
                $installedUpdates=(Get-CimInstance Win32_QuickFixEngineering).HotFixID
            }Else{
                $installedUpdates=Get-Hotfix|Select-Object -ExpandProperty HotFixID
            }
            $count=$hotfixes.count
            If(($count-eq0)-or($count-eq$null)){
                $text='Updates: No mandatory updates to install.'
                Write-Output $text
                $log.Updates='OK'
            }Else{
                $logEnTry=$null
                ForEach($hotfix in $hotfixes){
                    $kb=$hotfix-replace$regex-replace"\."-replace"-"
                    If($installedUpdates -like $kb){
                        $text="Update $hotfix"+": OK"
                        Write-Output $text
                    }Else{
                        If($null-eq$logEnTry){
                            $logEnTry=$kb
                        }Else{
                            $logEnTry+=", $kb"
                        }
                        $fix=(Get-XMLConfigUpdatesFix).ToLower()
                        If($fix-eq"true"){
                            $kbfullpath=Join-Path $updates $hotfix
                            $text="Update $hotfix"+": Missing. Installing now..."
                            Write-Warning $text
                            $temppath=Join-Path(Get-LocalFilesPath) "Temp"
                            If((Test-Path $temppath)-eq$false){New-Item -Path $temppath -ItemType Directory|Out-Null}
                            Copy-Item -Path $kbfullpath -Destination $temppath
                            $install=Join-Path $temppath $hotfix
                            wusa.exe $install /quiet /norestart
                            While(Get-Process wusa -ErrorAction SilentlyContinue){Start-Sleep -Seconds 2}
                            Remove-Item $install -Force -Recurse
                        }Else{
                            $text="Update $hotfix"+": Missing. Monitor mode only, no remediation."
                            Write-Warning $text
                        }
                    }
                    If($null-eq$logEnTry){
                        $log.Updates='OK'
                    }Else{
                        $log.Updates=$logEnTry
                    }
                }
            }
        }Else{
            $log.Updates='Failed'
            Write-Warning "Updates Failed: Could not locate update folder '$($Updates)'."
        }
    }
    Function Test-ConfigMgrClient{Param([Parameter(Mandatory=$true)]$Log)
        # Check if the SCCM Agent is installed or not.
        # If installed, perform tests to decide if reinstall is needed or not.
        If(Get-Service -Name ccmexec -ErrorAction SilentlyContinue){
            $text="Configuration Manager Client is installed"
            Write-Host $text
            # Lets not reinstall client unless tests tells us to.
            $Reinstall=$false
            # We test that the local database files exists. Less than 7 means the client is horrible broken and requires reinstall.
            $LocalDBFilesPresent=Test-CcmSDF
            If($LocalDBFilesPresent-eq$False){
                New-ClientInstalledReason -Log $Log -Message "ConfigMgr Client database files missing."
                Write-Host "ConfigMgr Client database files missing. Reinstalling..."
                # Add /ForceInstall to Client Install Properties to ensure the client is uninstalled before we install client again.
                #If(-NOT($clientInstallProperties -like "*/forceinstall*")){$clientInstallProperties=$clientInstallProperties+" /forceinstall"}
                $Reinstall=$true
                $Uninstall=$true
            }
            # Only test CM client local DB if this check is enabled
            $testLocalDB=(Get-XMLConfigCcmSQLCELog).ToLower()
            If($testLocalDB -like "enable"){
                Write-Host "Testing CcmSQLCELog"
                $LocalDB=Test-CcmSQLCELog
                If($LocalDB-eq$true){
                    # LocalDB is messed up
                    New-ClientInstalledReason -Log $Log -Message "ConfigMgr Client database corrupt."
                    Write-Host "ConfigMgr Client database corrupt. Reinstalling..."
                    $Reinstall=$true
                    $Uninstall=$true
                }
            }
            $CCMService=Get-Service -Name ccmexec -ErrorAction SilentlyContinue
            # Reinstall if we are unable to start the CM client
            If(($CCMService.Status-eq"Stopped")-and($LocalDB-eq$false)){
                Try{
                    Write-Host "ConfigMgr Agent not running. Attempting to start it."
                    If($CCMService.StartType-ne"Automatic"){
                        $text="Configuring service CcmExec StartupType to: Automatic(Delayed Start)..."
                        Write-Output $text
                        Set-Service -Name CcmExec -StartupType Automatic
                    }
                    Start-Service -Name CcmExec
                }Catch{
                    $Reinstall=$true
                    New-ClientInstalledReason -Log $Log -Message "Service not running, failed to start."
                }
            }
            If($reinstall-eq$true){
                $text="ConfigMgr Client Health thinks the agent need to be reinstalled.."
                Write-Host $text
                # Lets check that regisTry settings are OK before we Try a new installation.
                Test-CCMSetup1
                # Adding forceinstall to the client install properties to make sure previous client is uninstalled.
                #If(($localDB-eq$true)-and(-NOT($clientInstallProperties -like "*/forceinstall*"))){$clientInstallProperties=$clientInstallProperties+" /forceinstall"}
                Resolve-Client -Xml $xml -ClientInstallProperties $clientInstallProperties -FirstInstall $false
                $log.ClientInstalled=Get-SmallDateTime
                Start-Sleep 600
            }
        }Else{
            $text="Configuration Manager client is not installed. Installing..."
            Write-Host $text
            Resolve-Client -Xml $xml -ClientInstallProperties $clientInstallProperties -FirstInstall $true
            New-ClientInstalledReason -Log $Log -Message "No agent found."
            $log.ClientInstalled=Get-SmallDateTime
            #Start-Sleep 600
            # Test again if agent is installed
            If(Get-Service -Name ccmexec -ErrorAction SilentlyContinue){
            }Else{
                Out-LogFile -Mode "ClientInstall"
            }
        }
    }
    Function Test-ClientCacheSize{Param([Parameter(Mandatory=$true)]$Log)
        $ClientCacheSize=Get-XMLConfigClientCache
        If($PowerShellVersion-ge6){
            $Cache=Get-CimInstance -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig
        }Else{
            $Cache=Get-WmiObject -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig
        }
        $CurrentCache=Get-ClientCache
        If($ClientCacheSize-match'%'){
            $type='percentage'
            # percentage based cache based on disk space
            $num=$ClientCacheSize-replace'%'
            $num=($num/100)
            # TotalDiskSpace in Byte
            If($PowerShellVersion-ge6){
                $TotalDiskSpace=(Get-CimInstance -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object -ExpandProperty Size)
            }Else{
                $TotalDiskSpace=(Get-WmiObject -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object -ExpandProperty Size)
            }
            $ClientCacheSize=([math]::Round(($TotalDiskSpace * $num)/1048576))
        }Else{
            $type='fixed'
        }
        If($CurrentCache-eq$ClientCacheSize){
            $text="ConfigMgr Client Cache Size: OK"
            Write-Host $text
            $Log.CacheSize=$CurrentCache
            $obj=$false
        }Else{
            Switch($type){
                'fixed'{$text="ConfigMgr Client Cache Size: $CurrentCache. Expected: $ClientCacheSize. Redmediating."}
                'percentage'{
                    $percent=Get-XMLConfigClientCache
                    $text="ConfigMgr Client Cache Size: $CurrentCache. Expected: $ClientCacheSize($percent). Redmediating."
                }
            }
            Write-Warning $text
            #$Cache.Size=$ClientCacheSize
            #$Cache.Put()
            $log.CacheSize=$ClientCacheSize
            (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize="$ClientCacheSize"
            $obj=$true
        }
        Write-Output $obj
    }
    Function Test-ClientVersion{Param([Parameter(Mandatory=$true)]$Log)
        $ClientVersion=Get-XMLConfigClientVersion
        $installedVersion=Get-ClientVersion
        $log.ClientVersion=$installedVersion
        If($installedVersion-ge$ClientVersion){
            $text='ConfigMgr Client version is: '+$installedVersion+': OK'
            Write-Output $text
            $obj=$false
        }ElseIf((Get-XMLConfigClientAutoUpgrade).ToLower() -like 'true'){
            $text='ConfigMgr Client version is: '+$installedVersion+': Tagging client for upgrade to version: '+$ClientVersion
            Write-Warning $text
            $obj=$true
        }Else{
            $text='ConfigMgr Client version is: '+$installedVersion+': Required version: '+$ClientVersion+' AutoUpgrade: false. Skipping upgrade'
            Write-Output $text
            $obj=$false
        }
        Write-Output $obj
    }
    Function Test-ClientSiteCode{Param([Parameter(Mandatory=$true)]$Log)
        $sms=new-object -comobject "Microsoft.SMS.Client"
        $ClientSiteCode=Get-XMLConfigClientSitecode
        #[String]$currentSiteCode=Get-Sitecode
        $currentSiteCode=$sms.GetAssignedSite()
        $currentSiteCode=$currentSiteCode.Trim()
        $Log.Sitecode=$currentSiteCode
        # Do more investigation and testing on WMI Method "SetAssignedSite" to possible avoid reinstall of client for this check.
        If($ClientSiteCode -like $currentSiteCode){
            $text="ConfigMgr Client Site Code: OK"
            Write-Host $text
            #$obj=$false
        }Else{
            $text='ConfigMgr Client Site Code is "'+$currentSiteCode+'". Expected: "'+$ClientSiteCode+'". Changing sitecode.'
            Write-Warning $text
            $sms.SetAssignedSite($ClientSiteCode)
            #$obj=$true
        }
        #Write-Output $obj
    }
    Function Test-PendingReboot{Param([Parameter(Mandatory=$true)]$Log)
        # Only run pending reboot check if enabled in config
        If(($Xml.Configuration.Option|Where-Object{$_.Name -like 'PendingReboot'}|Select-Object -ExpandProperty 'Enable') -like 'True'){
            $result=@{
            CBSRebootPending=$false
            WindowsUpdateRebootRequired=$false
            FileRenamePending=$false
            SCCMRebootPending=$false
            }
            #Check CBS RegisTry
            $key=Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
            If($null-ne$key){$result.CBSRebootPending=$true}
            #Check Windows Update
            $key=Get-Item 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
            If($null-ne$key){$result.WindowsUpdateRebootRequired=$true}
            #Check PendingFileRenameOperations
            $prop=Get-ItemProperty 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
            If($null-ne$prop){
                #PendingFileRenameOperations is not *must* to reboot?
                #$result.FileRenamePending=$true
            }
            Try{
                $util=[wmiclass]'\\.\root\ccm\clientsdk:CCM_ClientUtilities'
                $status=$util.DetermineIfRebootPending()
                If(($null-ne$status)-and$status.RebootPending){$result.SCCMRebootPending=$true}
            }Catch{
            }
            #Return Reboot required
            If($result.ContainsValue($true)){
                $text='Pending Reboot: Computer is in pending reboot'
                Write-Warning $text
                $log.PendingReboot='Pending Reboot'
                If((Get-XMLConfigPendingRebootApp)-eq$true){
                    Start-RebootApplication
                    $log.RebootApp=Get-SmallDateTime
                }
            }Else{
                $text='Pending Reboot: OK'
                Write-Output $text
                $log.PendingReboot='OK'
            }
            #Out-LogFile -Xml $xml -Text $text
        }
    }
    # Functions to detect and fix errors
    Function Test-ProvisioningMode{Param([Parameter(Mandatory=$true)]$Log)
        $regisTryPath='HKLM:\SOFTWARE\Microsoft\CCM\CcmExec'
        $provisioningMode=(Get-ItemProperty -Path $regisTryPath).ProvisioningMode
        If($provisioningMode-eq'true'){
            $text='ConfigMgr Client Provisioning Mode: YES. Remediating...'
            Write-Warning $text
            Set-ItemProperty -Path $regisTryPath -Name ProvisioningMode -Value "false"
            $ArgumentList=@($false)
            If($PowerShellVersion-ge6){
                Invoke-CimMethod -Namespace 'root\ccm' -Class 'SMS_Client' -MethodName 'SetClientProvisioningMode' -Arguments @{bEnable=$false}|Out-Null
            }Else{
                Invoke-WmiMethod -Namespace 'root\ccm' -Class 'SMS_Client' -Name 'SetClientProvisioningMode' -ArgumentList $ArgumentList|Out-Null
            }
            $log.ProvisioningMode='Repaired'
        }Else{
            $text='ConfigMgr Client Provisioning Mode: OK'
            Write-Output $text
            $log.ProvisioningMode='OK'
        }
    }
    Function Update-State{
        Write-Verbose "Start Update-State"
        $SCCMUpdatesStore=New-Object -ComObject Microsoft.CCM.UpdatesStore
        $SCCMUpdatesStore.RefreshServerComplianceState()
        $log.StateMessages='OK'
        Write-Verbose "End Update-State"
    }
    Function Test-UpdateStore{Param([Parameter(Mandatory=$true)]$Log)
        Write-Verbose "Check StateMessage.log if State Messages are successfully forwarded to Management Point"
        $logdir=Get-CCMLogDirectory
        $logfile="$logdir\StateMessage.log"
        $StateMessage=Get-Content($logfile)
        If($StateMessage-match'Successfully forwarded State Messages to the MP'){
            $text='StateMessage: OK'
            $log.StateMessages='OK'
            Write-Output $text
        }Else{
            $text='StateMessage: ERROR. Remediating...'
            Write-Warning $text
            Update-State
            $log.StateMessages='Repaired'
        }
    }
    Function Test-RegisTryPol{Param([datetime]$StartTime=[datetime]::MinValue,$Days,[Parameter(Mandatory=$true)]$Log)
        $log.WUAHandler="Checking"
        $RepairReason=""
        $MachineRegisTryFile="$($env:WinDir)\System32\GroupPolicy\Machine\regisTry.pol"
        # Check 1 - Error in WUAHandler.log
        Write-Verbose "Check WUAHandler.log for errors since $($StartTime)."
        $logdir=Get-CCMLogDirectory
        $logfile="$logdir\WUAHandler.log"
        $logLine=Search-CMLogFile -LogFile $logfile -StartTime $StartTime -SearchStrings @('0x80004005','0x87d00692')
        If($logLine){$RepairReason="WUAHandler Log"}
        # Check 2 - RegisTry.pol is too old.
        If($Days){
            Write-Verbose "Check machine regisTry file to see if it's older than $($Days) days."
            Try{
                $file=Get-ChildItem -Path $MachineRegisTryFile -ErrorAction SilentlyContinue|Select-Object -First 1 -ExpandProperty LastWriteTime
                $regPolDate=Get-Date($file)
                $now=Get-Date
                If(($now - $regPolDate).Days-ge$Days){$RepairReason="File Age"}
            }Catch{
                Write-Warning "GPO Cache: Failed to check machine policy age."
            }
        }
        # Check 3 - Look back through the last 7 days for group policy processing errors.  
        #Event IDs documented here: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc749336(v=ws.10)#troubleshooting-group-policy-using-event-logs-1      
        Try{
            Write-Verbose "Checking the Group Policy event log for errors since $($StartTime)."
            $numberOfGPOErrors=(Get-WinEvent -Verbose:$false -FilterHashTable @{LogName='Microsoft-Windows-GroupPolicy/Operational';Level=2;StartTime=$StartTime}-ErrorAction SilentlyContinue|Where-Object{($_.ID-ge7000-and$_.ID-le7007)-or($_.ID-ge7017-and$_.ID-le7299)-or($_.ID-eq1096)}).Count
            If($numberOfGPOErrors-gt0){$RepairReason="Event Log"}
        }Catch{
            Write-Warning "GPO Cache: Failed to check the event log for policy errors."
        }
        #If we need to repart the policy files then do so.
        If($RepairReason-ne""){
            $log.WUAHandler="Broken($RepairReason)"
            Write-Output "GPO Cache: Broken($RepairReason)"
            Write-Verbose 'Deleting regisTry.pol and running gpupdate...'
            Try{
                If(Test-Path -Path $MachineRegisTryFile){Remove-Item $MachineRegisTryFile -Force}
            }Catch{
                Write-Warning "GPO Cache: Failed to remove the regisTry file($($MachineRegisTryFile))."
            }Finally{
                & Write-Output n|gpupdate.exe /force /target:computer|Out-Null
            }
            #Write-Verbose 'Sleeping for 1 minute to allow for group policy to refresh'
            #Start-Sleep -Seconds 60
            Write-Verbose 'Refreshing update policy'
            Get-SCCMPolicyScanUpdateSource
            Get-SCCMPolicySourceUpdateMessage
            $log.WUAHandler="Repaired($RepairReason)"
            Write-Output "GPO Cache: $($log.WUAHandler)"
        }Else{
            $log.WUAHandler='OK'
            Write-Output "GPO Cache: OK"
        }
    }
    Function Test-ClientLogSize{Param([Parameter(Mandatory=$true)]$Log)
        Try{
            [int]$currentLogSize=Get-ClientMaxLogSize
        }Catch{
            [int]$currentLogSize=0
        }
        Try{
            [int]$currentMaxHistory=Get-ClientMaxLogHistory
        }Catch{
            [int]$currentMaxHistory=0
        }
        Try{
            $logLevel=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').logLevel
        }Catch{
            $logLevel=1
        }
        $clientLogSize=Get-XMLConfigClientMaxLogSize
        $clientLogMaxHistory=Get-XMLConfigClientMaxLogHistory
        $text=''
        If(($currentLogSize-eq$clientLogSize)-and($currentMaxHistory-eq$clientLogMaxHistory)){
            $Log.MaxLogSize=$currentLogSize
            $Log.MaxLogHistory=$currentMaxHistory
            $text="ConfigMgr Client Max Log Size: OK($currentLogSize)"
            Write-Host $text
            $text="ConfigMgr Client Max Log History: OK($currentMaxHistory)"
            Write-Host $text
            $obj=$false
        }Else{
            If($currentLogSize-ne$clientLogSize){
                $text='ConfigMgr Client Max Log Size: Configuring to '+$clientLogSize+' KB'
                $Log.MaxLogSize=$clientLogSize
                Write-Warning $text
            }Else{
                $text="ConfigMgr Client Max Log Size: OK($currentLogSize)"
                Write-Host $text
            }
            If($currentMaxHistory-ne$clientLogMaxHistory){
                $text='ConfigMgr Client Max Log History: Configuring to '+$clientLogMaxHistory
                $Log.MaxLogHistory=$clientLogMaxHistory
                Write-Warning $text
            }Else{
                $text="ConfigMgr Client Max Log History: OK($currentMaxHistory)"
                Write-Host $text
            }
            $newLogSize=[int]$clientLogSize
            $newLogSize=$newLogSize * 1000
            If($PowerShellVersion-ge6){
                Invoke-CimMethod -Namespace "root/ccm" -ClassName "sms_client" -MethodName SetGlobalLoggingConfiguration -Arguments @{LogLevel=$loglevel; LogMaxHistory=$clientLogMaxHistory; LogMaxSize=$newLogSize}
            }Else{
                $smsClient=[wmiclass]"root/ccm:sms_client"
                $smsClient.SetGlobalLoggingConfiguration($logLevel, $newLogSize, $clientLogMaxHistory)
            }
            #Write-Verbose 'Returning true to trigger restart of ccmexec service'
            #Write-Verbose 'Sleeping for 5 seconds to allow WMI method complete before we collect new results...'
            #Start-Sleep -Seconds 5
            Try{
                $Log.MaxLogSize=Get-ClientMaxLogSize
            }Catch{
                $Log.MaxLogSize=0
            }
            Try{
                $Log.MaxLogHistory=Get-ClientMaxLogHistory
            }Catch{
                $Log.MaxLogHistory=0
            }
            $obj=$true
        }
        Write-Output $obj
    }
    Function Remove-CCMOrphanedCache{
        Write-Host "Clearing ConfigMgr orphaned Cache items."
        Try{
            $CCMCache="$env:SystemDrive\Windows\ccmcache"
            $CCMCache=(New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().Location
            If($null-eq$CCMCache){
                $CCMCache="$env:SystemDrive\Windows\ccmcache"
            }
            $ValidCachedFolders=(New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().GetCacheElements()|ForEach-Object{$_.Location}
            $AllCachedFolders=(Get-ChildItem -Path $CCMCache)|Select-Object Fullname -ExpandProperty Fullname
            ForEach($CachedFolder in $AllCachedFolders){
                If($ValidCachedFolders-notcontains$CachedFolder){
                    #Don't delete new folders that might be syncing data with BITS
                    If((Get-ItemProperty $CachedFolder).LastWriteTime-le(get-date).AddDays(-14)){
                        Write-Verbose "Removing orphaned folder: $CachedFolder - LastWriteTime: $((Get-ItemProperty $CachedFolder).LastWriteTime)"
                        Remove-Item -Path $CachedFolder -Force -Recurse
                    }
                }
            }
        }Catch{
            Write-Host "Failed Clearing ConfigMgr orphaned Cache items."
        }
    }
    Function Resolve-Client{Param([Parameter(Mandatory=$false)]$Xml,[Parameter(Mandatory=$true)]$ClientInstallProperties,[Parameter(Mandatory=$false)]$FirstInstall=$false)
        $ClientShare=Get-XMLConfigClientShare
        If((Test-Path $ClientShare -ErrorAction SilentlyContinue)-eq$true){
            If($FirstInstall-eq$true){
                $text='Installing Configuration Manager Client.'
            }Else{
                $text='Client tagged for reinstall. Reinstalling client...'
            }
            Write-Output $text
            Write-Verbose "Perform a test on a specific regisTry key required for ccmsetup to succeed."
            Test-CCMSetup1
            Write-Verbose "Enforce registration of common DLL files to make sure CCM Agent works."
            $DllFiles='actxprxy.dll', 'atl.dll', 'Bitsprx2.dll', 'Bitsprx3.dll', 'browseui.dll', 'cryptdlg.dll', 'dssenh.dll', 'gpkcsp.dll', 'initpki.dll', 'jscript.dll', 'mshtml.dll', 'msi.dll', 'mssip32.dll', 'msxml.dll', 'msxml3.dll', 'msxml3a.dll', 'msxml3r.dll', 'msxml4.dll', 'msxml4a.dll', 'msxml4r.dll', 'msxml6.dll', 'msxml6r.dll', 'muweb.dll', 'ole32.dll', 'oleaut32.dll', 'Qmgr.dll', 'Qmgrprxy.dll', 'rsaenh.dll', 'sccbase.dll', 'scrrun.dll', 'shdocvw.dll', 'shell32.dll', 'slbcsp.dll', 'softpub.dll', 'rlmon.dll', 'userenv.dll', 'vbscript.dll', 'Winhttp.dll', 'wintrust.dll', 'wuapi.dll', 'wuaueng.dll', 'wuaueng1.dll', 'wucltui.dll', 'wucltux.dll', 'wups.dll', 'wups2.dll', 'wuweb.dll', 'wuwebv.dll', 'Xpob2res.dll', 'WBEM\wmisvc.dll'
            ForEach($Dll in $DllFiles){
                $file=$env:windir+"\System32\$Dll"
                Register-DLLFile -FilePath $File
            }
            If($Uninstall-eq$true){
                Write-Verbose "Trigger ConfigMgr Client uninstallation using Invoke-Expression."
                Invoke-Expression "&'$ClientShare\ccmsetup.exe' /uninstall"
                $launched=$true
                Do{
                    Start-Sleep -seconds 5
                    If(Get-Process "ccmsetup" -ErrorAction SilentlyContinue){
                        Write-Verbose "ConfigMgr Client Uninstallation still running"
                        $launched=$true
                    }Else{
                        $launched=$false
                    }
                }While($launched-eq$true)
            }
            Write-Verbose "Trigger ConfigMgr Client installation using Invoke-Expression."
            Invoke-Expression "&'$ClientShare\ccmsetup.exe' $ClientInstallProperties"
            $launched=$true
            Do{
                Start-Sleep -seconds 5
                If(Get-Process "ccmsetup" -ErrorAction SilentlyContinue){
                    Write-Verbose "ConfigMgr Client installation still running"
                    $launched=$true
                }Else{
                    $launched=$false
                }
            }While($launched-eq$true)
            If($FirstInstall-eq$true){
                Write-Host "ConfigMgr Client was installed for the first time. Waiting 6 minutes for client to syncronize policy before proceeding."
                Start-Sleep -Seconds 360
            }
        # Client is reinstalled. Remove tag.
        }Else{
            $text='ERROR: Client tagged for reinstall, but failed to access fileshare: '+$ClientShare
            Write-Error $text
            Exit 1
        }
    }
    Function Register-DLLFile{[CmdletBinding()]Param([string]$FilePath)
        Try{
            $Result=Start-Process -FilePath 'regsvr32.exe' -Args "/s `"$FilePath`"" -Wait -NoNewWindow -PassThru
        }Catch{
        }
    }
    Function Test-WMI{Param([Parameter(Mandatory=$true)]$Log)
        $vote=0
        $result=winmgmt /verifyrepository
        Switch -wildcard($result){
            # Always fix if this returns inconsistent
            "*inconsistent*"{$vote=100}# English
            "*not consistent*" {$vote=100}# English
            "*inkonsekvent*"{$vote=100}# Swedish
            "*epäyhtenäinen*"{$vote=100}# Finnish
            "*inkonsistent*"{$vote=100}# German
            # Add more languages as I learn their inconsistent value
        }
        Try{
            If($PowerShellVersion-ge6){
                $WMI=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
            }Else{
                $WMI=Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
            }
        }Catch{
            Write-Verbose 'Failed to connect to WMI class "Win32_ComputerSystem". Voting for WMI fix...'
            $vote++
        }
        Try{
            If($PowerShellVersion-ge6){
                $WMI=Get-CimInstance -Namespace root/ccm -Class SMS_Client -ErrorAction Stop
            }Else{
                $WMI=Get-WmiObject -Namespace root/ccm -Class SMS_Client -ErrorAction Stop
            }
        }Catch{
            Write-Verbose 'Failed to connect to WMI namespace "root/ccm" class "SMS_Client". Tagging client for reinstall instead of WMI fix.'
            $obj=$true
        }Finally{
            If($vote-eq0){
                $text='WMI Check: OK'
                $log.WMI='OK'
                Write-Host $text
                $obj=$false
            }Else{
                $fix=Get-XMLConfigWMIRepairEnable
                If($fix -like "True"){
                    $text='WMI Check: Corrupt. Attempting to repair WMI and reinstall ConfigMgr client.'
                    Write-Warning $text
                    Repair-WMI
                    $log.WMI='Repaired'
                }Else{
                    $text='WMI Check: Corrupt. Autofix is disabled'
                    Write-Warning $text
                    $log.WMI='Corrupt'
                }
                Write-Verbose "returning true to tag client for reinstall" 
                $obj=$true
            }
            #Out-LogFile -Xml $xml -Text $text
            Write-Output $obj
        }
    }
    Function Repair-WMI{
        $text='Repairing WMI'
        Write-Output $text
        # Check PATH
        If((!(@(($ENV:PATH).Split(";"))-contains"$env:SystemDrive\WINDOWS\System32\Wbem"))-and(!(@(($ENV:PATH).Split(";"))-contains"%systemroot%\System32\Wbem"))){
            $text="WMI Folder not in search path!."
            Write-Warning $text
        }
        # Stop WMI
        Stop-Service -Force ccmexec -ErrorAction SilentlyContinue 
        Stop-Service -Force winmgmt
        # WMI Binaries
        [String[]]$aWMIBinaries=@("unsecapp.exe","wmiadap.exe","wmiapsrv.exe","wmiprvse.exe","scrcons.exe")
        ForEach($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
            If(Test-Path -Path $sWMIPath){
                Push-Location $sWMIPath
                ForEach($sBin in $aWMIBinaries){
                    If(Test-Path -Path $sBin){
                        $oCurrentBin=Get-Item -Path $sBin
                        & $oCurrentBin.FullName /RegServer
                    }Else{
                        # Warning only for System32
                        If($sWMIPath-eq$ENV:SystemRoot+"\System32\wbem"){
                            Write-Warning "File $sBin not found!"
                        }
                    }
                }
                Pop-Location
            }
        }
        # Reregister Managed Objects
        Write-Verbose "Reseting Repository..."
        &($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /resetrepository
        &($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /salvagerepository
        Start-Service winmgmt
        $text='Tagging ConfigMgr client for reinstall'
        Write-Warning $text
    }
    # Test if the compliance state messages should be resent.
    Function Test-RefreshComplianceState{Param($Days=0,[Parameter(Mandatory=$true)]$RegisTryKey,[Parameter(Mandatory=$true)]$Log)    
        $RegValueName="RefreshServerComplianceState"
        #Get the last time this script was ran.  If the regisTry isn't found just use the current date.
        Try{
            [datetime]$LastSent=Get-RegisTryValue -Path $RegisTryKey -Name $RegValueName
        }Catch{
            [datetime]$LastSent=Get-Date
        }
        Write-Verbose "The compliance states were last sent on $($LastSent)"
        #Determine the number of days until the next run.
        $NumberOfDays=(New-Timespan -Start(Get-Date) -End($LastSent.AddDays($Days))).Days
        #Resend complianc states if the next interval has already arrived or randomly based on the number of days left until the next interval.
        If(($NumberOfDays-le0)-or((Get-Random -Maximum $NumberOfDays)-eq0)){
            Try{
                Write-Verbose "Resending compliance states."
                (New-Object -ComObject Microsoft.CCM.UpdatesStore).RefreshServerComplianceState()
                $LastSent=Get-Date                
                Write-Output "Compliance States: Refreshed."
            }Catch{
                Write-Error "Failed to resend the compliance states."
                $LastSent=[datetime]::MinValue
            }                       
        }Else{
            Write-Output "Compliance States: OK."            
        }
        Set-RegisTryValue -Path $RegisTryKey -Name $RegValueName -Value $LastSent
        $Log.RefreshComplianceState=Get-SmallDateTime $LastSent
    }
    # Start ConfigMgr Agent if not already running
    Function Test-SCCMService{
        If($service.Status-ne'Running'){
            Try{
                Start-Service -Name CcmExec|Out-Null
            }Catch{
            }
        }
    }
    Function Test-SMSTSMgr{
        $service=get-service smstsmgr
        If(($service.ServicesDependedOn).name-contains"ccmexec"){ 
            write-host "SMSTSMgr: Removing dependency on CCMExec service."  
            start-process sc.exe -ArgumentList "config smstsmgr depend=winmgmt" -wait  
        }
        # WMI service depenency is present by default
        If(($service.ServicesDependedOn).name-notcontains"Winmgmt"){ 
            write-host "SMSTSMgr: Adding dependency on Windows Management Instrumentaion service."  
            start-process sc.exe -ArgumentList "config smstsmgr depend=winmgmt" -wait  
        }Else{
            Write-Host "SMSTSMgr: OK"
        }
    }
    # Windows Service Functions
    Function Test-Services{Param([Parameter(Mandatory=$true)]$Xml, $log)
        $log.Services='OK'
        Write-Verbose 'Test services from XML configuration file'
        ForEach($service in $Xml.Configuration.Service){
            $startuptype=($service.StartupType).ToLower()
            If($startuptype -like "automatic(delayed start)"){
                $service.StartupType="automaticd"
            }
            If($service.uptime-ne$null){
                $uptime=($service.Uptime).ToLower()
                Test-Service -Name $service.Name -StartupType $service.StartupType -State $service.State -Log $log -Uptime $uptime
            }Else{
                Test-Service -Name $service.Name -StartupType $service.StartupType -State $service.State -Log $log
            }
        }
    }
    Function Test-Service{Param([Parameter(Mandatory=$True,HelpMessage='Name')][string]$Name,[Parameter(Mandatory=$True,HelpMessage='StartupType: Automatic, Automatic(Delayed Start), Manual, Disabled')][string]$StartupType,[Parameter(Mandatory=$True,HelpMessage='State: Running, Stopped')][string]$State,[Parameter(Mandatory=$False,HelpMessage='Updatime in days')][int]$Uptime,[Parameter(Mandatory=$True)]$log)
        $OSName=Get-OperatingSystem
        # Handle all sorts of casing and mispelling of delayed and triggerd start in config.xml services
        $val=$StartupType.ToLower()
        Switch -Wildcard($val){
            "automaticd*"{$StartupType="Automatic(Delayed Start)"}
            "automatic(d*"{$StartupType="Automatic(Delayed Start)"}
            "automatic(t*"{$StartupType="Automatic(Trigger Start)"}
            "automatict*"{$StartupType="Automatic(Trigger Start)"}
        }
        $path="HKLM:\SYSTEM\CurrentControlSet\Services\$name"
        $DelayedAutostart=(Get-ItemProperty -Path $path).DelayedAutostart
        If($DelayedAutostart-ne1){
            $DelayedAutostart=0
        }
        $service=Get-Service -Name $Name
        If($PowerShellVersion-ge6){
            $WMIService=Get-CimInstance -Class Win32_Service -Property StartMode -Filter "Name='$Name'"
        }Else{
            $WMIService=Get-WmiObject -Class Win32_Service -Property StartMode -Filter "Name='$Name'"
        }
        $StartMode=($WMIService.StartMode).ToLower()
        Switch -Wildcard($StartMode){
            "auto*"{
                If($DelayedAutostart-eq1){
                    $serviceStartType="Automatic(Delayed Start)"
                }Else{
                    $serviceStartType="Automatic"
                }
            }
            <# This will be implemented at a later time.
            "automatic d*"{$serviceStartType="Automatic(Delayed Start)"}
            "automatic(d*"{$serviceStartType="Automatic(Delayed Start)"}
            "automatic(t*"{$serviceStartType="Automatic(Trigger Start)"}
            "automatic t*"{$serviceStartType="Automatic(Trigger Start)"}
            #>
            "manual"{$serviceStartType="Manual"}
            "disabled"{$serviceStartType="Disabled"}
        }
        Write-Verbose "Verify startup type"
        If($serviceStartType-eq$StartupType){
            $text="Service $Name startup: OK"
            Write-Output $text
        }ElseIf($StartupType -like "Automatic(Delayed Start)"){
            # Handle Automatic Trigger Start the dirty way for these two services. Implement in a nice way in future version.
            If((($name-eq"wuauserv")-or($name-eq"W32Time"))-and(($OSName -like "Windows 10*")-or($OSName -like "*Server 2016*"))){
                If($service.StartType-ne"Automatic"){
                    $text="Configuring service $Name StartupType to: Automatic(Trigger Start)..."
                    Set-Service -Name $service.Name -StartupType Automatic
                }Else{
                    "Service $Name startup: OK"
                }
                Write-Output $text
            }Else{
                # Automatic delayed requires the use of sc.exe
                & sc.exe config $service start=delayed-auto|Out-Null
                $text="Configuring service $Name StartupType to: $StartupType..."
                Write-Output $text
                $log.Services='Started'
            }
        }Else{
            Try{
                $text="Configuring service $Name StartupType to: $StartupType..."
                Write-Output $text
                Set-Service -Name $service.Name -StartupType $StartupType
                $log.Services='Started'
            }Catch{
                $text="Failed to set $StartupType StartupType on service $Name"
                Write-Error $text
            }
        }
        Write-Verbose 'Verify service is running'
        If($service.Status-eq"Running"){
            $text='Service '+$Name+' running: OK'
            Write-Output $text
            #If we are checking uptime.
            If($Uptime){
                Write-Verbose "Verify the $($Name) service hasn't exceeded uptime of $($Uptime) days."
                $ServiceUptime=Get-ServiceUpTime -Name $Name
                If($ServiceUptime-ge$Uptime){
                    Try{
                        #Before restarting the service wait for some known processes to end.  Restarting the service while an app or updates is installing might cause issues.
                        $Timer=[Diagnostics.Stopwatch]::StartNew()
                        $WaitMinutes=30
                        $ProcessesStopped=$True
                        While((Get-Process -Name WUSA,wuauclt,setup,TrustedInstaller,msiexec,TiWorker,ccmsetup -ErrorAction SilentlyContinue).Count-gt0){
                            $MinutesLeft=$WaitMinutes-$Timer.Elapsed.Minutes                        
                            If($MinutesLeft-le0){
                                Write-Warning "Timed out waiting $($WaitMinutes) minutes for installation processes to complete.  Will not restart the $($Name) service."
                                $ProcessesStopped=$False
                                Break
                            }
                            Write-Warning "Waiting $($MinutesLeft) minutes for installation processes to complete."
                            Start-Sleep -Seconds 30
                        }
                        $Timer.Stop()
                        #If the processes are not running the restart the service.
                        If($ProcessesStopped){
                            Write-Output "Restarting service: $($Name)..."
                            Restart-Service  -Name $service.Name -Force
                            Write-Output "Restarted service: $($Name)..."
                            $log.Services='Restarted'
                        }
                    }Catch{
                        $text="Failed to restart service $($Name)"
                        Write-Error $text
                    }
                }Else{
                    Write-Output "Service $($Name) uptime: OK"
                }
            }
        }Else{
            Try{
                $ReTryService=$False
                $text='Starting service: '+$Name+'...'
                Write-Output $text
                Start-Service -Name $service.Name -ErrorAction Stop                
                $log.Services='Started'
            }Catch{
                #Error 1290(-2146233087) indicates that the service is sharing a thread with another service that is protected and cannot share its thread.
                #This is resolved by configuring the service to run on its own thread.
                If($_.Exception.Hresult-eq'-2146233087'){               
                    Write-Output "Failed to start service $Name because it's sharing a thread with another process.  Changing to use its own thread."
                    & cmd /c sc config $Name type=own
                    $ReTryService=$True                    
                }Else{
                    $text='Failed to start service '+$Name
                    Write-Error $text
                }
            }
            #If a recoverable error was found, Try starting it again.
            If($ReTryService){
                Try{                   
                    Start-Service -Name $service.Name -ErrorAction Stop                
                    $log.Services='Started'
                }Catch{
                    $text='Failed to start service '+$Name
                    Write-Error $text
                }
            }
        }
    }
    Function Test-AdminShare{Param([Parameter(Mandatory=$true)]$Log)
        Write-Verbose "Test the ADMIN$ and C$"
        If($PowerShellVersion-ge6){
            $share=Get-CimInstance Win32_Share|Where-Object{$_.Name -like 'ADMIN$'}
        }Else{
            $share=Get-WmiObject Win32_Share|Where-Object{$_.Name -like 'ADMIN$'}
        }
        #$shareClass=[WMICLASS]"WIN32_Share"  # Depreciated
        If($share.Name-contains'ADMIN$'){
            $text='Adminshare Admin$: OK'
            Write-Output $text
        }Else{
            $fix=$true
        }
        If($PowerShellVersion-ge6){
            $share=Get-CimInstance Win32_Share|Where-Object{$_.Name -like 'C$'}
        }Else{
            $share=Get-WmiObject Win32_Share|Where-Object{$_.Name -like 'C$'}
        }
        #$shareClass=[WMICLASS]'WIN32_Share'  # Depreciated
        If($share.Name-contains"C$"){
            $text='Adminshare C$: OK'
            Write-Output $text
        }Else{
            $fix=$true
        }
        If($fix-eq$true){
            $text='Error with Adminshares. Remediating...'
            $log.AdminShare='Repaired'
            Write-Warning $text
            Stop-Service server -Force
            Start-Service server
        }Else{
            $log.AdminShare='OK'
        }
    }
    Function Test-DiskSpace{
        $XMLDiskSpace=Get-XMLConfigOSDiskFreeSpace
        If($PowerShellVersion-ge6){
            $driveC=Get-CimInstance -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object FreeSpace, Size
        }Else{
            $driveC=Get-WmiObject -Class Win32_LogicalDisk|Where-Object{$_.DeviceID-eq"$env:SystemDrive"}|Select-Object FreeSpace, Size
        }
        $freeSpace=(($driveC.FreeSpace/$driveC.Size) * 100)
        If($freeSpace-le$XMLDiskSpace){
            $text="Local disk $env:SystemDrive Less than $XMLDiskSpace % free space"
            Write-Error $text
        }Else{
            $text="Free space $env:SystemDrive OK"
            Write-Output $text
        }
    }
    Function Test-CCMSoftwareDistribution{
        # TODO Implement this function
        Get-WmiObject -Class CCM_SoftwareDistributionClientConfig
    }
    Function Get-UBR{
        $UBR=(Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').UBR
        Write-Output $UBR
    }
    Function Get-LastReboot{Param([Parameter(Mandatory=$true)][xml]$Xml)
        # Only run if option in config is enabled
        If(($Xml.Configuration.Option|Where-Object{$_.Name -like 'RebootApplication'}|Select-Object -ExpandProperty 'Enable') -like 'True'){
            [float]$maxRebootDays=Get-XMLConfigMaxRebootDays
            If($PowerShellVersion-ge6){
                $wmi=Get-CimInstance Win32_OperatingSystem
            }Else{
                $wmi=Get-WmiObject Win32_OperatingSystem
            }
            $lastBootTime=$wmi.ConvertToDateTime($wmi.LastBootUpTime)
            $uptime=(Get-Date) -($wmi.ConvertToDateTime($wmi.lastbootuptime))
            If($uptime.TotalDays-lt$maxRebootDays){
                $text='Last boot time: '+$lastBootTime+': OK'
                Write-Output $text
            }ElseIf(($uptime.TotalDays-ge$maxRebootDays)-and(Get-XMLConfigRebootApplicationEnable-eq$true)){
                $text='Last boot time: '+$lastBootTime+': More than '+$maxRebootDays+' days since last reboot. Starting reboot application.'
                Write-Warning $text
                Start-RebootApplication
            }Else{
                $text='Last boot time: '+$lastBootTime+': More than '+$maxRebootDays+' days since last reboot. Reboot application disabled.'
                Write-Warning $text
            }
        }
    }
    Function Start-RebootApplication{
        $taskName='ConfigMgr Client Health - Reboot on demand'
        #$OS=Get-OperatingSystem
        #If($OS -like "*Windows 7*"){
        $task=schtasks.exe /query|FIND /I "ConfigMgr Client Health - Reboot"
        #}
        #Else{$task=Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue}
        If($task-eq$null){New-RebootTask -taskName $taskName}
        #If($OS-notlike"*Windows 7*"){Start-ScheduledTask -TaskName $taskName}
        #Else{
        schtasks.exe /Run /TN $taskName
        #}
    }
    Function New-RebootTask{Param([Parameter(Mandatory=$true)]$taskName)
        $rebootApp=Get-XMLConfigRebootApplication
        # $execute is the executable file, $arguement is all the arguments added to it.
        $execute,$arguments=$rebootApp.Split(' ')
        $argument=$null
        ForEach($i in $arguments){
            $argument+=$i+" "
        }
        # Trim the " " from argument if present
        $i=$argument.Length -1
        If($argument.Substring($i)-eq' '){
            $argument=$argument.Substring(0, $argument.Length -1)
        }
        #$OS=Get-OperatingSystem
        #If($OS -like "*Windows 7*"){
        schtasks.exe /Create /tn $taskName /tr "$execute $argument" /ru "BUILTIN\Users" /sc ONCE /st 00:00 /sd 01/01/1901
        #}
        <#
        Else{
        $action=New-ScheduledTaskAction -Execute $execute -Argument $argument
        $userPrincipal=New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545"
        Register-ScheduledTask -Action $action -TaskName $taskName -Principal $userPrincipal|Out-Null
        }
        #>
    }
    Function Start-Ccmeval{
        Write-Host "Starting Built-in Configuration Manager Client Health Evaluation"
        $task="Microsoft\Configuration Manager\Configuration Manager Health Evaluation"
        schtasks.exe /Run /TN $task|Out-Null
    }
    Function Test-MissingDrivers{Param([Parameter(Mandatory=$true)]$Log)
        $FileLogLevel=((Get-XMLConfigLogginLevel).ToString()).ToLower()
        $i=0
        If($PowerShellVersion-ge6){
            $devices=Get-CimInstance Win32_PNPEntity|Where-Object{($_.ConfigManagerErrorCode-ne0)-and($_.ConfigManagerErrorCode-ne22)-and($_.Name-notlike"*PS/2*")}|Select-Object Name, DeviceID
        }Else{
            $devices=Get-WmiObject Win32_PNPEntity|Where-Object{($_.ConfigManagerErrorCode-ne0)-and($_.ConfigManagerErrorCode-ne22)-and($_.Name-notlike"*PS/2*")}|Select-Object Name, DeviceID
        }
        $devices|ForEach-Object{$i++}
        If($devices-ne$null){
            $text="Drivers: $i unknown or faulty device(s)" 
            Write-Warning $text
            $log.Drivers="$i unknown or faulty driver(s)" 
            ForEach($device in $devices){
                $text='Missing or faulty driver: '+$device.Name+'. Device ID: '+$device.DeviceID
                Write-Warning $text
                If(!($FileLogLevel -like "clientlocal")){
                    Out-LogFile -Xml $xml -Text $text
                }
            }
        }Else{
            $text="Drivers: OK"
            Write-Output $text
            $log.Drivers='OK' 
        }
    }
    # Function to store SCCM log file changes to be processed
    Function New-SCCMLogFileJob{Param([Parameter(Mandatory=$true)]$Logfile,[Parameter(Mandatory=$true)]$Text,[Parameter(Mandatory=$true)]$SCCMLogJobs)
        $path=Get-CCMLogDirectory
        $file="$path\$LogFile"
        $SCCMLogJobs.Rows.Add($file, $text)
    }
    # Function to remove info in SCCM logfiles after remediation. This to prevent false positives triggering remediation next time script runs
    Function Update-SCCMLogFile{Param([Parameter(Mandatory=$true)]$SCCMLogJobs)
        Write-Verbose "Start Update-SCCMLogFile"
        ForEach($job in $SCCMLogJobs){
            get-content -Path $job.File|Where-Object{$_-notmatch$job.Text}|Out-File $job.File -Force
        }
        Write-Verbose "End Update-SCCMLogFile"
    }
    Function Test-SCCMHardwareInventoryScan{Param([Parameter(Mandatory=$true)]$Log)
        Write-Verbose "Start Test-SCCMHardwareInventoryScan"
        $days=Get-XMLConfigHardwareInventoryDays
        If($PowerShellVersion-ge6){
            $wmi=Get-CimInstance -Namespace root\ccm\invagt -Class InventoryActionStatus|Where-Object{$_.InventoryActionID-eq'{00000000-0000-0000-0000-000000000001}'}|Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}}
        }Else{
            $wmi=Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus|Where-Object{$_.InventoryActionID-eq'{00000000-0000-0000-0000-000000000001}'}|Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}}
        }
        $HWScanDate=$wmi|Select-Object -ExpandProperty HWSCAN
        $HWScanDate=Get-SmallDateTime $HWScanDate
        $minDate=Get-SmallDateTime((Get-Date).AddDays(-$days))
        If($HWScanDate-le$minDate){
            $fix=(Get-XMLConfigHardwareInventoryFix).ToLower()
            If($fix-eq"true"){
                $text="ConfigMgr Hardware Inventory scan: $HWScanDate. Starting hardware inventory scan of the client."
                Write-Host $Text
                Get-SCCMPolicyHardwareInventory
                # Get the new date after policy trigger
                If($PowerShellVersion-ge6){
                    $wmi=Get-CimInstance -Namespace root\ccm\invagt -Class InventoryActionStatus|Where-Object{$_.InventoryActionID-eq'{00000000-0000-0000-0000-000000000001}'}|Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}}
                }Else{
                    $wmi=Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus|Where-Object{$_.InventoryActionID-eq'{00000000-0000-0000-0000-000000000001}'}|Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}}
                }
                $HWScanDate=$wmi|Select-Object -ExpandProperty HWSCAN
                $HWScanDate=Get-SmallDateTime -Date $HWScanDate
            }Else{
                # No need to update anything if fix=false. Last date will still be set in log
            }
        }Else{
            $text="ConfigMgr Hardware Inventory scan: OK"
            Write-Output $text
        }
        $log.HWInventory=$HWScanDate
        Write-Verbose "End Test-SCCMHardwareInventoryScan"
    }
    # TODO: Implement so result of this remediation is stored in WMI log object, next to result of previous WMI check. This do not require db or webservice update
    # ref: https://social.technet.microsoft.com/Forums/de-DE/1f48e8d8-4e13-47b5-ae1b-dcb831c0a93b/setup-was-unable-to-compile-the-file-discoverystatusmof-the-error-code-is-8004100e?forum=configmanagerdeployment
    Function Test-PolicyPlatform{Param([Parameter(Mandatory=$true)]$Log)
        Try{
            If(Get-WmiObject -Namespace 'root/Microsoft' -Class '__Namespace' -Filter 'Name="PolicyPlatform"'){
                Write-Host "PolicyPlatform: OK"
            }Else{
                Write-Warning "PolicyPlatform: Not found, recompiling WMI 'Microsoft Policy Platform\ExtendedStatus.mof'"
                If($PowerShellVersion-ge6){
                    $OS=Get-CimInstance Win32_OperatingSystem
                }Else{
                    $OS=Get-WmiObject Win32_OperatingSystem
                }
                # 32 or 64?
                If($OS.OSArchitecture-match'64'){
                    & mofcomp "$env:ProgramW6432\Microsoft Policy Platform\ExtendedStatus.mof"
                }Else{
                    & mofcomp "$env:ProgramFiles\Microsoft Policy Platform\ExtendedStatus.mof"
                }
                # Update WMI log object
                $text='PolicyPlatform Recompiled.'
                If(!($Log.WMI-eq'OK')){
                    $Log.WMI+=". $text"
                }Else{
                    $Log.WMI=$text
                }
            }
        }Catch{
            Write-Warning "PolicyPlatform: RecompilePolicyPlatform failed!"
        }
    }
    # Get the clients SiteName in Active Directory
    Function Get-ClientSiteName{
        Try{
            If($PowerShellVersion-ge6){
                $obj=(Get-CimInstance Win32_NTDomain).ClientSiteName
            }Else{
                $obj=(Get-WmiObject Win32_NTDomain).ClientSiteName
            }
        }Catch{
            $obj=$false
        }Finally{
            If($obj-ne$false){
                Write-Output($obj|Select-Object -First 1)
            }
        }
    }
    Function Test-SoftwareMeteringPrepDriver{Param([Parameter(Mandatory=$true)]$Log)
        # To execute function:If(Test-SoftwareMeteringPrepDriver-eq$false){$restartCCMExec=$true}
        # Thanks to Paul Andrews for letting me know about this issue.
        # And Sherry Kissinger for a nice fix: https://mnscug.org/blogs/sherry-kissinger/481-configmgr-ccmrecentlyusedapps-blank-or-mtrmgr-log-with-startprepdriver-openservice-failed-with-error-issue
        Write-Verbose "Start Test-SoftwareMeteringPrepDriver"
        $logdir=Get-CCMLogDirectory
        $logfile="$logdir\mtrmgr.log"
        $content=Get-Content -Path $logfile
        $error1="StartPrepDriver - OpenService Failed with Error"
        $error2="Software Metering failed to start PrepDriver"
        If(($content-match$error1)-or($content-match$error2)){
            $fix=(Get-XMLConfigSoftwareMeteringFix).ToLower()
            If($fix-eq"true"){
                $Text="Software Metering - PrepDriver: Error. Remediating..."
                Write-Host $Text
                $CMClientDIR=(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties" -Name 'Local SMS Path').'Local SMS Path'
                $ExePath=$env:windir+'\system32\RUNDLL32.EXE'
                $CLine=' SETUPAPI.DLL,InstallHinfSection DefaultInstall 128 '+$CMClientDIR+'prepdrv.inf'
                $ExePath=$env:windir+'\system32\RUNDLL32.EXE'
                $Prms=$Cline.Split(" ")
                & "$Exepath" $Prms
                $newContent=$content|Select-String -pattern $error1, $error2 -notmatch
                Stop-Service -Name CcmExec
                Out-File -FilePath $logfile -InputObject $newContent -Encoding utf8 -Force
                Start-Service -Name CcmExec
                $Obj=$false
                $Log.SWMetering="Remediated"
            }Else{
                # Set $obj to true as we don't want to do anything with the CM agent.
                $obj=$true
                $Log.SWMetering="Error"
            }
        }Else{
            $Text="Software Metering - PrepDriver: OK"
            Write-Host $Text
            $Obj=$true
            $Log.SWMetering="OK"
        }
        $content=$null # Clean the variable containing the log file.
        Write-Output $Obj
        Write-Verbose "End Test-SoftwareMeteringPrepDriver"
    }
    Function Test-SCCMHWScanErrors{
        # Function to test and fix errors that prevent a computer to perform a HW scan. Not sure if this is really needed or not.
    }
    # SCCM Client evaluation policies
    Function Get-SCCMPolicySourceUpdateMessage{
        $trigger="{00000000-0000-0000-0000-000000000032}"
        If($PowerShellVersion-ge6){
            Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}-ErrorAction SilentlyContinue|Out-Null
        }Else{
            Invoke-WmiMethod -Namespace 'root\ccm' -Class 'sms_client' -Name TriggerSchedule $trigger -ErrorAction SilentlyContinue|Out-Null
        }
    }
    Function Get-SCCMPolicySendUnsentStateMessages{
        $trigger="{00000000-0000-0000-0000-000000000111}"
        If($PowerShellVersion-ge6){
            Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}-ErrorAction SilentlyContinue|Out-Null
        }Else{
            Invoke-WmiMethod -Namespace 'root\ccm' -Class 'sms_client' -Name TriggerSchedule $trigger -ErrorAction SilentlyContinue|Out-Null
        }
    }
    Function Get-SCCMPolicyScanUpdateSource{
        $trigger="{00000000-0000-0000-0000-000000000113}"
        If($PowerShellVersion-ge6){
            Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}-ErrorAction SilentlyContinue|Out-Null
        }Else{
            Invoke-WmiMethod -Namespace 'root\ccm' -Class 'sms_client' -Name TriggerSchedule $trigger -ErrorAction SilentlyContinue|Out-Null
        }
    }
    Function Get-SCCMPolicyHardwareInventory{
        $trigger="{00000000-0000-0000-0000-000000000001}"
        If($PowerShellVersion-ge6){
            Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}-ErrorAction SilentlyContinue|Out-Null
        }Else{
            Invoke-WmiMethod -Namespace 'root\ccm' -Class 'sms_client' -Name TriggerSchedule $trigger -ErrorAction SilentlyContinue|Out-Null
        }
    }
    Function Get-SCCMPolicyMachineEvaluation{
        $trigger="{00000000-0000-0000-0000-000000000022}"
        If($PowerShellVersion-ge6){
            Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'sms_client' -MethodName TriggerSchedule -Arguments @{sScheduleID=$trigger}-ErrorAction SilentlyContinue|Out-Null
        }Else{
            Invoke-WmiMethod -Namespace 'root\ccm' -Class 'sms_client' -Name TriggerSchedule $trigger -ErrorAction SilentlyContinue|Out-Null
        }
    }
    Function Get-Version{
        $text='ConfigMgr Client Health Version '+$Version
        Write-Output $text
        Out-LogFile -Xml $xml -Text $text
    }
    <# Trigger codes
    {00000000-0000-0000-0000-000000000001}Hardware Inventory
    {00000000-0000-0000-0000-000000000002}Software Inventory 
    {00000000-0000-0000-0000-000000000003}Discovery Inventory 
    {00000000-0000-0000-0000-000000000010}File Collection 
    {00000000-0000-0000-0000-000000000011}IDMIF Collection 
    {00000000-0000-0000-0000-000000000012}Client Machine Authentication 
    {00000000-0000-0000-0000-000000000021}Request Machine Assignments 
    {00000000-0000-0000-0000-000000000022}Evaluate Machine Policies 
    {00000000-0000-0000-0000-000000000023}Refresh Default MP Task 
    {00000000-0000-0000-0000-000000000024}LS(Location Service) Refresh Locations Task 
    {00000000-0000-0000-0000-000000000025}LS(Location Service) Timeout Refresh Task 
    {00000000-0000-0000-0000-000000000026}Policy Agent Request Assignment(User) 
    {00000000-0000-0000-0000-000000000027}Policy Agent Evaluate Assignment(User) 
    {00000000-0000-0000-0000-000000000031}Software Metering Generating Usage Report 
    {00000000-0000-0000-0000-000000000032}Source Update Message
    {00000000-0000-0000-0000-000000000037}Clearing proxy settings cache 
    {00000000-0000-0000-0000-000000000040}Machine Policy Agent Cleanup 
    {00000000-0000-0000-0000-000000000041}User Policy Agent Cleanup
    {00000000-0000-0000-0000-000000000042}Policy Agent Validate Machine Policy/Assignment 
    {00000000-0000-0000-0000-000000000043}Policy Agent Validate User Policy/Assignment 
    {00000000-0000-0000-0000-000000000051}ReTrying/Refreshing certificates in AD on MP 
    {00000000-0000-0000-0000-000000000061}Peer DP Status reporting 
    {00000000-0000-0000-0000-000000000062}Peer DP Pending package check schedule 
    {00000000-0000-0000-0000-000000000063}SUM Updates install schedule 
    {00000000-0000-0000-0000-000000000071}NAP action 
    {00000000-0000-0000-0000-000000000101}Hardware Inventory Collection Cycle 
    {00000000-0000-0000-0000-000000000102}Software Inventory Collection Cycle 
    {00000000-0000-0000-0000-000000000103}Discovery Data Collection Cycle 
    {00000000-0000-0000-0000-000000000104}File Collection Cycle 
    {00000000-0000-0000-0000-000000000105}IDMIF Collection Cycle 
    {00000000-0000-0000-0000-000000000106}Software Metering Usage Report Cycle 
    {00000000-0000-0000-0000-000000000107}Windows Installer Source List Update Cycle 
    {00000000-0000-0000-0000-000000000108}Software Updates Assignments Evaluation Cycle 
    {00000000-0000-0000-0000-000000000109}Branch Distribution Point Maintenance Task 
    {00000000-0000-0000-0000-000000000110}DCM policy 
    {00000000-0000-0000-0000-000000000111}Send Unsent State Message 
    {00000000-0000-0000-0000-000000000112}State System policy cache cleanout 
    {00000000-0000-0000-0000-000000000113}Scan by Update Source 
    {00000000-0000-0000-0000-000000000114}Update Store Policy 
    {00000000-0000-0000-0000-000000000115}State system policy bulk send high
    {00000000-0000-0000-0000-000000000116}State system policy bulk send low 
    {00000000-0000-0000-0000-000000000120}AMT Status Check Policy 
    {00000000-0000-0000-0000-000000000121}Application manager policy action 
    {00000000-0000-0000-0000-000000000122}Application manager user policy action
    {00000000-0000-0000-0000-000000000123}Application manager global evaluation action 
    {00000000-0000-0000-0000-000000000131}Power management start summarizer
    {00000000-0000-0000-0000-000000000221}Endpoint deployment reevaluate 
    {00000000-0000-0000-0000-000000000222}Endpoint AM policy reevaluate 
    {00000000-0000-0000-0000-000000000223}External event detection
    #>
    Function Test-SQLConnection{   
        $SQLServer=Get-XMLConfigSQLServer
        $Database='ClientHealth'
        $FileLogLevel=((Get-XMLConfigLogginLevel).ToString()).ToLower()
        $ConnectionString="Server={0};Database={1};Integrated Security=True;" -f $SQLServer,$Database
        Try{
            $sqlConnection=New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
            $sqlConnection.Open();
            $sqlConnection.Close();
            $obj=$true;
        }Catch{
            $text="Error connecting to SQLDatabase $Database on SQL Server $SQLServer"
            Write-Error -Message $text
            If(!($FileLogLevel -like "clientinstall")){
                Out-LogFile -Xml $xml -Text $text
            }
            $obj=$false;
        }Finally{
            Write-Output $obj
        }
    }
    # Invoke-SqlCmd2 - Created by Chad Miller
    Function Invoke-Sqlcmd2{[CmdletBinding()]Param([Parameter(Position=0, Mandatory=$true)][string]$ServerInstance,[Parameter(Position=1, Mandatory=$false)][string]$Database,[Parameter(Position=2, Mandatory=$false)][string]$Query,[Parameter(Position=3, Mandatory=$false)][string]$Username,[Parameter(Position=4, Mandatory=$false)][string]$Password,[Parameter(Position=5, Mandatory=$false)][Int32]$QueryTimeout=600,[Parameter(Position=6, Mandatory=$false)][Int32]$ConnectionTimeout=15,[Parameter(Position=7, Mandatory=$false)][ValidateScript({test-path $_})][string]$InputFile,[Parameter(Position=8, Mandatory=$false)][ValidateSet("DataSet", "DataTable", "DataRow")][string]$As="DataRow") 
        If($InputFile){
            $filePath=$(resolve-path $InputFile).path 
            $Query=[System.IO.File]::ReadAllText("$filePath") 
        }
        $conn=new-object System.Data.SqlClient.SQLConnection 
        If($Username){
            $ConnectionString="Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout
        }Else{
            $ConnectionString="Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
        }
        $conn.ConnectionString=$ConnectionString 
        #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose Parameter specified by caller 
        If($PSBoundParameters.Verbose){
            $conn.FireInfoMessageEventOnUserErrors=$true 
            $handler=[System.Data.SqlClient.SqlInfoMessageEventHandler]{Write-Verbose "$($_)"}
            $conn.add_InfoMessage($handler) 
        }
        $conn.Open() 
        $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
        $cmd.CommandTimeout=$QueryTimeout 
        $ds=New-Object system.Data.DataSet 
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
        [void]$da.fill($ds) 
        $conn.Close() 
        Switch($As){
            'DataSet'  {Write-Output($ds)}
            'DataTable'{Write-Output($ds.Tables)}
            'DataRow'  {Write-Output($ds.Tables[0])}
        }
    }
    # Gather info about the computer
    Function Get-Info{
        If($PowerShellVersion-ge6){
            $OS=Get-CimInstance Win32_OperatingSystem
            $ComputerSystem=Get-CimInstance Win32_ComputerSystem
            If($ComputerSystem.Manufacturer -like 'Lenovo'){
                $Model=(Get-CimInstance Win32_ComputerSystemProduct).Version
            }Else{
                $Model=$ComputerSystem.Model
            }
        }Else{
            $OS=Get-WmiObject Win32_OperatingSystem
            $ComputerSystem=Get-WmiObject Win32_ComputerSystem
            If($ComputerSystem.Manufacturer -like 'Lenovo'){
                $Model=(Get-WmiObject Win32_ComputerSystemProduct).Version
            }Else{
                $Model=$ComputerSystem.Model
            }
        }
        $obj=New-Object PSObject -Property @{
        Hostname=$ComputerSystem.Name;
        Manufacturer=$ComputerSystem.Manufacturer
        Model=$Model
        Operatingsystem=$OS.Caption;
        Architecture=$OS.OSArchitecture;
        Build=$OS.BuildNumber;
        InstallDate=Get-SmallDateTime -Date($OS.ConvertToDateTime($OS.InstallDate))
        LastLoggedOnUser=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\').LastLoggedOnUser;
        }
        $obj=$obj
        Write-Output $obj
    }
    # Start Getters - XML config file
    Function Get-LocalFilesPath{
        $obj=$Xml.Configuration.LocalFiles
        $obj=$ExecutionContext.InvokeCommand.ExpandString($obj)
        If($obj-eq$null){
            $obj=Join-path "$env:SystemDrive\ClientHealth"
        }
        Return $obj
    }
    Function Get-XMLConfigClientVersion{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Version'}|Select-Object -ExpandProperty '#text'
        Write-Output $obj
    }
    Function Get-XMLConfigClientSitecode{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'SiteCode'}|Select-Object -ExpandProperty '#text'
        Write-Output $obj
    }
    Function Get-XMLConfigClientDomain{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Domain'}|Select-Object -ExpandProperty '#text'
        Write-Output $obj
    }
    Function Get-XMLConfigClientAutoUpgrade{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'AutoUpgrade'}|Select-Object -ExpandProperty '#text'
        Write-Output $obj
    }
    Function Get-XMLConfigClientMaxLogSize{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Log'}|Select-Object -ExpandProperty 'MaxLogSize'
        Write-Output $obj
    }
    Function Get-XMLConfigClientMaxLogHistory{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Log'}|Select-Object -ExpandProperty 'MaxLogHistory'
        Write-Output $obj
    }
    Function Get-XMLConfigClientMaxLogSizeEnabled{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Log'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigClientCache{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'CacheSize'}|Select-Object -ExpandProperty 'Value'
        Write-Output $obj
    }
    Function Get-XMLConfigClientCacheDeleteOrphanedData{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'CacheSize'}|Select-Object -ExpandProperty 'DeleteOrphanedData'
        Write-Output $obj
    }
    Function Get-XMLConfigClientCacheEnable{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'CacheSize'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigClientShare{
        $obj=$Xml.Configuration.Client|Where-Object{$_.Name -like 'Share'}|Select-Object -ExpandProperty '#text' -ErrorAction SilentlyContinue
        If(!($obj)){
            $obj=$global:ScriptPath
        }#If Client share is empty, default to the script folder.
        Write-Output $obj
    }
    Function Get-XMLConfigUpdatesShare{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'Updates'}|Select-Object -ExpandProperty 'Share'
        If(!($obj)){
            $obj=Join-Path $global:ScriptPath "Updates"
        }
        Return $obj
    }
    Function Get-XMLConfigUpdatesEnable{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'Updates'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigUpdatesFix{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'Updates'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigLoggingShare{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'File'}|Select-Object -ExpandProperty 'Share'
        $obj=$ExecutionContext.InvokeCommand.ExpandString($obj)
        Return $obj
    }
    Function Get-XMLConfigLoggingLocalFile{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'File'}|Select-Object -ExpandProperty 'LocalLogFile'
        Write-Output $obj
    }
    Function Get-XMLConfigLoggingEnable{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'File'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigLoggingMaxHistory{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'File'}|Select-Object -ExpandProperty 'MaxLogHistory'
        Write-Output $obj
    }
    Function Get-XMLConfigLogginLevel{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'File'}|Select-Object -ExpandProperty 'Level'
        Write-Output $obj
    }
    Function Get-XMLConfigLoggingTimeFormat{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'Time'}|Select-Object -ExpandProperty 'Format'
        Write-Output $obj
    }
    Function Get-XMLConfigPendingRebootApp{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'PendingReboot'}|Select-Object -ExpandProperty 'StartRebootApplication'
        Write-Output $obj
    }
    Function Get-XMLConfigMaxRebootDays{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'MaxRebootDays'}|Select-Object -ExpandProperty 'Days'
        Write-Output $obj
    }
    Function Get-XMLConfigRebootApplication{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'RebootApplication'}|Select-Object -ExpandProperty 'Application'
        Write-Output $obj
    }
    Function Get-XMLConfigRebootApplicationEnable{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'RebootApplication'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigDNSCheck{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'DNSCheck'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigCcmSQLCELog{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'CcmSQLCELog'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigDNSFix{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'DNSCheck'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigDrivers{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'Drivers'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigPatchLevel{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'PatchLevel'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigOSDiskFreeSpace{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'OSDiskFreeSpace'}|Select-Object -ExpandProperty '#text'
        Write-Output $obj
    }
    Function Get-XMLConfigHardwareInventoryEnable{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'HardwareInventory'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigHardwareInventoryFix{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'HardwareInventory'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigSoftwareMeteringEnable{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'SoftwareMetering'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigSoftwareMeteringFix{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'SoftwareMetering'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigHardwareInventoryDays{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'HardwareInventory'}|Select-Object -ExpandProperty 'Days'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationAdminShare{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'AdminShare'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationClientProvisioningMode{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'ClientProvisioningMode'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationClientStateMessages{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'ClientStateMessages'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationClientWUAHandler{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'ClientWUAHandler'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationClientWUAHandlerDays{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'ClientWUAHandler'}|Select-Object -ExpandProperty 'Days'
        Write-Output $obj
    }
    Function Get-XMLConfigBITSCheck{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'BITSCheck'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigBITSCheckFix{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'BITSCheck'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigWMI{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'WMI'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigWMIRepairEnable{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'WMI'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigRefreshComplianceState{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'RefreshComplianceState'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    Function Get-XMLConfigRefreshComplianceStateDays{
        $obj=$Xml.Configuration.Option|Where-Object{$_.Name -like 'RefreshComplianceState'}|Select-Object -ExpandProperty 'Days'
        Write-Output $obj
    }
    Function Get-XMLConfigRemediationClientCertificate{
        $obj=$Xml.Configuration.Remediation|Where-Object{$_.Name -like 'ClientCertificate'}|Select-Object -ExpandProperty 'Fix'
        Write-Output $obj
    }
    Function Get-XMLConfigSQLServer{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'SQL'}|Select-Object -ExpandProperty 'Server'
        Write-Output $obj
    }
    Function Get-XMLConfigSQLLoggingEnable{
        $obj=$Xml.Configuration.Log|Where-Object{$_.Name -like 'SQL'}|Select-Object -ExpandProperty 'Enable'
        Write-Output $obj
    }
    # End Getters - XML config file
    Function GetComputerInfo{
        $info=Get-Info|Select-Object HostName, OperatingSystem, Architecture, Build, InstallDate, Manufacturer, Model, LastLoggedOnUser
        #$text='Computer info'+"`n"
        $text='Hostname: '+$info.HostName
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='Operatingsystem: '+$info.OperatingSystem
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='Architecture: '+$info.Architecture
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='Build: '+$info.Build
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='Manufacturer: '+$info.Manufacturer
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='Model: '+$info.Model
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='InstallDate: '+$info.InstallDate
        Write-Output $text
        #Out-LogFile -Xml $xml $text
        $text='LastLoggedOnUser: '+$info.LastLoggedOnUser
        Write-Output $text
        #Out-LogFile -Xml $xml $text
    }
    Function Test-ConfigMgrHealthLogging{
        # Verifies that logfiles are not bigger than max history
        $localLogging=(Get-XMLConfigLoggingLocalFile).ToLower()
        If($localLogging-eq"true"){
            $clientpath=Get-LocalFilesPath
            $logfile="$clientpath\ClientHealth.log"
            Test-LogFileHistory -Logfile $logfile
        }
        $fileshareLogging=(Get-XMLConfigLoggingEnable).ToLower()
        If($fileshareLogging-eq"true"){
            $logfile=Get-LogFileName
            Test-LogFileHistory -Logfile $logfile
        }
    }
    Function CleanUp{
        $clientpath=(Get-LocalFilesPath).ToLower()
        $forbidden="$env:SystemDrive", "$env:SystemDrive\", "$env:SystemDrive\windows", "$env:SystemDrive\windows\"
        $NoDelete=$false
        ForEach($item in $forbidden){
            If($clientpath -like $item){
                $NoDelete=$true
            }
        }
        If(((Test-Path "$clientpath\Temp" -ErrorAction SilentlyContinue)-eq$True)-and($NoDelete-eq$false)){
            Write-Verbose "Cleaning up temporary files in $clientpath\ClientHealth"
            Remove-Item "$clientpath\Temp" -Recurse -Force|Out-Null
        }
        $LocalLogging=((Get-XMLConfigLoggingLocalFile).ToString()).ToLower()
        If(($LocalLogging-ne"true")-and($NoDelete-eq$false)){
            Write-Verbose "Local logging disabled. Removing $clientpath\ClientHealth"
            Remove-Item "$clientpath\Temp" -Recurse -Force|Out-Null
        }
    }
    Function New-LogObject{
        # Write-Verbose "Start New-LogObject"
        If($PowerShellVersion-ge6){
            $OS=Get-CimInstance -class Win32_OperatingSystem
            $CS=Get-CimInstance -class Win32_ComputerSystem
            If($CS.Manufacturer -like 'Lenovo'){
                $Model=(Get-CimInstance Win32_ComputerSystemProduct).Version
            }Else{
                $Model=$CS.Model
            }
        }Else{
            $OS=Get-WmiObject -class Win32_OperatingSystem
            $CS=Get-WmiObject -class Win32_ComputerSystem
            If($CS.Manufacturer -like 'Lenovo'){
                $Model=(Get-WmiObject Win32_ComputerSystemProduct).Version
            }Else{
                $Model=$CS.Model
            }
        }
        # Handles different OS languages
        $Hostname=Get-Computername
        $OperatingSystem=$OS.Caption
        $Architecture=($OS.OSArchitecture-replace('([^0-9])(\.*)', ''))+'-Bit'
        $Build=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').BuildLabEx
        $Manufacturer=$CS.Manufacturer
        $Model=$Model
        $ClientVersion='Unknown'
        $Sitecode=Get-Sitecode
        $Domain=Get-Domain
        [int]$MaxLogSize=0
        $MaxLogHistory=0
        If($PowerShellVersion-ge6){
            $InstallDate=Get-SmallDateTime -Date($OS.InstallDate)
        }Else{
            $InstallDate=Get-SmallDateTime -Date($OS.ConvertToDateTime($OS.InstallDate))
        }
        $InstallDate=$InstallDate-replace'\.', ':'
        $LastLoggedOnUser=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\').LastLoggedOnUser
        $CacheSize=Get-ClientCache
        $Services='Unknown'
        $Updates='Unknown'
        $DNS='Unknown'
        $Drivers='Unknown'
        $ClientCertificate='Unknown'
        $PendingReboot='Unknown'
        $RebootApp='Unknown'
        If($PowerShellVersion-ge6){
            $LastBootTime=Get-SmallDateTime -Date($OS.LastBootUpTime)
        }Else{
            $LastBootTime=Get-SmallDateTime -Date($OS.ConvertToDateTime($OS.LastBootUpTime))
        }
        $LastBootTime=$LastBootTime-replace'\.', ':'
        $OSDiskFreeSpace=Get-OSDiskFreeSpace
        $AdminShare='Unknown'
        $ProvisioningMode='Unknown'
        $StateMessages='Unknown'
        $WUAHandler='Unknown'
        $WMI='Unknown'
        $RefreshComplianceState=Get-SmallDateTime
        $Updates='Unknown'
        $Services='Unknown'
        $smallDateTime=Get-SmallDateTime
        $smallDateTime=$smallDateTime-replace'\.', ':'
        [float]$PSVersion=[float]$psVersion=[float]$PSVersionTable.PSVersion.Major+([float]$PSVersionTable.PSVersion.Minor/10)
        [int]$PSBuild=[int]$PSVersionTable.PSVersion.Build
        If($PSBuild-le0){
            $PSBuild=$null
        }
        $UBR=Get-UBR
        $BITS=$null
        $obj=New-Object PSObject -Property @{
        Hostname=$Hostname
        Operatingsystem=$OperatingSystem
        Architecture=$Architecture
        Build=$Build
        Manufacturer=$Manufacturer
        Model=$Model
        InstallDate=$InstallDate
        OSUpdates=$null
        LastLoggedOnUser=$LastLoggedOnUser
        ClientVersion=$ClientVersion
        PSVersion=$PSVersion
        PSBuild=$PSBuild
        Sitecode=$Sitecode
        Domain=$Domain
        MaxLogSize=$MaxLogSize
        MaxLogHistory=$MaxLogHistory
        CacheSize=$CacheSize
        ClientCertificate=$Certificate
        ProvisioningMode=$ProvisioningMode
        DNS=$DNS
        Drivers=$Drivers
        Updates=$Updates
        PendingReboot=$PendingReboot
        LastBootTime=$LastBootTime
        OSDiskFreeSpace=$OSDiskFreeSpace
        Services=$Services
        AdminShare=$AdminShare
        StateMessages=$StateMessages
        WUAHandler=$WUAHandler
        WMI=$WMI
        RefreshComplianceState=$RefreshComplianceState
        ClientInstalled=$null
        Version=$Version
        Timestamp=$smallDateTime
        HWInventory=$null
        SWMetering=$null
        BITS=$BITS
        PatchLevel=$UBR
        ClientInstalledReason=$null
        RebootApp=$RebootApp
        }
        Write-Output $obj
        # Write-Verbose "End New-LogObject"
    }
    Function Get-SmallDateTime{Param([Parameter(Mandatory=$false)]$Date)
        #Write-Verbose "Start Get-SmallDateTime"
        $UTC=(Get-XMLConfigLoggingTimeFormat).ToLower()
        If($null-ne$Date){
            If($UTC-eq"utc"){
                $obj=(Get-UTCTime -DateTime $Date).ToString("yyyy-MM-dd HH:mm:ss")
            }Else{
                $obj=($Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }Else{
            $obj=Get-DateTime
        }
        $obj=$obj-replace'\.', ':'
        Write-Output $obj
        #Write-Verbose "End Get-SmallDateTime"
    }
    # Test some values are whole numbers before attempting to insert/update database
    Function Test-ValuesBeforeLogUpdate{
        Write-Verbose "Start Test-ValuesBeforeLogUpdate"
        [int]$Log.MaxLogSize=[Math]::Round($Log.MaxLogSize)
        [int]$Log.MaxLogHistory=[Math]::Round($Log.MaxLogHistory)
        [int]$Log.PSBuild=[Math]::Round($Log.PSBuild)
        [int]$Log.CacheSize=[Math]::Round($Log.CacheSize)
        Write-Verbose "End Test-ValuesBeforeLogUpdate"
    }
    Function Update-SQL{Param([Parameter(Mandatory=$true)]$Log,[Parameter(Mandatory=$false)]$Table)
        Write-Verbose "Start Update-SQL"
        Test-ValuesBeforeLogUpdate
        $SQLServer=Get-XMLConfigSQLServer
        $Database='ClientHealth'
        $table='dbo.Clients'
        $smallDateTime=Get-SmallDateTime
        If($null-ne$log.OSUpdates){
            # UPDATE
            $q1="OSUpdates='"+$log.OSUpdates+"', "
            # INSERT INTO
            $q2="OSUpdates, "
            # VALUES
            $q3="'"+$log.OSUpdates+"', "
        }Else{
            $q1=$null
            $q2=$null
            $q3=$null
        }
        If($null-ne$log.ClientInstalled){
            # UPDATE
            $q10="ClientInstalled='"+$log.ClientInstalled+"', "
            # INSERT INTO
            $q20="ClientInstalled, "
            # VALUES
            $q30="'"+$log.ClientInstalled+"', "
        }Else{
            $q10=$null
            $q20=$null
            $q30=$null
        }
        $query="begin tran
        if exists(SELECT * FROM $table WITH(updlock,serializable) WHERE Hostname='"+$log.Hostname+"')
        begin
        UPDATE $table SET Operatingsystem='"+$log.Operatingsystem+"', Architecture='"+$log.Architecture+"', Build='"+$log.Build+"', Manufacturer='"+$log.Manufacturer+"', Model='"+$log.Model+"', InstallDate='"+$log.InstallDate+"', $q1 LastLoggedOnUser='"+$log.LastLoggedOnUser+"', ClientVersion='"+$log.ClientVersion+"', PSVersion='"+$log.PSVersion+"', PSBuild='"+$log.PSBuild+"', Sitecode='"+$log.Sitecode+"', Domain='"+$log.Domain+"', MaxLogSize='"+$log.MaxLogSize+"', MaxLogHistory='"+$log.MaxLogHistory+"', CacheSize='"+$log.CacheSize+"', ClientCertificate='"+$log.ClientCertificate+"', ProvisioningMode='"+$log.ProvisioningMode+"', DNS='"+$log.DNS+"', Drivers='"+$log.Drivers+"', Updates='"+$log.Updates+"', PendingReboot='"+$log.PendingReboot+"', LastBootTime='"+$log.LastBootTime+"', OSDiskFreeSpace='"+$log.OSDiskFreeSpace+"', Services='"+$log.Services+"', AdminShare='"+$log.AdminShare+"', StateMessages='"+$log.StateMessages+"', WUAHandler='"+$log.WUAHandler+"', WMI='"+$log.WMI+"', RefreshComplianceState='"+$log.RefreshComplianceState+"', HWInventory='"+$log.HWInventory+"', Version='"+$Version+"', $q10 Timestamp='"+$smallDateTime+"', SWMetering='"+$log.SWMetering+"', BITS='"+$log.BITS+"', PatchLevel='"+$Log.PatchLevel+"', ClientInstalledReason='"+$log.ClientInstalledReason+"'
        WHERE Hostname='"+$log.Hostname+"'
        end
        Else
        begin
        INSERT INTO $table(Hostname, Operatingsystem, Architecture, Build, Manufacturer, Model, InstallDate, $q2 LastLoggedOnUser, ClientVersion, PSVersion, PSBuild, Sitecode, Domain, MaxLogSize, MaxLogHistory, CacheSize, ClientCertificate, ProvisioningMode, DNS, Drivers, Updates, PendingReboot, LastBootTime, OSDiskFreeSpace, Services, AdminShare, StateMessages, WUAHandler, WMI, RefreshComplianceState, HWInventory, Version, $q20 Timestamp, SWMetering, BITS, PatchLevel, ClientInstalledReason)
        VALUES('"+$log.Hostname+"', '"+$log.Operatingsystem+"', '"+$log.Architecture+"', '"+$log.Build+"', '"+$log.Manufacturer+"', '"+$log.Model+"', '"+$log.InstallDate+"', $q3 '"+$log.LastLoggedOnUser+"', '"+$log.ClientVersion+"', '"+$log.PSVersion+"', '"+$log.PSBuild+"', '"+$log.Sitecode+"', '"+$log.Domain+"', '"+$log.MaxLogSize+"', '"+$log.MaxLogHistory+"', '"+$log.CacheSize+"', '"+$log.ClientCertificate+"', '"+$log.ProvisioningMode+"', '"+$log.DNS+"', '"+$log.Drivers+"', '"+$log.Updates+"', '"+$log.PendingReboot+"', '"+$log.LastBootTime+"', '"+$log.OSDiskFreeSpace+"', '"+$log.Services+"', '"+$log.AdminShare+"', '"+$log.StateMessages+"', '"+$log.WUAHandler+"', '"+$log.WMI+"', '"+$log.RefreshComplianceState+"', '"+$log.HWInventory+"', '"+$log.Version+"', $q30 '"+$smallDateTime+"', '"+$log.SWMetering+"', '"+$log.BITS+"', '"+$Log.PatchLevel+"', '"+$Log.ClientInstalledReason+"')
        end
        commit tran"
        Try{
            Invoke-SqlCmd2 -ServerInstance $SQLServer -Database $Database -Query $query
        }Catch{
            $ErrorMessage=$_.Exception.Message
            $text="Error updating SQL with the following query: $transactSQL. Error: $ErrorMessage"
            Write-Error $text
            Out-LogFile -Xml $Xml -Text "ERROR Insert/Update SQL. SQL Query: $query `nSQL Error: $ErrorMessage"
        }
        Write-Verbose "End Update-SQL"
    }
    Function Update-LogFile{Param([Parameter(Mandatory=$true)]$Log,[Parameter(Mandatory=$false)]$Mode)
        # Start the logfile
        Write-Verbose "Start Update-LogFile"
        #$share=Get-XMLConfigLoggingShare
        Test-ValuesBeforeLogUpdate
        $logfile=$logfile=Get-LogFileName
        Test-LogFileHistory -Logfile $logfile
        $text="<--- ConfigMgr Client Health Check starting --->"
        $text+=$log|Select-Object Hostname, Operatingsystem, Architecture, Build, Model, InstallDate, OSUpdates, LastLoggedOnUser, ClientVersion, PSVersion, PSBuild, SiteCode, Domain, MaxLogSize, MaxLogHistory, CacheSize, Certificate, ProvisioningMode, DNS, PendingReboot, LastBootTime, OSDiskFreeSpace, Services, AdminShare, StateMessages, WUAHandler, WMI, RefreshComplianceState, ClientInstalled, Version, Timestamp, HWInventory, SWMetering, BITS, PatchLevel, ClientInstalledReason|Out-String
        $text=$text.replace("`t","")
        $text=$text.replace("  ","")
        $text=$text.replace(" :",":")
        $text=$text-creplace'(?m)^\s*\r?\n',''
        If($Mode-eq'Local'){
            Out-LogFile -Xml $xml -Text $text -Mode $Mode
        }ElseIf($Mode-eq'ClientInstalledFailed'){
            Out-LogFile -Xml $xml -Text $text -Mode $Mode
        }Else{
            Out-LogFile -Xml $xml -Text $text
        }
        Write-Verbose "End Update-LogFile"
    }
    #endregion
    # Set default restart values to false
    $newinstall=$false
    $restartCCMExec=$false
    $Reinstall=$false
    # Build the ConfigMgr Client Install Property string
    $propertyString=""
    ForEach($property in $Xml.Configuration.ClientInstallProperty){
        $propertyString=$propertyString+$property
        $propertyString=$propertyString+' '
    }
    $clientCacheSize=Get-XMLConfigClientCache
    $clientInstallProperties=$propertyString+"SMSCACHESIZE=$clientCacheSize"
    $clientAutoUpgrade=(Get-XMLConfigClientAutoUpgrade).ToLower()
    $AdminShare=Get-XMLConfigRemediationAdminShare
    $ClientProvisioningMode=Get-XMLConfigRemediationClientProvisioningMode
    $ClientStateMessages=Get-XMLConfigRemediationClientStateMessages
    $ClientWUAHandler=Get-XMLConfigRemediationClientWUAHandler
    $LogShare=Get-XMLConfigLoggingShare
    # Create a DataTable to store all changes to log files to be processed later. This to prevent false positives to remediate the next time script runs if error is already remediated.
    $SCCMLogJobs=New-Object System.Data.DataTable
    [Void]$SCCMLogJobs.Columns.Add("File")
    [Void]$SCCMLogJobs.Columns.Add("Text")
}
Process{
    Write-Verbose "Starting precheck. Determing if script will run or not."
    # Veriy script is running with administrative priveleges.
    If(-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        $text='ERROR: Powershell not running as Administrator! Client Health aborting.'
        Out-LogFile -Xml $Xml -Text $text
        Write-Error $text
        Exit 1
    }Else{
        $StartupText1="PowerShell version: "+$PSVersionTable.PSVersion+". Script executing with Administrator rights."
        Write-Host $StartupText1
        Write-Verbose "Determing if a task sequence is running."
        Try{
            $tsenv=New-Object -COMObject Microsoft.SMS.TSEnvironment|Out-Null
        }Catch{
            $tsenv=$null
        }
        If($tsenv-ne$null){
            $TSName=$tsenv.Value("_SMSTSAdvertID") 
            Write-Host "Task sequence $TSName is active executing on computer. ConfigMgr Client Health will not execute."
            Exit 1
        }Else{
            $StartupText2="ConfigMgr Client Health "+$Version+" starting."
            Write-Host $StartupText2
        }
    }
    $LocalLogging=((Get-XMLConfigLoggingLocalFile).ToString()).ToLower()
    $FileLogging=((Get-XMLConfigLoggingEnable).ToString()).ToLower()
    $FileLogLevel=((Get-XMLConfigLogginLevel).ToString()).ToLower()
    $SQLLogging=((Get-XMLConfigSQLLoggingEnable).ToString()).ToLower()
    $RegisTryKey="HKLM:\Software\ConfigMgrClientHealth"
    $LastRunRegisTryValueName="LastRun"
    #Get the last run from the regisTry, defaulting to the minimum date value if the script has never ran.
    Try{
        [datetime]$LastRun=Get-RegisTryValue -Path $RegisTryKey -Name $LastRunRegisTryValueName
    }Catch{
        $LastRun=[datetime]::MinValue
    }
    Write-Output "Script last ran: $($LastRun)"
    Write-Verbose "Testing if log files are bigger than max history for logfiles."
    Test-ConfigMgrHealthLogging
    # Create the log object containing the result of health check
    $Log=New-LogObject
    Write-Verbose 'Testing SQL Server connection'
    If(($SQLLogging -like 'true')-and((Test-SQLConnection)-eq$false)){
        # Failed to create SQL connection. Logging this error to fileshare and aborting script.
        #Exit 1
    }
    Write-Verbose 'Validating WMI is not corrupt...'
    $WMI=Get-XMLConfigWMI
    If($WMI -like 'True'){
        Write-Verbose 'Checking if WMI is corrupt. Will reinstall configmgr client if WMI is rebuilt.'
        If((Test-WMI -log $Log)-eq$true){
            $reinstall=$true
            New-ClientInstalledReason -Log $Log -Message "Corrupt WMI."
        }
    }
    Write-Verbose 'Determining if compliance state should be resent...'
    $RefreshComplianceState=Get-XMLConfigRefreshComplianceState
    If($RefreshComplianceState -like 'True'){
        $RefreshComplianceStateDays=Get-XMLConfigRefreshComplianceStateDays
        Write-Verbose "Checking if compliance state should be resent after $($RefreshComplianceStateDays) days."
        Test-RefreshComplianceState -Days $RefreshComplianceStateDays -RegisTryKey $RegisTryKey  -log $Log
    }
    Write-Verbose 'Testing if ConfigMgr client is installed. Installing if not.'
    Test-ConfigMgrClient -Log $Log
    Write-Verbose 'Validating if ConfigMgr client is running the minimum version...'
    If((Test-ClientVersion -Log $log)-eq$true){
        If($clientAutoUpgrade -like 'true'){
            $reinstall=$true
            New-ClientInstalledReason -Log $Log -Message "Below minimum verison."
        }
    }
    <#
    Write-Verbose 'Validate that ConfigMgr client do not have CcmSQLCE.log and are not in debug mode'
    If(Test-CcmSQLCELog-eq$true){
        # This is a very bad situation. ConfigMgr agent is fubar. Local SDF files are deleted by the test itself, now reinstalling client immediatly. Waiting 10 minutes before continuing with health check.
        Resolve-Client -Xml $xml -ClientInstallProperties $ClientInstallProperties
        Start-Sleep -Seconds 600
    }
    #>
    Write-Verbose 'Validating services...'
    Test-Services -Xml $Xml -log $log
    Write-Verbose 'Validating SMSTSMgr service is depenent on CCMExec service...'
    Test-SMSTSMgr
    Write-Verbose 'Validating ConfigMgr SiteCode...'
    Test-ClientSiteCode -Log $Log
    Write-Verbose 'Validating client cache size. Will restart configmgr client if cache size is changed'    
    $CacheCheckEnabled=Get-XMLConfigClientCacheEnable
    If($CacheCheckEnabled -like 'True'){
        $TestClientCacheSzie=Test-ClientCacheSize -Log $Log
        # This check is now able to set ClientCacheSize without restarting CCMExec service.
        If($TestClientCacheSzie-eq$true){$restartCCMExec=$false}
    }
    If((Get-XMLConfigClientMaxLogSizeEnabled -like 'True')-eq$true){
        Write-Verbose 'Validating Max CCMClient Log Size...'
        $TestClientLogSize=Test-ClientLogSize -Log $Log
        If($TestClientLogSize-eq$true){$restartCCMExec=$true}
    }
    Write-Verbose 'Validating CCMClient provisioning mode...'
    If(($ClientProvisioningMode -like 'True')-eq$true){Test-ProvisioningMode -log $log}
    Write-Verbose 'Validating CCMClient certificate...'
    If((Get-XMLConfigRemediationClientCertificate -like 'True')-eq$true){Test-CCMCertificateError -Log $Log}
    If(Get-XMLConfigHardwareInventoryEnable -like 'True'){Test-SCCMHardwareInventoryScan -Log $log}
    If(Get-XMLConfigSoftwareMeteringEnable -like 'True'){
        Write-Verbose "Testing software metering prep driver check"
        If((Test-SoftwareMeteringPrepDriver -Log $Log)-eq$false){$restartCCMExec=$true}
    }
    Write-Verbose 'Validating DNS...'
    If((Get-XMLConfigDNSCheck -like 'True')-eq$true){Test-DNSConfiguration -Log $log}
    Write-Verbose 'Validating BITS'
    If(Get-XMLConfigBITSCheck -like 'True'){
        If((Test-BITS -Log $Log)-eq$true){
            #$Reinstall=$true
        }
    }
    If(($ClientWUAHandler -like 'True')-eq$true){
        Write-Verbose 'Validating Windows Update Scan not broken by bad group policy...'
        $days=Get-XMLConfigRemediationClientWUAHandlerDays
        Test-RegisTryPol -Days $days -log $log -StartTime $LastRun
    }
    Write-Verbose 'Validating that CCMClient is sending state messages...'
    If(($ClientStateMessages -like 'True')-eq$true){Test-UpdateStore -log $log}
    Write-Verbose 'Validating Admin$ and C$ are shared...'
    If(($AdminShare -like 'True')-eq$true){Test-AdminShare -log $log}
    Write-Verbose 'Testing that all devices have functional drivers.'
    If((Get-XMLConfigDrivers -like 'True')-eq$true){Test-MissingDrivers -Log $log}
    $UpdatesEnabled=Get-XMLConfigUpdatesEnable
    If($UpdatesEnabled -like 'True'){
        Write-Verbose 'Validating required updates are installed...'
        Test-Update -Log $log
    }
    Write-Verbose "Validating $env:SystemDrive free diskspace(Only warning, no remediation)..."
    Test-DiskSpace
    Write-Verbose 'Getting install date of last OS patch for SQL log'
    Get-LastInstalledPatches -Log $log
    Write-Verbose 'Sending unsent state messages if any'
    Get-SCCMPolicySendUnsentStateMessages
    Write-Verbose 'Getting Source Update Message policy and policy to trigger scan update source'
    If($newinstall-eq$false){
        Get-SCCMPolicySourceUpdateMessage
        Get-SCCMPolicyScanUpdateSource
        Get-SCCMPolicySendUnsentStateMessages
    }
    Get-SCCMPolicyMachineEvaluation
    # Restart ConfigMgr client if tagged for restart and no reinstall tag
    If(($restartCCMExec-eq$true)-and($Reinstall-eq$false)){
        Write-Output "Restarting service CcmExec..."
        If($SCCMLogJobs.Rows.Count-ge1){
            Stop-Service -Name CcmExec
            Write-Verbose "Processing changes to SCCM logfiles after remediation to prevent remediation again next time script runs."
            Update-SCCMLogFile
            Start-Service -Name CcmExec
        }Else{
            Restart-Service -Name CcmExec
        }
        $Log.MaxLogSize=Get-ClientMaxLogSize
        $Log.MaxLogHistory=Get-ClientMaxLogHistory
        $log.CacheSize=Get-ClientCache
    }
    # Updating SQL Log object with current version number
    $log.Version=$Version
    Write-Verbose 'Cleaning up after healthcheck'
    CleanUp
    Write-Verbose 'Validating pending reboot...'
    Test-PendingReboot -log $log
    Write-Verbose 'Getting last reboot time'
    Get-LastReboot -Xml $xml
    If(Get-XMLConfigClientCacheDeleteOrphanedData -like "true"){
        Write-Verbose "Removing orphaned ccm client cache items."
        Remove-CCMOrphanedCache
    }
    # Reinstall client if tagged for reinstall and configmgr client is not already installing
    $proc=Get-Process ccmsetup -ErrorAction SilentlyContinue
    If(($reinstall-eq$true)-and($null-ne$proc)){
        Write-Warning "ConfigMgr Client set to reinstall, but ccmsetup.exe is already running."
    }ElseIf(($Reinstall-eq$true)-and($null-eq$proc)){
        Write-Verbose 'Reinstalling ConfigMgr Client'
        Resolve-Client -Xml $Xml -ClientInstallProperties $ClientInstallProperties
        # Add smalldate timestamp in SQL for when client was installed by Client Health.
        $log.ClientInstalled=Get-SmallDateTime
        $Log.MaxLogSize=Get-ClientMaxLogSize
        $Log.MaxLogHistory=Get-ClientMaxLogHistory
        $log.CacheSize=Get-ClientCache
    }
    # Trigger default Microsoft CM client health evaluation
    Start-Ccmeval
    Write-Verbose "End Process"
}
End{
    # Update database and logfile with results
    #Set the last run.
    $Date=Get-Date
    Set-RegisTryValue -Path $RegisTryKey -Name $LastRunRegisTryValueName -Value $Date
    Write-Output "Setting last ran to $($Date)"
    If($LocalLogging -like 'true'){
        Write-Output 'Updating local logfile with results'
        Update-LogFile -Log $log -Mode 'Local'
    }
    If(($FileLogging -like 'true')-and($FileLogLevel -like 'full')){
        Write-Output 'Updating fileshare logfile with results' 
        Update-LogFile -Log $log
    }
    If(($SQLLogging -like 'true')-and(($Webservice-eq$null))-or($Webservice-eq"")){
        Write-Output 'Updating SQL database with results'
        Update-SQL -Log $log
    }
    If($Webservice){
        Write-Output 'Updating SQL database with results using webservice'
        Update-Webservice -URI $Webservice -Log $Log
    }
    Write-Verbose "Client Health script finished"
}
