#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -Server vc-manager-ardc.shared.utsystem.edu -Protocol https -User shared\dgrays-uta -Password 




#$cmdline="echo -n " + "novell123" + " | passwd --stdin root"



#Invoke-VMScript -VM "SLES TEST" -GuestUser root -GuestPassword "Johnson" -ScriptType Bash -ScriptText $cmdline




#$vm = "WXEROXtest10010"

#Start-VM -VM $vm -confirm: $false

# For MAC Address
#start-sleep -seconds 200
#$mac = getmac

#write-host "MAC Address:" $mac



#Invoke-VMScript -VM WXEROXtest10030  -GuestUser Administrator -GuestPassword Password1 -ScriptType bat -ScriptText "powershell -noprofile Set-ExecutionPolicy RemoteSigned" 


#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -Server $args[0] -Protocol https -User $args[1]  -Password  $args[2]

#$vm = $args[3]

#shutdown-vmguest -vm $vm -confirm:$false

#Get-VIEvent -maxsamples 10000 | where {$_.Gettype().Name -eq "VmRemovedEvent"} | Sort CreatedTime -Descending | Select * -First 19

#$filename = "Post Provision Scripts.iso"
#echo $filename
#$filename = $filename.Replace(".iso","")
#$filename = $filename.Substring(0,[System.Math]::Min(16, $filename.Length))
#$filename = '"'+$filename+'"'
#echo $filename
#$runfile = "C:\MusicalDrivesandSQLRename.ps1"

#& $runfile -isoName "Post Provision Scripts.iso'