#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -Server devdalvc00.dev.cloudcore.local -Protocol https -User sa_dev_tidal -Password Aec@dallas


$fileName="\MusicalDrives.ps1"
$driveLetter = Invoke-VMScript -VM WXEROXtest10010  -ScriptText "(Get-WmiObject -Class Win32_CDRomDrive).drive" 
$driveLetter
#[string]$drive = $driveLetter | Select-String -pattern ".:"
#$runFile = $drive += $fileName
#$runFile=$runFile.Replace("`n",'')
#$runFile=$runFile.Replace("`r",'')
#Invoke-VMScript -VM WXEROXtest10010 -GuestUser Administrator -GuestPassword Password1 -ScriptType Powershell -ScriptText $runFile

#$cdDrive = Get-CDDrive -VM WXEROXtest10010
#Set-CDDrive -CD $cdDrive -Connected:$false -Confirm:$false

#-GuestUser Administrator -GuestPassword Password1