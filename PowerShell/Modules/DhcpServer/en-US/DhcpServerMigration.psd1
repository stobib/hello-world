# Localized	10/08/2016 04:53 AM (GMT)	303:4.80.0411 	DhcpServerMigration.psd1
# Localized	04/17/2011 10:20 PM (GMT)	303:4.80.0411 	DhcpServerMigration.psd1
# Only add new (name,value) pairs to the end of this table
# Do not remove, insert or re-arrange entries
   ConvertFrom-StringData @'
       ###PSLOC start localizing
       #
       # helpID = VersionTooLow
       #
        
    #Error Msg
ExportedFileExists=File {0} already exists.
InvalidIPv4ScopeAddress=ScopeID {0} is not a valid IPv4 address.
InvalidIPv6ScopeAddress=Prefix {0} is not a valid IPv6 address.
NothingToExport=Nothing is exported. File {0} is not created.
ImportedVersionMismatch=The functionality is not available on this server version. Version of DHCP server is {0}.{1}.
ImportedFileVersionMismatch=The DHCP server version {0}.{1} is not compatible with the file version {2}.{3}.
ImportFileDoesNotExist=File {0} does not exists.
ErrInputScopeNotInImportFile=Input scope {0} is not present in the specified file {1}.
GenericErrorMsg={0} : {1}({2})
ErrXmlValidationFailed=XML schema validation for {0} failed. Please ensure that import file {0} is valid as per the XML schema in {1}. {2}
ErrServerConfigGivenWithScopePrefix=ScopeId/Prefix cannot be specified when ServerConfigOnly is specified.
ErrServerConfigGivenWithLeases=Leases cannot be specified when ServerConfigOnly is specified.
ErrServerConfigGivenWithScopeOverwrite=ScopeOverwrite cannot be specified when ServerConfigOnly is specified.
ErrFilePathInvalid=Invalid path {0}. {1}

    #ShouldProcess/ShouldContinue Messages
Msg_Export_DhcpServer_1=The configuration (and leases) for the scope(s) {0} on server {1} will be exported to the file {2}.
Msg_Export_DhcpServer_2=The configuration (and leases) on server {0} will be exported to the file {1}.
Msg_Export_DhcpServer_3=The configuration for the scope(s) {0} on server {1} will be exported to the file {2}.
Msg_Export_DhcpServer_4=The configuration on server {0} will be exported to the file {1}.
Msg_Import_DhcpServer_1=The configuration (and leases) for following scopes will be imported from the file {0} to server {1}: {2}.{3}
Msg_Import_DhcpServer_2=The configuration (and leases) from the file {0} will be imported to server {1}.{2}
Msg_Import_DhcpServer_3=The configuration for following scopes will be imported from the file {0} to server {1}: {2}.{3}
Msg_Import_DhcpServer_4=The configuration from the file {0} will be imported to server {1}. {2}
ShoudContinueCaption=Confirm
ShoudContinueConfirmation=Do you want to perform this action?

    #Export Verbose Msg
Ver_Export_Start=Exporting configuration from server {0} to file {1}.
Ver_Export_Classes=Exporting classes from server...
Ver_Export_OptDef=Exporting option definitions from server...
Ver_Export_Server_OptValue=Exporting server wide option values...
Ver_Export_Server_Pol_OptValue=Exporting server wide option values from policy {0}...
Ver_Export_Scope_OptValue=Exporting option values from scope {0}...
Ver_Export_Rsvation_OptValue=Exporting option values from reservation {0}...
Ver_Export_Scope_Pol_OptValue=Exporting option values from policy {0} of scope {1}...
Ver_Export_Server_Policy=Exporting server wide policies...
Ver_Export_Server_Filter=Exporting Link Layer Filters...
Ver_Export_Scope=Exporting scope {0} from server {1}...
Ver_Export_Scope_ExRanges=Exporting exclusion ranges from scope {0}...
Ver_Export_Scope_Policy=Exporting policies from scope {0}...
Ver_Export_Scope_Rsvation=Exporting reservations from scope {0}. This operation may take some time.
Ver_Export_Scope_ExRange=Exporting exclusion ranges from scope {0}...
Ver_Export_Scope_Lease=Exporting leases from scope {0}. This operation may take some time.
Ver_Export_End=Export operation on server {0} completed.

    #Import Verbose Msg
Ver_Import_Started=Importing configuration on server {0} from file {1}.
Ver_Import_Backup=Dhcp Server database has been backed up at {0} on {1}.
Ver_Import_Classes=Importing classes on server...
Ver_Import_OptDef=Importing option definitions on server...
Ver_Import_Server_OptVal=Importing server wide option values...
Ver_Import_Server_Pol_OptVal=Importing server wide option values for policy {0}...
Ver_Import_Scope_OptVal=Importing option values for scope {0}...
Ver_Import_Rsvation_OptVal=Importing option values for reservation {0}...
Ver_Import_Scope__PolOptVal=Importing option values for policy {0} to scope {1}...
Ver_Import_Server_OptVal_Del=Deleting server wide option values...
Ver_Import_Scope_OptVal_Del=Deleting existing option values from scope {0}...
Ver_Import_Scope_ExRange=Importing exclusion ranges to scope {0}...
Ver_Import_Scope_ExRange_Del=Deleting existing exclusion ranges in scope {0}...
Ver_Import_Rsvation_OptVal_Del=Deleting existing option values on reservation {0}...
Ver_Import_Server_Policy=Importing server wide policies...
Ver_Import_Scope_Policy=Importing policies to scope {0}...
Ver_Import_Server_Policy_Del=Deleting server wide policies...
Ver_Import_Scope_Policy_Del=Deleting existing policies in scope {0}...
Ver_Import_Server_Filter_Del=Deleting link layer filters...
Ver_Import_Server_Filter=Importing link layer filters...
Ver_Import_Scope=Importing scope {0} on server {1}...
Ver_Import_Scope_Rsvation=Importing reservations to scope {0}. This operation may take some time.
Ver_Import_Scope_Leases=Importing leases to scope {0}. This operation may take some time.
Ver_Import_Scope_Del=Deleting existing scope {0} on server {1}...
Ver_Import_Scope_Rsvation_Del=Deleting existing reservations in scope {0}...
Ver_Import_End=Import operation on server {0} completed.
Ver_Import_Scope_Exists_1=Scope {0} exists on server {1}. This scope will be overwritten with data in the import file.
War_Import_Scope_Exists_2=Scope {0} exists on server {1}. This scope will not be imported.
Ver_Import_Scope_Exists_3=Scope {0} exists on server {1}. This scope will be deleted and imported from the data in the import file.

Ver_Import_ClassAlreadyExist=Class '{0}' of type {1} already exists on server {2} and will not be changed.
Ver_Import_OptDefAlreadyExist=Option definition {0} already exists on server {1} and will not be changed.

War_RestoreDhcpDatabase=To restore the DHCP server configuration to the previous state, restore the DHCP database from {0}.
War_ImportOptValueServerLevelWithoutValue=Server wide option value {0} was not imported on server {1} because it did not have any value associated with it.
War_ImportOptValueServerPolicyLevelWithoutValue=Server wide option value {0} for policy {1} was not imported on server {2} because it did not have any value associated with it.
War_ImportOptValueScopeLevelWithoutValue=Option value {0} for scope {1} was not imported on server {2} because it did not have any value associated with it.
War_ImportOptValueReservationLevelWithoutValue=Option value {0} for reservation {1} was not imported on server {2} because it did not have any value associated with it.
War_ImportOptValueScopePolicyLevelWithoutValue=Option value {0} for policy {1} of scope {2} was not imported on server {3} because it did not have any value associated with it.

'@
