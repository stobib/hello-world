
$base = "ou=staffgroups,ou=staff,ou=wacoisd.org,dc=ad,dc=wacoisd,dc=org"
$foldeList = Get-ChildItem -Path "f:\home"
$ldap = "(cn=*)"

foreach ($Item in $folderList) {
    $folder = $Item.Name
    $UserID = [Environment]::UserName
    $viewGroupList = get-adgroup -ldapfilter $ldap -searchbase $base -searchscope onelevel| ?{ $_.name -match $folder } | select name
    $noViewGroupList = get-adgroup -ldapfilter $ldap -searchbase $base -searchscope onelevel| ?{ $_.name -notmatch $folder } | select name
    $dir = $folder
    
    # $group = "MSMITH-EST-PC\Test"
    $acl = Get-Item $dir |get-acl

    # This removes inheritance
    $acl.SetAccessRuleProtection($true,$true)
    $acl |Set-Acl
    $acl = Get-Item $dir |get-acl

    # This removes the access for the builtin user group from the Personal folder
    foreach ($G in $noViewGroupList) {
        $noview = $g.name
        $acl.Access |where {$_.IdentityReference -eq $noview} |%{$acl.RemoveAccessRule($_)}
        $acl |Set-Acl
        }
    # This adds Read access to the apropriate group
    foreach ($g in $viewGropList) {
        $view = $g.Name
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList @($view,"ReadAndExecute","Allow")
        $acl.SetAccessRule($rule)
        $acl |Set-Acl
        }
}
