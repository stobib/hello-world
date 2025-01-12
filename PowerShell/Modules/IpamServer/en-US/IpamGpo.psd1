# Localized	10/08/2016 04:53 AM (GMT)	303:4.80.0411 	IpamGPO.psd1
# Only add new (name,value) pairs to the end of this table
# Do not remove, insert or re-arrange entries
   ConvertFrom-StringData @'
       ###PSLOC start localizing
       #
       # helpID = VersionTooLow
       #
        
    #Error Msg
ErrorMsgServerDoesNotExist=Server {0} does not exist or could not be contacted.
ErrorMsgServerFqdnWrongFormat=Server name {0} should be given in 'Fully Qualified Domain Name' format.
ErrorMsgCreateGpoFailed=Failed to create GPO. {0}
ErrorMsgImportGpoFailed=Failed to import GPO. {0}
ErrorMsgLinkGpoFailed=Failed to link GPO. {0}
ErrorMsgRemoveAuthUserFailed=Failed to remove authenticated users from the GPO. {0}
ErrorMsgDeleteUserFailed=Failed to add user to the delegation list. {0}
ErrorMsgDeleteGroupFailed=Failed to add group to the delegation list. {0}
ErrorMsgGetDomainFailed=Failed to retrieve domain {0}. {1}
ErrorMsgGetDCServerFailed=Failed to retrieve domain controller for domain {0}. {1}
ErrorMsgDnsAclUpdateFailed=Failed to update DNS ACLs.
ErrorMsgIpamUGCreateFailed=Failed to create the universal group {0} on {1}. {2}
ErrorMsgCreateUGFailed=Failed to create universal group {0}. {1}
ErrorMsgAddIpamToUGFailed=Failed to add computer {0} to group {1}. {2}
ErrorMsgGetCurrentForestFailed=Failed to find the current forest. Please check connection to Domain Controller
ErrorMsgGetCurrentDomainFailed=Failed to find the current domain. Please check connection to Domain Controller
ErrorNotEnoughPriviledge=Make sure you have sufficient privileges to perform the operation.
ErrorMsgIpamMachineSIDNotAvaiable=IPAM machine SID could not be found from DN Name {0}. {1}
WarningDnsAclNotFound=Failed to update the DNS ACL {0} since the corresponding Active Directory object was not found. This is expected if you do not have the DNS Server role co-located with a domain controller in the domain. For standalone DNS servers, add the IPAM universal group (IPAMUG) or IPAM machine account to the local Administrators group on the DNS server in order to enable DNS RPC access for IPAM.

    #ShouldProcess/ShouldContinue Messages
Msg_ShouldProcess_WithUserOrGroup=The Invoke-IpamGpoProvisioning cmdlet creates and links three Group Policy Objects in the domain indicated by Domain parameter, for provisioning IPAM access settings on the servers that are managed by IPAM. The cmdlet also modifies the domain wide DNS ACL to enable read access for IPAM. The value of GpoPrefixName must be the same as the one provided in the IPAM provisioning wizard when selecting the option of Group Policy Based provisioning.
Msg_ShouldProcess_WithoutUserAndGroup=The Invoke-IpamGpoProvisioning cmdlet creates and links three Group Policy Objects in the domain indicated by Domain parameter, for provisioning IPAM access settings on the servers that are managed by IPAM. The cmdlet also modifies the domain wide DNS ACL to enable read access for IPAM. The value of GpoPrefixName must be the same as the one provided in the IPAM provisioning wizard when selecting the option of Group Policy Based provisioning.\n\nYou have not specified the optional parameters DelegatedGpoUser or DelegatedGpoGroup. The delegation parameters can be used to enable IPAM GPO edit privileges for users or groups who do not have domain or enterprise administrator privileges, but need to mark servers as managed or unmanaged in IPAM.
Msg_ShouldContinue_WithUserOrGroup=The Invoke-IpamGpoProvisioning cmdlet creates and links three Group Policy Objects in the domain indicated by Domain parameter, for provisioning IPAM access settings on the servers that are managed by IPAM. The cmdlet also modifies the domain wide DNS ACL to enable read access for IPAM. The value of GpoPrefixName must be the same as the one provided in the IPAM provisioning wizard when selecting the option of Group Policy Based provisioning. {0}
Msg_ShouldContinue_WithoutUserAndGroup=The Invoke-IpamGpoProvisioning cmdlet creates and links three Group Policy Objects in the domain indicated by Domain parameter, for provisioning IPAM access settings on the servers that are managed by IPAM. The cmdlet also modifies the domain wide DNS ACL to enable read access for IPAM. The value of GpoPrefixName must be the same as the one provided in the IPAM provisioning wizard when selecting the option of Group Policy Based provisioning.\n\nYou have not specified the optional parameters DelegatedGpoUser or DelegatedGpoGroup. The delegation parameters can be used to enable IPAM GPO edit privileges for users or groups who do not have domain or enterprise administrator privileges, but need to mark servers as managed or unmanaged in IPAM. {0}
ShoudContinueCaption=Confirm
ShoudContinueConfirmation=Do you want to perform this action?

    #Progress-bar messages
MsgIpamProvisionining=Provisioning IPAM ...
MsgValidatingParams=Validating parameters ...
MsgCreateUG=Creating IPAM universal group {0} ...
MsgAddIpamServerToUG=Adding IPAM Server {0} to universal group {1} ...
MsgCreateGPOs=Creating GPOs ...
MsgImportGPOs=Importing GPOs ...
MsgLinkingGPOs=Linking GPOs to domain {0} ...
MsgAddDelegatedUsers=Adding users to the delegation list ...
MsgAddDelegatedGroups=Adding groups to the delegation list ...
MsgModifyDnsAcls=Updating DNS ACLs ...

'@
