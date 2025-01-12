# Adds the base cmdlets if needed
$SnapinLoaded = get-pssnapin | Where-Object {$_.name -like "*VMware*"}
if (!$SnapinLoaded) {
	Add-PSSnapin VMware.VimAutomation.Core
}

#Connect-VIServer -server vc-manager.uta.edu

$VMs = get-vm -Name dav-1.ardclb.uta.edu,fs-edge-56-inf.uta.edu,highpoint-test.uta.edu,isec2.uta.edu,labrador,libwebnmprod-1.ardclb.uta.edu,mumble.uta.edu,oraprdinf1.uta.edu,sawmilltest.uta.edu,splunkindex-6.ardclb.uta.edu,vc-sa.uta.edu,webappsdev-1,webmaster.pcilb.uta.edu
echo $VMs

<#
foreach ($v in $VMs) {
restart-vm -vm $v.name -confirm:$true
}
#>
