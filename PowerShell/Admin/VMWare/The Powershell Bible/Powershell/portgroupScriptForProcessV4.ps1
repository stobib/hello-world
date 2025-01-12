#Add-PSSnapin VMware.VimAutomation.Core
#Add-PSSnapin VMware.VimAutomation.VDS
#Connect-VIServer -Server devdalvc00.dev.cloudcore.local -Protocol https -User sa_dev_tidal -Password Aec@dallas

#Function that returns portgroup information when provided a portgroup



function Get-dvPgFreePort{
  param(
  [CmdletBinding()]
  [string]$PortGroup
  )
    
    if($PortGroup -ne $FALSE){
        $dvPortgroup = Get-VDPortGroup  -Name $PortGroup 
        $dvPortgroupInfo = New-Object PSObject -Property @{            
            Name = $dvPortgroup.Name
            Key = $dvPortgroup.Key
            VlanId = $dvPortgroup.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId
            Portbinding = $dvPortgroup.Portbinding
            NumPorts = $dvPortgroup.NumPorts
            PortsFree = ($dvPortgroup.ExtensionData.PortKeys.count - $dvPortgroup.ExtensionData.vm.count)
        }
    }
    else{
        $dvPortgroupInfo = New-Object PSObject -Property @{            
            Name = "Not Found"
            Key = "Not Found"
            VlanId = "Not Found"
            Portbinding = "Not Found"
            NumPorts ="0"
            PortsFree ="0"
        }    
    }            
    return $dvPortgroupInfo
}


#Write in the name of your portgroup
$pgWEB = "dvpg_01070_APRIL_WEB"
$pgAPP = "dvpg_01070_APRIL_APP"
$pgDB = "dvpg_01070_APRIL_DB"


$userSelectZone = "WEB"
[int]$CustomerNetCapacity = "256"
[int]$standardPortIncrease = "5"


#Collects and organizes information for each zone into an object.
$freePortsWEB = Get-dvPgFreePort -PortGroup $pgWEB
$freePortsAPP = Get-dvPgFreePort -PortGroup $pgAPP
$freePortsDB = Get-dvPgFreePort -PortGroup $pgDB

#writes "Not Found" if a portgroup is not found for each zone
$foundPgWEB = $freePortsWEB.Name
$foundPgAPP = $freePortsAPP.Name
$foundPgDB = $freePortsDB.Name

#gets the the amount of free ports in each zone
$numOfFreePortsWEB = $freePortsWEB.PortsFree
$numOfFreePortsAPP = $freePortsAPP.PortsFree
$numOfFreePortsDB = $freePortsDB.PortsFree

#gets the total portgroup capacity for each zone
$TotalPortsWEB = $freePortsWEB.NumPorts
$TotalPortsAPP = $freePortsAPP.NumPorts
$TotalPortsDB = $freePortsDB.NumPorts



#gets the current total Network Capacity
[int]$CurrentNetworkCapacity = [int]$TotalPortsWEB + [int]$TotalPortsAPP + [int]$TotalPortsDB

#gets current network usage
[int]$CurrentNetworkUsage = ([int]$TotalPortsWEB-[int]$numOfFreePortsWEB) + ([int]$TotalPortsAPP-[int]$numOfFreePortsAPP) + ([int]$TotalDBports-[int]$numOfFreePortsDB)


#Build dynamic variable for finding the amount of free ports in an user selected zone
#and for determining if the user selected zone was found

$userSelectFreeZone = Get-Variable "numofFreePorts$userselectZone"
$userSelectZoneFound = Get-Variable "foundPg$userselectZone"


#Determine Addition of ports if needed
$portsLefttoAdd = $CustomerNetCapacity - $CurrentNetworkCapacity

if($userSelectZoneFound.value -ne "Not Found"){
    if($userSelectFreeZone.value -gt 5){
        $numAddPorts = 0
        $addWkNow ="True"
        $fullNetCap="False"    
    }
    elseif($portsLefttoAdd -gt $standardPortIncrease ){
        $numAddPorts = $standardPortIncrease
        $addWkNow ="False"
        $fullNetCap="False"
    }
    elseif(($portsLefttoAdd -lt $standardPortIncrease) -and ($portsLefttoAdd -gt 0)){
        $numAddPorts = $portsLefttoAdd
        $addWkNow ="False"
        $fullNetCap="True"
    }
    elseif(($userSelectFreeZone.value -le 5) -and ($userSelectFreeZone.value -gt 0)){
        $numAddPorts = 0
        $addWkNow ="True"
        $fullNetCap = "True"       
    }    
    else {
        $numAddPorts = 0
        $addWkNow ="False"
        $fullNetCap="True"
    }
}
else{
$numAddPorts = 0
$addWkNow ="False"
$fullNetCap="Unknown"
}    


#Setup Writing Output
$foundUserPG=$userSelectZoneFound.value
$setUserPG = Get-Variable "TotalPorts$userselectZone"

if($numAddPorts -ne 0){
$setUserPG= [int]$setUserPG.value + [int]$numAddPorts
}
else{$setUserPG = "Not Applicable"}


#Write Output
Write-Output "WEB PG Found=$foundPgWEB"
Write-Output "WEB Free Ports=$numOfFreePortsWEB"
Write-Output "WEB Total Ports=$TotalPortsWEB"
Write-Output "APP PG Found=$foundPgAPP"
Write-Output "APP Free Ports=$numOfFreePortsAPP"
Write-Output "APP Total Ports=$TotalPortsAPP"
Write-Output "DB PG Found=$foundPgDB"
Write-Output "DB Free Ports=$numOfFreePortsDB"
Write-Output "DB Total Ports=$TotalPortsDB"
Write-Output "Current Network Capacity=$CurrentNetworkCapacity"
Write-Output "Current Network Usage=$CurrentNetworkUsage"
Write-output "Add workload immediately=$addWkNow"
Write-output "At full customer network capacity=$fullNetCap"
Write-output "Number of Ports to Add=$numAddPorts"
Write-output "Number of Ports to Set Portgroup to=$setUserPG"
Write-output "User Selected Portgroup Found=$foundUserPG"