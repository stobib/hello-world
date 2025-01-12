# Adds the base cmdlets if needed
$SnapinLoaded = get-pssnapin | Where-Object {$_.name -like "*VMware*"}
if (!$SnapinLoaded) {
	Add-PSSnapin VMware.VimAutomation.Core
}

Connect-VIServer -server vc-manager.uta.edu

Get-VM | Select Name, State