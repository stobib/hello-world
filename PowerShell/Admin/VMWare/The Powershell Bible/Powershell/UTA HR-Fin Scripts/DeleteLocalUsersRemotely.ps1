
# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrEmpty($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}




#Prompt for list of computers and put them into an array

$filepath = Read-OpenFileDialog -WindowTitle "Select Text File with Windows Servers" -InitialDirectory 'C:\' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($filePath)) { Write-Host "You selected the file: $filePath" } 
else { "You did not select a file." }


$computers = Get-Content -Path $filepath



#Prompt for list of users and put them into an array

$userfilepath = Read-OpenFileDialog -WindowTitle "Select Text File with Users to delete" -InitialDirectory 'C:\' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($userfilePath)) { Write-Host "You selected the file: $userfilePath" } 
else { "You did not select a file." }


$peoples = Get-Content -Path $userfilepath




ForEach($computer in $computers){

    Write-Host "Starting Entry $computer"
    $computerTrue=[adsi]"WinNT://$computer"
    $localUsers = $computerTrue.Children | where {$_.SchemaClassName -eq 'user'}  |  % {$_.name[0].ToString()}
#    Write-Host "$localUsers"

        ForEach($person in $peoples){
               
            Write-Host "Starting User $person"
            if($localUsers -NotContains $person)
            {
            Write-Host "$person does not exist on $computer"
            }
            else
            {
            $computerTrue.delete("user","$person")
            Write-Host "Finishing User: $person on $computer"
            }
        }

}
