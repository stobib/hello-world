#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -Server 172.26.116.82 -Protocol https -User sa_dev_tidal -Password Aec@dallas


function Get-dvPgFreePort{
  <#
.SYNOPSIS  Get free ports on a dvSwitch portgroup
.DESCRIPTION The function will return 1 or more
  free ports on a dvSwitch portgroup
.NOTES  Author:  Luc Dekens
.PARAMETER PortGroup
  Specify the portgroup for which you want to retrieve
  free ports
.PARAMETER Number
  Specify the number of free ports you want to retrieve.
  The default is 1 port. If Number is greater than the
  number of available ports, the function will return all
  available ports
.EXAMPLE
  PS> Get-dvPgFreePort -PortGroup $pg
.EXAMPLE
  PS> Get-dvPgFreePort -PortGroup $pg -Number 5
#>

  param(
  [CmdletBinding()]
  [string]$PortGroup,
  [int]$Number = 1
  )

  $nicTypes = "VirtualE1000","VirtualE1000e","VirtualPCNet32",
  "VirtualVmxnet","VirtualVmxnet2","VirtualVmxnet3" 
  $ports = @{}

  $pg = Get-VirtualPortGroup -Distributed -Name $PortGroup
  $pg.ExtensionData.PortKeys | %{$ports.Add($_,$pg.Name)}

  Get-View $pg.ExtensionData.Vm | %{
    $nic = $_.Config.Hardware.Device | 
    where {$nicTypes -contains $_.GetType().Name -and
      $_.Backing.GetType().Name -match "Distributed"}
    $nic | %{$ports.Remove($_.Backing.Port.PortKey)}
  }

  if($Number -gt $ports.Keys.Count){
    $Number = $ports.Keys.Count
  }
  ($ports.Keys | Sort-Object)[0..($Number - 1)]
}

#Write in the name of your portgroup
$pg = "dvpg_NO_NETWORK_ACCESS"

#The Function above returns a specific number of port ID's that are free on the above portgroup
#in order to get all the free ports I have chosen a number below that is much larger than any portgroup
#will ever be so that the function will return all the free ports of that portgroup.
$numOfPortsNeeded = 5000

#Assigns free port id's of the given portgroup to an array
$freePorts = Get-dvPgFreePort -PortGroup $pg  -Number $numOfPortsNeeded

#gets the length of the array
$numOfFreePorts = $freePorts.length

#Prints the length of the array which is the number of free ports

$numOfFreePorts