#####################
 #Set-myCredential.ps1
$username = "sa_dev_tidal"
$secpasswd = ConvertTo-SecureString "Aec@dallas" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
 #####################
$path = "\\UNC path"
New-Psdrive -name O -Psprovider FileSystem -root $path -credential $creds