Function Get-CasCpu {

$Serverlist = get-clientAccessServer
foreach ($s in $serverlist) {
    $server = $s.name
    $CPU = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average
    $Server + " : " + $CPU
    }
 }