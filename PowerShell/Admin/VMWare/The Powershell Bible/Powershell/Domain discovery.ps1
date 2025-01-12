Import-Module ActiveDirectory

$server = "s-na-dal01dc11"

$user = "NAM\conitsmjs"
$creds = Get-Credential -Credential $User 

$domain = Get-ADDomain -Server $SERVER -Credential $CREDS

$domain | Export-Csv f:\est\accor\accor.csv

echo "" >> f:\est\accor\accor.csv
echo "Allowed DNS Suffixes" >> f:\est\accor\accor.csv
foreach ($al in $domain.AllowedDNSSuffixes) {
    $text = $al
    $text >> f:\est\accor\accor.csv
    }
echo "" >> f:\est\accor\accor.csv
echo "Child Domains" >> f:\est\accor\accor.csv
foreach ($al in $domain.ChildDomains) {
    $text = $al
    $text >> f:\est\accor\accor.csv
    }
echo "" >> f:\est\accor\accor.csv
echo "Domain Controllers" >> f:\est\accor\accor.csv
foreach ($dc in $domain.ReplicaDirectoryServers) {
    $text = "Name," + $dc
    $text >> f:\est\accor\accor.csv
}
echo "" >> f:\est\accor\accor.csv
echo "Read Only Domain Controllers" >> f:\est\accor\accor.csv
foreach ($rodc in $domain.ReadOnlyReplicaDirectoryServers) {
    $text = "Name," + $rodc
    $text >> f:\est\accor\accor.csv
    }
echo "" >> f:\est\accor\accor.csv
echo "Subordinate References" >> f:\est\accor\accor.csv
foreach ($sr in $domain.SubordinateReferences) {
    $text = $sr
    $text >> f:\est\accor\accor.csv
    }
