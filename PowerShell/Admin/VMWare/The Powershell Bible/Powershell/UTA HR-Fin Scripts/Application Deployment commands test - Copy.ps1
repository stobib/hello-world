




#$Lowriskregpath ="HKCU:\Software\Microsoft\Windows\Currentversion\Policies\Associations"
#$Lowriskregfile = "LowRiskFileTypes"
#$LowRiskFileTypes = ".exe,.msp,.msi"
#Function Addlowriskfiles()
#{
#New-Item -Path $Lowriskregpath -erroraction silentlycontinue |out-null
#New-ItemProperty $Lowriskregpath -name $Lowriskregfile -value $LowRiskFileTypes -propertyType String -erroraction silentlycontinue |out-null
#}
#Function removelowriskfiles()
#{
#remove-itemproperty -path $Lowriskregpath -name $Lowriskregfile -erroraction silentlycontinue
#}

#Addlowriskfiles   

#$arguments = 'msiexec /q /i/'
#start-process -FilePath 'C:\Users\dgrays\Documents\ACS\ApplicationISOs\GoogleChromeStandaloneEnterprise.msi'-ArgumentList '/package | /i GoogleChromeStandaloneEnterprise.msi /qn'  -wait


#[Environment]::SetEnvironmentVariable("SEE_MASK_NOZONECHECKS", "1","Process")
#$machine=[System.Net.Dns]::GetHostName()
#$product= [WMICLASS]"\\$machine\ROOT\CIMV2:win32_Product"
#$product.Install("C:\Users\dgrays\Documents\ACS\ApplicationISOs\GoogleChromeStandaloneEnterprise.msi")
#[Environment]::SetEnvironmentVariable("SEE_MASK_NOZONECHECKS",$null,"Process")




#removelowriskfiles

