#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -Server 172.26.116.82 -Protocol https -User sa_dev_tidal -Password Aec@dallas

$PortGroup = "dvpg_0265_Nike"

$pg = Get-VirtualPortGroup -Distributed -Name $PortGroup
$Numofports = $pg.NumPorts

$Numofports