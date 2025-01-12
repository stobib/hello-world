Import-Module ActiveDirectory

#$server = "AD-Domain-Controller-Name"
$server = "dc-1-ardc.shared.utsystem.edu"

#$user = "shared\username"
$user = "shared\dgrays-uta"

$creds = Get-Credential -Credential $User 

$domain = Get-ADDomain -Server $SERVER -Credential $CREDS

$domain | Export-Csv c:\pwscriptoutputs\domaindiscovery\dcdisc.csv

echo "" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
echo "Allowed DNS Suffixes" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
foreach ($al in $domain.AllowedDNSSuffixes) {
    $text = $al
    $text >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
    }
echo "" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
echo "Child Domains" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
foreach ($al in $domain.ChildDomains) {
    $text = $al
    $text >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
    }
echo "" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
echo "Domain Controllers" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
foreach ($dc in $domain.ReplicaDirectoryServers) {
    $text = "Name," + $dc
    $text >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
}
echo "" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
echo "Read Only Domain Controllers" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
foreach ($rodc in $domain.ReadOnlyReplicaDirectoryServers) {
    $text = "Name," + $rodc
    $text >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
    }
echo "" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
echo "Subordinate References" >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
foreach ($sr in $domain.SubordinateReferences) {
    $text = $sr
    $text >> c:\pwscriptoutputs\domaindiscovery\dcdisc.csv
    }
