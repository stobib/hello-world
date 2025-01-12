# Adds the base cmdlets if needed
$SnapinLoaded = get-pssnapin | Where-Object {$_.name -like "*VMware*"}
if (!$SnapinLoaded) {
	Add-PSSnapin VMware.VimAutomation.Core
}
Connect-VIServer -server vc-manager.uta.edu -user uta\dgrays 

$VMs = get-vm -Name | where {($_.folder -notlike "ACS ITO") -and ($_.folder -notlike "Xerox")}

<#
foreach ($v in $VMs) {
shutdown-vmguest -vm $v.name -confirm:$false
}

#>