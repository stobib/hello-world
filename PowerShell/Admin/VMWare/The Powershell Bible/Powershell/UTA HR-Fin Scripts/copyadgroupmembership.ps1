#RUN SCRIPT AS ADMIN AND IN CORRECT DOMAIN IN ORDER TO FUNCTION PROPERLY


Import-Module ActiveDirectory

$ToGroup = "ToGroup Remote Desktop Users"
$FromGroup = "FromGroup Remote Desktop Users"


$Users = Get-ADGroupMember -Identity $FromGroup 

Write-Host = $Users

ForEach ($User in $Users)
{	
    $UserToAdd = Get-ADUser -Identity $User
    Add-ADGroupMember -Identity $ToGroup -Member $UserToAdd
}