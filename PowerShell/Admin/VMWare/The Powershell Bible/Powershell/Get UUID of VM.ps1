Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.VDS
Connect-VIServer -Server 172.26.116.82 -Protocol https -User sa_dev_tidal -Password Aec@dallas

$vmUUID = Get-VM WXEROXtest10011 | %{(Get-View $_.Id).config.uuid}
Write-Output "UUID=$vmUUID"