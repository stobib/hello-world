﻿#Load VMWare Snapin if it hasn't been loaded
$SnapinLoaded = get-pssnapin | Where-Object {$_.name -like "*VMware*"}
if (!$SnapinLoaded) {
	Add-PSSnapin VMware.VimAutomation.Core
    Write-Host "VMware Snapin has been loaded!"
}
else
{
    Write-Host "VMware Snapin was already loaded!"
}

# Show input box popup and return the value entered by the user.
function Read-InputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
    Add-Type -AssemblyName Microsoft.VisualBasic
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText)
}


# Asks the user if they want to continue or exit. 
Function AreYouSure
{
	# Creates a windows dialogue box
	$a = new-object -comobject wscript.shell 
	$intAnswer = $a.popup("Do you want to continue to run this script?",0,"Continue Running Script",4) 
	If ($intAnswer -eq 6) 
	{ 
	    $a.popup("You have chosen to continue running the script! :-)",0,"Continuing Script :-)") 
		#Write decision to the log
		Write-Host ""
		Write-Host "Admin has chosen to continue running the script! :-)"
		Write-Host ""
	} 
	else 
	{ 
	    $a.popup("You have chosen to exit the script! :-(",0,"Now Exiting! :-(") 
		#Write decision to the log
		Write-Host ""
		Write-Host "Admin has chosen to exit the script! :-("
		Write-Host ""
		exit
	} 
	  
	#Button Types  
	# 
	#Value  Description   
	#0 		Show OK button. 
	#1 		Show OK and Cancel buttons. 
	#2 		Show Abort, Retry, and Ignore buttons. 
	#3 		Show Yes, No, and Cancel buttons. 
	#4 		Show Yes and No buttons. 
	#5		Show Retry and Cancel buttons. 
}


#Function to Check Connectivity with VIServer
Function CheckVIConnectivity{
#If connected, show which ones
	if ($defaultVIServers) {
	# Asks the user if they want to continue or exit. 
	AreYouSure	
	}
	Else{
	#If not connected to any hosts, connect to a VCenter
	Write-Host "Prompting for user input"
    $userVIServer = Read-InputBoxDialog -Message "Please enter a valid VCenter Server Hostname or IP" -WindowTitle "VCenter Hostname"
    Connect-VIServer -Server $userVIServer
	Write-Host "Now Connected." -ForegroundColor Red

	}
}
# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrEmpty($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}


#Start Program

#Check Connectivity with Vcenter
CheckVIConnectivity

#Get list of ESXi Servers from file
$filepath = Read-OpenFileDialog -WindowTitle "Select Text File With ESXi Hostnames" -InitialDirectory 'C:\' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($filePath)) { Write-Host "You selected the file: $filePath" } 
else { "You did not select a file." }

#Assign list of ESXi Servers to a variable
$esxiHosts = Get-Content -Path $filepath

#Get names of NTP Servers to add
$ntpServer = Read-InputBoxDialog -Message "Please enter the ntp server you would like to add." -WindowTitle "NTP Server to add"



#Pre-Check

#Check ntpd Status on Hosts
Get-VMHost $esxiHosts | Get-VmHostService | Where-Object {$_.key -eq "ntpd"}

#Check Firewall Status for NTP on Hosts
Get-VMHost $esxiHosts | Get-VMHostFirewallException | Where {$_.Name -eq "NTP client"}



#Set Values/Do Work

ForEach($aHost in $esxiHosts){

#Add NTP Servers to Hosts
Get-VMHost $aHost | Add-VMHostNtpServer $ntpServer

#Set NTPD Startup Policies to Automatic
Get-VmHostService -VMHost $ahost | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService | Set-VMHostService -policy "automatic"

#Open ESXi Host Firewalls for NTP communication
Get-VMHost $aHost | Get-VMHostFirewallException | where {$_.Name -eq "NTP client"} |Set-VMHostFirewallException -Enabled:$true

}

#Post Check

#Check ntpd Status on Hosts
Get-VMHost $esxiHosts | Get-VmHostService | Where-Object {$_.key -eq "ntpd"}

#Check Firewall Status for NTP on Hosts
Get-VMHost $esxiHosts | Get-VMHostFirewallException | Where {$_.Name -eq "NTP client"}
