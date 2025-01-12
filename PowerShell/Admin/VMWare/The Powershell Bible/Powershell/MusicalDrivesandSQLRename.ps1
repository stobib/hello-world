#Sets ISO name for proper movement
param([string]$isoName)
echo $isoName
$isoName = $isoName.Replace(".iso","")
$isoName = $isoName.Substring(0,[System.Math]::Min(16, $isoName.Length))
echo $isoName

#Gets all drives other than the C drive
$drives = Get-WmiObject win32_volume | where {$_.driveletter -notlike "c:"}

#Moves specific drive letters to the end of the alphabet
ForEach ($D in $drives) {
    $label = $D.label
    if ($label -like $isoName) {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="Z:"}
    }
    if ($label -like "data") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="Y:"}
    }
    if ($label -like "logs") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="X:"}
    }
    if ($label -like "temp") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="W:"}
    }
    if ($label -like "backup") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="V:"}
    }
    if ($label -like "System Recovery") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="U:"}
    } 
}
#Sets Delay for 
Start-Sleep -Second 10

#Gets all drives other than the C drive (with refreshed names)
$drives = Get-WmiObject win32_volume | where {$_.driveletter -notlike "c:"}

#Moves specific drive letters to the end of the alphabet
ForEach ($D in $drives) {
    $label = $D.label

    #IMPORTANT!!!! RENAME "Post Provision S"(below) TO WHATEVER THE NAME OF THE MOUNTED ISO IS!!!!
    if ($label -like $isoName) {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="D:"}
    }
    if ($label -like "data") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="E:"}
    }
    if ($label -like "logs") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="F:"}
    }
    if ($label -like "temp") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="G:"}
    }
    if ($label -like "backup") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="H:"}
    }
    if ($label -like "System Recovery") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="I:"}
    } 
}

#Starts SQL Server to rename the instance
net start MSSQLSERVER

#Makes Local Administrator able to administrate SQL Server
sqlcmd -E -Q "exec sp_addsrvrolemember 'BUILTIN\Administrators','sysadmin';"

#Renames SQL Instance to local machine name
sqlcmd -E -Q "exec sp_dropserver @@SERVERNAME; exec sp_addserver '%1',local"

#Stops SQL server
net stop MSSQLSERVER