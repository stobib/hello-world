# Localized	12/07/2019 05:46 AM (GMT)	303:6.40.20520 	Resources.psd1
#
# Remote Desktop Management Localization File  
#

ConvertFrom-StringData @'
    
    ###PSLOC start localizing
    
    #
    # General
    #
PromptCaption=Do you want to continue?
ResourceTypeUnknown=Unknown
ResourceTypeRemoteApp=RemoteApp programs
ResourceTypeRemoteDesktop=Remote Desktop
WrnWildcardNoMatches=No matches found for {0}.
InvalidAccount=Failed to convert account {0} to a valid SID.
CannotDetermineCollectionExists=Error occured while determining if a collection with the same name exists.
CannotCreateCollectionAlias=Error occured while generating a valid collection alias for use.
InvalidLocalUser=Current user is not a domain user.
NonElavatedMessage=This module requires Administrator privileges. Please restart this session in elevated mode.
WaitingForBatchToComplete=Waiting for the current batch of {0} jobs to complete...
WaitingForJobToComplete=Waiting for the current job to complete...
RestartingTSSDISService=Restarting RD Connection Broker (tssdis) service on server {0}...
RestartingRDMSService=Restarting RD Management (rdms) service on server {0}...
RestartingTSCPUBRPCService=Restarting RD Publishing (tscpubrpc) service on server {0}...
      
    #
    # Deployment check messages
    #
DeploymentDoesNotExist=A Remote Desktop Services deployment does not exist on {0}. This operation can be performed after creating a deployment. For information about creating a deployment, run "Get-Help New-RDVirtualDesktopDeployment" or "Get-Help New-RDSessionDeployment".
SessionDeploymentDoesNotExist=A Remote Desktop Services session-based desktop deployment does not exist on {0}. This operation can be performed only after creating a session-based desktop deployment. For information about how to create a session-based desktop deployment, run "Get-Help New-RDSessionDeployment".
VirtualDeploymentDoesNotExist=A Remote Desktop Services virtual machine-based desktop deployment does not exist on {0}. This operation can be performed only after creating a virtual machine-based desktop deployment. For information about how to create a virtual machine-based desktop deployment, run "Get-Help New-RDVirtualDesktopDeployment"
ValidationInprogress=Validation in progress...
InstallationInprogress=Installation in progress...
ConfigurationInprogress=Configuration in progress...
DeploymentInprogress=Deployment in progress...
VerificationInprogress=Deployment verification in progress...
RemovalInprogress=Configuration removal in progress...
GatewayDoesNotExist=Deployment does not contain an RD Gateway server.
WebAccessDoesNotExist=Deployment does not contain an RD Web Access server.

    #
    # Add/Remove server
    #
WarnRemoveServerMessage=Removing server from the Remote Desktop deployment. Do you want to continue?
SessionDeploymentTypeNameString=session
VDIDeploymentTypeNameString=virtual desktop


    #
    # RDMS Heart Beat
    #
RdmsRoleNotInstalled=The RD Connection Broker role service is not installed on server {0}.
RdmsServicesNotRunning=The RD Connection Broker server’s status is unhealthy. The following services are not running: {0}.
RdmsServerIsNotActive=The RD Connection Broker server’s status is not active for management. The current active server is {0}. Refer to the active RD Connection Broker server for all management operations.
    
    #
    # Certificate
    #
InvalidCertificateRole=The specified Remote Desktop certificate type is not valid. Valid Remote Desktop certificate types are RDGateway, RDWebAccess, RDRedirector, and RDPublishing.
WarnCreatingAndConfiguringCertMessage=Creating and configuring certificate for the role: {0}. Do you want to continue?
WarnConfiguringCertMessage=Configuring certificate for the role: {0}. Do you want to continue?
CertificateLevelUnknown=Unknown
CertificateLevelNotConfigured=NotConfigured
CertificateLevelUntrusted=Untrusted
CertificateLevelTrusted=Trusted
CertificateNotConfigured=Certificate is not configured for the role {0}.

    #
    # General Validations
    #
VerifyingInput=Verifying input...
InvalidFqdn=The specified FQDN {0} is not valid.
InvalidPath=The specified path {0} is not valid or not accessible.
InvalidPfxFile=ImportPath {0} is not a pfx file
InvalidHostname=The specified server name {0} is not valid.
InvalidServerNameFormat=The server name {0} is not a fully qualified domain name (FQDN). Please specify all the server names in FQDN format.
ErrorCode=Error

    #
    #High availability Validations
    #
InvalidSqlFilePath=The specified path {0} for -DatabaseFilePath parameter should contain the the SQL Server database file.
BothConnStringNullErr=Please provide a value for either -DatabaseconnectionString or -DatabaseSecondaryConnectionString parameters and try again.
DoNotSetSecondaryDatabaseConnStr=This a dedicated database server configuration for high availability. Setting the DatabaseSecondaryConnectionString value is not supported. Please update the DatabaseConnectionSring value only.
InvalidDatabaseConnStr=Please specify a valid database connection string for -DatabaseConnectionSring parameter.
DedicatedServerHAConfigDoNotSetSecConnStr=The value provided for -DatabaseConnectionString parameter indicates a dedicated database server configuration. For this type of configuration -DatabaseSecondaryConnectionString is not supported.
SharedServerConnStringDoNotSetDbFilePath=The value provided for -DatabaseConnectionString parameter indicates a shared database server configuration. For this type of configuration -DatabaseFilePath is not supported.
RemoveConnStringOnDedicatedDBServer=The high availability configuration uses a dedicated database server. Removing connection string is not supported for this configuration.
RemovePrimaryConnStringNotSupported=Removing the primary connection string is not supported at this time. Only secondary connection string removal is supported.
RemoveRDSecondaryDBConnectionStringMessageWhatif=The following secondary database connection string will be removed from the deployment: {0}.
RemoveRDSecondaryDBConnectionStringMessage=The following secondary database connection string will be removed from the deployment: {0}. Do you want to continue?
RemoveRDSecondaryDBConnectionStringCaption=Warning: Removing the secondary database connection string from the deployment...
SecondaryConnectionStringNotSet=The secondary connection string is not set for the deployment.
ConnStringsResetFailed=Updating database connection string(s) failed. Check RD Connection Broker event logs for more information.
UpdateDatabaseConnStringsOnAllBrokers=Updating the database connection strings on all brokers in the deployment ...
UpdatingDBConnStringsOnBroker=Updating the database connection strings on RD Connection Broker server {0}.
DoneUpdatingConnStringsOnBroker=Successfully updated the database connection strings on RD Connection Broker server {0}.
FailedUpdatingConnStringOnBroker=Failed to update the database connection strings on RD Connection broker server. Please re-run this cmdlet explicitly on server {0}.
SuccessfullyUpdatedConnStringsAllBrokers=Successfully updated the database connection strings on all RD Connection Broker servers in the deployment. The connection to the database is established and the deployment is functional.
SuccessfullyUpdatedConnStringsOnBroker=Successfully updated the database connection strings on specified RD Connection Broker server {0}.
FailedUpdatingConnStringsOnBrokers=Failed to update the database connection strings on the following RD Connection broker servers: {0}. Please re-run this cmdlet explicitly on each server.
LegacyOSNotSupported=The RD Connection Broker server {0} in the current deployment is not running Windows 2016 or later version. This cmdlet is not supported on legacy Windows OS versions.
DatabaseFilePathMandotoryForLegacyOSBrokers=The -DatabaseFilePath parameter is mandatory for RD Connection Broker server {0} that is not running Windows 2016 or later OS version. Please provide a valid value for this parameter and try again.
RestoreDatabaseConnectionLegacyOSNotSupported=The -RestoreDatabaseConnection parameter is not supported on RD Connection Broker server {0} running legacy Windows OS versions. This feature is supported only on Windows 2016 or later RD Connection Brokers.
SharedDatabaseServerOnLegacyOSNotSupported=The database connection string provided in -DatabaseConnectionString parameter is not supported on RD Connection Broker server {0} running legacy Windows OS version. This feature is supported only on Windows 2016 or later RD Connection Brokers.
SecondaryDBConnStringLegacyOSNotSupported=The -DatabaseSecondaryConnectionString parameter is not supported on RD Connection Broker server {0} running legacy Windows OS version. This parameter is supported only on Windows 2016 or later deployments.
RestoreOnAllBrokersWithoutRestoreDBConnString=The -RestoreDBConnectionOnAllBrokers flag cannot be used if -RestoreDatabaseConnection parameter is not provided.
RestoreDatabaseConnectionOnAllBrokersNotSupported=The -RestoreDBConnectionOnAllBrokers parameter is not supported on RD Connection Broker server {0} running legacy Windows OS versions. This feature is supported only on Windows 2016 or later RD Connection Brokers, and only when -RestoreDatabaseConnection parameter is provided as well.
BrokerIsNotHAConfigured=The RD Connection Broker server {0} in the current deployment is not configured for high availability. The cmdlet is not supported.
BrokerNotMatchingOSVersionErr=The server {0} has to be same OS version as the active RD Connection Broker server {1}: {2}.
NotMatchingDatabaseNameErr=Database name does not match! You must specify same database name in both database connection strings.
SharedDatabaseConnStrFormatError=Specified database connection string uses Windows Authentication, corresponding to dedicated database configuration. Please provide a connection string with database specific authentication for shared database configuration, that contains user name and password.
DedicatedDatabaseConnStrFormatError=Specified database connection string uses database specific authentication, corresponding to shared database configuration. Please provide a connection string with Windows Authentication for dedicated database configuration.

    #
    # User Group general errors/warnings
    #
UnableToMapSid=Unable to convert SID to a valid account name.\nSID: {0}\nError: {1}
InvalidUserGroup=The specified user group {0} could not be mapped to a valid SID.\nError: {1}
InvalidUserGroupNoErr=One of the specified user groups, {0}, could not be mapped to a valid SID.
    
    #
    # Custom RDP Properties
    #
GetCustomRdpPropertiesInvalidCollectionError=Unable to get custom RDP properties for collection {0}; the collection does not exist.
GetCustomRdpPropertiesWmiError=Unable to get custom RDP properties for collection {0}.\nError: {1}
SetCustomRdpPropertiesInvalidCollectionError=Unable to set custom RDP properties for collection {0} on RD Connection Broker server {1}; the collection does not exist on that RD Connection Broker server.
SetCustomRdpPropertiesWmiError=Unable to set custom RDP properties for collection {0} on RD Connection Broker server {1}.\nError: {2}
SetCustomRdpPropertiesForBrokerSuccess=Successfully applied the custom RDP properties to RD Connection Broker server {0}.
SetCustomRdpPropertiesInvalidBrokers=Unable to set custom RDP properties for collection {0} because one or more RD Connection Broker servers are unreachable or misconfigured. Remove these servers from the deployment by using the Remove-RDServer cmdlet, and then try again.\nUnreachable RD Connection Broker servers: {1}\nMisconfigured RD Connection Broker servers: {2}
SetCollectionCustomRdpPropertyFailure=Unable to set custom RDP property on RD Connection Broker server {0}; failed on attempt {1}. Error: {2}
UpdateCustomRdpPropertyFailure=Failed to update the custom RDP settings on RD Connection Broker server {0}, please remove it from the deployment and try to re-add it.
UpdatingCollectionCustomRdpPropertyOnBroker=Updating custom RDP properties for collection {0} on RD Connection Broker server {1}.

    #
    # Licensing
    #
InvalidLicenseServer=The server(s) '{0}' are not valid license server(s).
InvalidLicensingMode=The specified licensing mode is not valid. Valid licensing modes are Per Device and Per User.
LicensingModeNotConfigured=The licensing mode is not configured. Configure the licensing mode by specifying Per Device or Per User.
WarnChangingLicenseSettingsMessage=Changing license settings of the Remote Desktop deployment. Do you want to continue?


    #
    # RDSH
    #
CollectionDoesNotExist=Collection {0} does not exist.
ErrorWmiSessionCollectionServer=Error looking up the session collection server.\nError: {0}
ErrorWmiDrainModeRDSessionHost=Error allowing new connections for RD Session Host server {0}.\nError: {1}
ErrorWmiRemoveRDSessionHost=Error removing RD Session Host server {0} from the collection {1}.\nError: {2}
ErrorWmiAddRDSessionHost=Error adding RD Session Host server {0} to the collection {1}.\nError: {2}
ErrorCreatingRDSHCollection=Failed to create the session collection.
NoServersInRDSHCollection=The session collection {0} does not have any RD Session Host servers.
RDSHCollectionNotFound=No session collection {0} was found.
ErrorDeletingRDSHCollection=Unable to delete the session collection {0}.
RDSHNotFound=The RD Session Host server {0} does not exist in this deployment.
RDSHAlreadyExistInCollection=The RD Session Host server {0} already exists in another collection.
RDSHCollectionAlreadyExist=A session collection with the same name already exists.
RDSHNotFoundInCollection=An RD Session Host server {0} does not exist in this collection.
RemoveRDSessionCollectionCaption=Warning: Removing session collection...
RemoveRDSessionCollectionMessage=The session collection {0} will be removed. Do you want to continue?
RemoveRDSessionCollectionMessageWhatif=The session collection {0} will be removed.
RemoveRDSessionCollectionServerCaption=Warning: Removing the RD Session Host server from the session collection...
RemoveRDSessionCollectionServerMessage=The specified RD Session Host server will be removed from the session collection {0}. Do you want to continue?
RemoveRDSessionCollectionServerMessageWhatif=The specified RD Session Host server will be removed from the session collection {0}.
CollectionNotPersonalPool=The specified desktop collection is not a Session Desktop Collection.
UserAlreadyAssignedDesktop=User {0} already assigned to desktop {1}.
DesktopAlreadyAssigned=Desktop {0} already assigned to user {1}\{2}.
FailedToAddDesktopAssignment=Failed to add the Session Desktop assignment.
FailedToRemoveDesktopAssignment=Failed to remove current desktop assignment.
MissingUserOrDestkop=Must specifiy either user name or desktop name when removing assignment.
NoDesktopAssignmentFound=No assignment found.
InvalidCollectionOrConnectionBroker=Connection Broker {0} or collection {1} is invalid.
NotSupportedSessionDesktopCollection={0} is not supported in Personal Session Collection.
RDSHServerNotThreshold=Server {0} does not support Personal Session Collection.
RemovePersonalDesktopAssignmentMsg1=The personal session desktop assignment for user [{0}] to desktop [{1}] will be removed.
RemovePersonalDesktopAssignmentMsg2=The personal session desktop assignment for user [{0}] will be removed.
RemovePersonalDesktopAssignmentMsg3=The personal session desktop assignment for desktop [{0}] will be removed.
SuccessAddDesktopAssignment=User {0} has been assigned to desktop {1} in collection {2}.
SuccessRemoveDesktopAssignment1=Successfully remove assignment for user {0}
SuccessRemoveDesktopAssignment2=Successfully remove assignment for desktop {0}
    

    #
    # RDVH
    #
VirtualDesktopDoesNotExist=The virtual desktop {0} does not exist in the virtual desktop collection {1}.
VirtualDesktopRemoved=The virtual desktop {0} is removed from the virtual desktop collection {1}.
FailedToRemoveVirtualDesktop=Failed to remove the virtual desktop {0} from the virtual desktop collection {1}.
RDVHCollectionAlreadyExist=A virtual desktop collection with the same name already exists.
DeploymentExportLocationQueryFailed=Getting deployment properties: Failed (Error: {0}). For more information, see the event log.
SetDeploymentExportLocationSuccess=Setting deployment properties: Succeeded. \nExportLocation: {0}
SetDeploymentExportLocationFailed=Setting deployment properties: Failed (Error: {0}). For more information, see the event log.
GrantOUAccessSuccess=Granted access for {1} to organizational unit {0}.
FailedToGrantOUAccess=Failed to grant access for {1} to organizational unit {0}. Verify that the current user is either a domain admin or has proper permissions on the organizational unit.\nError: {2}
TestOUAccessSuccess=Test access for {1} to organizational unit {0} is successful.
FailedToTestOUAccess=Failed to test access for {1} to organizational unit {0}.
InvalidDomainOrOU=The specified domain ({0}) and\\or OU ({1}) is not valid.
UserProfileDiskLocationNotExist=The location {0} does not exist.
UserProfileDiskLocationNotWritable=The currently signed on user cannot create files in {0}.
UserProfileDiskLocationInUse=The specified user profile disk location {0} is already configured for another collection.
LookupTaskWmiError=Error looking up patch information for {0}: {1}
RemoveTaskWmiError=Error removing patch for {0}: {1}
TaskNotFound=Patching task ID {0} not found
CreateTaskWmiError=Error creating patch: {0}
CreateTaskAlreadyExistsError=Patch with given ID already exists: {0}
ModifyTaskWmiError=Error modifying patch: {0}
InvalidLocalStoragePath=The local path {0} is not a local drive-based path. Specify the path in the format DriveLetter:\\Path.
UnreachableVmhostLocalPath=The local path {0} is not accessible to the RD Virtualization Host server {1}.
InvalidSmbSharePath=The specified SMB share path {0} is not valid. Specify the path in the format \\\\ShareHost\\Path.
UnreacahbleSmbSharePath=The specified SMB share path {0} is not reachable. Verify that the path exists.
UnreachablePath=The specified path {0} is not accessible. Verify that the path exists.
VmNamePrefixAlreadyExists=The specified virtual machine name prefix {0} is already in use. Please specify a unique virtual machine name prefix.
CreatingRdvhCollection=Creating a virtual desktop collection: {0}...
AddingVmToCollection=Adding virtual desktop {0} to collection...
AddUnmgdVmFailed=Failed to add virtual desktop {0} to collection. Check that this virtual desktop is configured properly and is not in running state.
CreateRdvhCollectionFailed=Failed to create the virtual desktop collection. Error: {0}
DeleteRdvhCollectionFailed=Failed to delete the virtual desktop collection. Error: {0}
DeleteMgdVmFromCollectionFailed=Failed to delete virtual desktops from the managed virtual desktop collection. Error: {0}
DeleteUnmgdVmFromCollectionFailed=Failed to remove virtual desktop {0} from the virtual desktop collection. Error: {1}
AddVmToRdvhCollectionFailed=Failed to add virtual desktops to the virtual desktop collection. Error: {0}
DeleteVirtualDesktopFailed=Failed to delete virtual desktops from the collection.
RdvmCollectionNotFound=No virtual desktop collection was found.
SpecifiedVmCollNotFound=The virtual desktop collection "{0}" could not be found.
GetVirtDesktopFailed=Failed to get virtual desktops. Error: {0}
RemovingVirtDesktopFromCollection=Removing virtual desktops from the collection...
CollectionDeleted=The virtual desktop collection was successfully deleted.
SpecifyVmAllocation=Cannot add an existing virtual desktop to a managed virtual desktop collection.  Instead, specify how many virtual desktops to add for each server by using the VirtualDesktopAllocation parameter.
SpecifyVmList=Specify a list of already existing virtual machines to be added to the unmanaged virtual desktop collection.
RecreateErrorNotManagedVmCollection=This virtual desktop collection cannot be recreated because it is not a managed collection.
RecreateErrorNotSharedVmCollection=This virtual desktop collection cannot be recreated because it is not a pooled virtual desktop collection.
VmCollectionNotFound=The virtual desktop collection for {0} could not be found. Error: {1}
VmCollectionPropNotFound=The virtual desktop collection properties could not be found.
VmCollectionProvPropNotFound=Provisioning properties for the collection could not be found.
ErrorExportFailed=Failed to export the virtual desktop template.
FailedToSaveVmCollProp=Failed to save the collection properties.
FailedToScheduleVmCollRecreate=Failed to schedule a Recreate operation for the managed virtual desktop collection.
ScheduledVmCollRecreate=Successfully scheduled a Recreate operation for the managed virtual desktop collection. To check the job status, use "Get-RDVirtualDesktopCollectionJobStatus."
FailedToGetStatusNotManaged=The job status of a virtual desktop collection cannot be retrieved because it is not a managed collection.
FailedToGetCollectionState=The job status of a virtual desktop collection cannot be retrieved. Error: {0}
FailedToGetStatusNotShared=The updated status of a virtual desktop collection cannot be retrieved because it is not a pooled virtual desktop collection.
FailedToGetRecreateProps=Failed to retrieve pending Recreate job properties.
FailedToGetJobReport=Failed to retrieve job report.
PDAssignErrorNotPDPool=The specified virtual desktop collection is not a personal virtual desktop collection.
ErrorNotPDPool=The specified virtual desktop {0} is not in a personal virtual desktop collection.
InvalidUserName=Specify a correct user name in the format domain\\user.
FailedToFindVirtualDesktop=Failed to find a virtual desktop with the specified name {0}. Specify a valid virtual desktop name.
FailedToFindVirtualDesktopWmi=Failed to find a virtual desktop with the specified name {0}. Specify a valid virtual desktop name.  Error: {1}
VirtDesktopNotAMemeberOfSpecifiedPool=The virtual desktop {0} is not a member of the specified virtual desktop collection.
UserAlreadyAssigned=The virtual desktop is already assigned to user {0}\\{1}.
FailedToRemovePDAssignment=Failed to clear current desktop assignment.
FailedToSetPDAssignment=Failed to set the personal virtual desktop assignment.
SetPDAssignSuccess=User {0} has been assigned the personal virtual desktop {1} in collection {2}.
PDAssignErrorNoCurrentAssignment=User is not assigned any personal virtual desktop in this collection.
RemovePDAssignSuccess=Successfully removed personal virtual desktop assignment.
FailedToGetProvXml=Failed to generate provisioning XML.
ErrorEmptyVmList=Specify at least one virtual machine for the unmanaged virtual desktop pool.
VirtDesktopAlreadyAMember=The virtual desktop {0} is already a member of collection {1}.
CentralStorageCanNotBeEmpty=The CentralStoragePath parameter cannot be empty for this storage type.
InvalidSanStoragePath=Specify the central SAN storage path in the format DriveLetter:\\ClusterStorage\\VolumeX\\Folder.
InvalidUnattendFilePath=The unattend answer file path is not valid; please specify the full path to the unattend answer file.
FailedToLoadUnattendFile=Failed to load the specified unattend answer xml file; verify that it is in the correct format.
InvalidUnattendNoCompName=Specify an unattend answer file without ComputerName.
InvalidUnattendNoDomainJoin=Specify an unattend answer file without domain join information.
InvalidRdvhFqdn=Server name {0} is not a fully qualified domain name (FQDN). Specify all server names in FQDN format in the -VirtualDesktopAllocation parameter.
InvalidRdvhRoleNotFound=Server name {0} could not be found on the RD Virtualization Host servers in the deployment. Specify the correct server name in the -VirtualDesktopAllocation parameter.
InvalidRdvhRoleNotFoundGeneric=Server name {0} could not be found on the RD Virtualization Host servers in the deployment.
FailedToFindMasterVm=A virtual desktop template named {0} could not be found.
FailedToGetMasterVmInfo=Failed to validate the virtual desktop template. Error: {0}. \nVerify that the virtual desktop template is sysprep generalized, in stopped state, and connected to the network, and that it has at least 1 GB of RAM.
ErrorMasterVmNotGeneralized=The specified virtual desktop template is not sysprep generalized.
ExportRootNotFound=The virtual desktop export path could not be found in deployment properties.
ExportRootInvalid=The virtual desktop template export path {0} is either invalid or unreachable. Please make sure that the path is reachable or specify a different virtual desktop template export path using Set-RDVirtualDesktopTemplateExportPath.
FailedToCreateFolder=Failed to create folder: {0} \nError: {1}
FailedToGetComputerObject=Failed to retrieve computer object from the server: {0}
FailedToGetComputerObjectWmi=Failed to retrieve computer object from the server: {0} \nError: {1}
FailedToSetFolderPermission=Failed to set permissions on folder: {0} \nError: {1}
ErrFailedToQueryRunningJob=Failed to query the running jobs for the virtual desktop collection.
ErrProvJobAlreadyScheduled=The operation cannot be performed on the virtual desktop collection because a provisioning job is already scheduled.
ErrVmCollectionRequiresUserGroups=You specified an empty list of user groups to which to assign the virtual desktop collection. The collection must be assigned to at least one user group.
FailedToCancelCollJob=The collection job could not be stopped. Error: {0}
ErrCollectionJobCancelInvalidState=The Stop operation is not possible in current collection state: {0}
ErrStartTimeGTLogoffTime=Verify that the StartTime is earlier than the ForceLogoffTime.
MovingVirtualDesktop=Moving virtual desktop {0} from server {1} to {2}. This may take a few minutes...
MovingVirtualDesktopSucceeded=Moving the virtual desktop succeeded.
MovingVirtualDesktopFailed=Moving the virtual desktop failed. Refer to the event logs on the source server.
EnsuringGoldCacheExists=Verifying that a copy of the virtual desktop template exists on the destination server {0}...
MoveOperationRequiresCredentials=The virtual desktop move operation on the remote server requires credentials.
RemoveVmCollMsg=The virtual desktop collection {0} will be removed.
RemoveVmsFromCollMsg=The specified virtual desktops will be removed from the collection.
RemovePatch=The specified patching task will be removed.
RemovePatches=All patching tasks will be removed.
NoAssignedPDFoundInCollection=No personal virtual desktop has been assigned to any user in the collection that you specified.
SpecifiedPDNotAssigned=The specified virtual desktop has not been assigned to any user.
WrnAutoAssignNotApplicable=Auto-assignment of a personal virtual desktop is not applicable for this collection type.
WrnGrantAdminNotApplicable=Administrative privileges cannot be enabled for this collection type.
RemovePDAssignmentMsg=The personal virtual desktop assignment for user [{0}] to virtual desktop [{1}] will be removed.
ErrReadingConcurrencyFactor=Failed to read a concurrency factor from RD Virtualization Host server: {0}\nError: {1}
ErrSettingConcurrencyFactor=Failed to set a concurrency factor on RD Virtualization Host server: {0}\nError: {1}
ErrInvalidConcurrencyType=Concurrency value type "{0}" specified for {1} is unexpected. Expected: "System.Int32"
ErrInvalidConcurrencyRange=Concurrency value {0} specified for {1} is out of range. Valid range: [1..100]
SettingConcurrencyFactorSuccess=Succsessfully set concurrency factor on RD Virtualization Host server: {0}
DeletingConcurrencyFactorSuccess=Succsessfully deleted concurrency factor on RD Virtualization Host server: {0}
SettingConcurrencyFactor=Setting concurrency factor on RD Virtualization Host server: {0}...
UnsupportedVirtualDesktopTemplateOption=Parameter "{0}" is supported only for managed personal virtual desktop collections.
ErrSettingReuseVmAdAccount=Failed to set the Reuse Virtual Desktop property on RD Connection Broker server: {0} \nError: {1}
ErrReadingReuseVmAdAccount=Failed to read the Reuse Virtual Desktop property from RD Connection Broker server: {0} \nError: {1}
WrnOUAccessNotGranted=Access to organizational unit {0} is not granted.
ShouldContinueOUAccessNotGranted=Access to organizational unit {0} is not granted. Do you want to ignore and continue?

    #
    # UserVHD Share ACL
    #
GetFolderPathWmiError=Error retrieving the folder path: {0}
GetComputerWmiError=Error retrieving the computer name for {0}: {1}
GetComputerError=Error retrieving the computer name for {0}
FolderPathStatusInvalid=Folder path status is not valid: {0}
FolderPathTypeInvalid=Folder path type is not valid: {0}
FolderPathNotShareFormat=Folder path type is not in a UNC format.
ModifyACLFailed=Warning: ACL on folder {0} could not be modified.
FolderPathInUse=The specified user profile disk location: {0} is already in use.
SidEveryone=S-1-1-0
EveryoneHasAccess=The specified user profile disk location {0} allows access permissions (Read or Full Control) to Everyone. This is not required for proper functioning and may impose a security risk.
    
ErrReadingIdleVmCount=Failed to read Virtual Desktop Idle Count from RD Virtualization Host server: {0}\nError: {1}
ErrSettingIdleVmCount=Failed to set Virtual Desktop Idle Count on RD Virtualization Host server: {0}\nError: {1}
ErrInvalidIdleVmCountType=Virtual Desktop Idle Count type "{0}" specified for {1} is unexpected. Expected: "System.Int32"
IdleVmCountSetSuccess=Successfully set Virtual Desktop Idle Count on RD Virtualization Host server: {0}
IdleVmCountDeleteSuccess=Successfully deleted Virtual Desktop Idle Count on RD Virtualization Host server: {0}
UpdateVmCollMsg=All the virtual desktops in the virtual desktop collection {0} will be updated with the specified virtual desktop template.
FailedToGetVirtualDesktop=Failed to retrieve the virtual desktop {0}.\nError: {1}
DefaultPatchPluginName=Default Patch plug-in
ErrSettingHostConfiguration=Failed to set "{0}" on RD Virtualization Host server: {1}\nError: {2}
InvalidHostConfigurationSetting="{0}" is supported only for managed virtual desktop collections with rollback enabled.
StopProvJobMsg=The provisioning job for this collection will be cancelled.
ModifyRollbackEnableFailed=Failed to modify the Rollback property of the collection.\nError: {0}

    #
    # Workspace
    #
GetListOfConnectionBrokersFailed=Failed to obtain list of RD Connection Broker servers.
GetListOfRDWAServersFailed=Failed to obtain list of RD Web Access servers.
NoWorkspacesInRDMgmt=No workspaces found on RD Connection Broker server {0}.
SetRemoteWebConfigFileFailed=Failed to update web.config on {0}.
SetWorkspaceNameFailed=Failed to update workspace name.
GetWorkspacesWmiError=Failed to get workspace objects on RD Connection Broker server {0}.\nError: {1}
WriteWorkspaceWmiError=Failed to update the workspace on RD Connection Broker server {0}.\nError: {1}
UpdateBrokersInProgress=Updating RD Connection Broker server {0} of {1}...
UpdateRDWAsInProgres=Updating RD Web Access server {0} of {1}...
SetWorkspaceBadServers=Unable to set the workspace name; one or more of the RD Connection Broker servers or RD Web Access servers in the deployment is unavailable or misconfigured. Remove these servers from the deployment by using Remove-RDServer, and then try again.\nUnavailable RD Connection Broker servers: {0}\nMisconfigured RD Connection Broker servers: {1}\nUnavailable RD Web Access servers: {2}\nMisconfigured RD Web Access servers: {3}
SetWorkspaceOfflineRdwa=Could not determine the existence of the RD Web Access web.config file on server {0}.\nError: {1}
SetWorkspaceMissingWebConfig=Could not find the RD Web Access web.config file on server {0}.

    #
    # PublishedDesktop
    #
NoPublishedDesktopsAvailable=No published virtual or physical desktops found.
GetPublishedDesktopsWmiError=Error retrieving published virtual or physical desktops: {0}
WarnUserRemovingAllPublishedAppsWhatif=Allowing virtual or physical desktops to show in RD Web Access will remove all your published RemoteApp programs.
WarnUserRemovingAllPublishedApps=Allowing virtual or physical desktops to show in RD Web Access will remove all your published RemoteApp programs. Do you wish to continue?
WarnUserTitleRemovingPubApps=Warning: Removing published RemoteApp programs...
RemovingPubAppsInProgress=Removing published RemoteApp program {0} of {1}...
UpdatingDesktopInProgress=Updating the virtual or physical desktop connection...

    #
    # Firewall enable/disable
    #
FirewallDisableFailedError=Failed to disable the firewall on virtual desktop {0}.
FirewallDisableFailedWmiError=Failed to disable the firewall on virtual desktop {0} due to a WMI error. \nError: {1}
FirewallDisableFailedErrorCode=Failed to disable the firewall on virtual desktop {0}. \nError: {1}
FirewallEnableFailedError=Failed to re-enable the firewall on virtual desktop {0}.
FirewallEnableFailedWmiError=Failed to re-enable the firewall on virtual desktop {0} due to a WMI error. \nError: {1}
FirewallEnableFailedErrorCode=Failed to re-enable the firewall on virtual desktop {0}. \nError: {1}
    
    #
    # Start Menu Applications
    #
NoVMsFoundInCollectionError=Could not find any virtual desktops in collection {0}.
VMNotFoundInCollectionError=Could not find any virtual desktops named {0} in collection {1}.
NoSessionHostsFoundInCollectionError=Could not find any RD Session Host servers in collection {0}.
NoRunningSessionHostsFoundInCollectionError=Could not find any RD Session Host servers in collection {0} that are accepting connections.
StartMenuPreparingVmInProgress=Preparing virtual machine '{0}' to allow retrieving available applications...
RetreivingAppsInProgress=Retrieving available applications...
    
    #
    # GateWay Deployment Property Errors
    #
GetGatewayUsageFailed=Failed to obtain RD Gateway Usage property. \nError: {0}
GetGatewayNameFailed=Failed to obtain RD Gateway Name property. \nError: {0}
GetGatewayAuthModeFailed=Failed to obtain RD Gateway Authentication Mode property. \nError: {0}
GetGatewayUseCachedCredsFailed=Failed to obtain RD Gateway Use Cached Credentials property. \nError: {0}
GetGatewayPropertiesWmiError=Failed to retrieve RD Gateway properties: {0}
WarnChangingGatewaySettingsMessage=Changing RD Gateway settings of the Remote Desktop deployment. Do you want to continue?
ErrorCustomGatewayProperties=Your gateway mode is "{0}", but you attempted to update one or more of the following RD Gateway properties which can only be modified when the gateway mode is "Custom": {1}.
ErrorMissingCustomGatewayProperties=The following RD Gateway properties are required when gateway mode is "Custom": {0}.
    
    #
    # RemoteApp Publishing
    #
LookupCollectionWmiError=Error looking up collection info: {0}
GetRemoteAppsWmiError=Error retrieving the RemoteApp programs: {0}
GetFtasWmiError=Error retrieving file type associations: {0}
SetFtaDoesNotExistError=The specified file type association cannot be modified because it does not exist.\nCollection name: {0}\nApp alias: {1}\nFile extension name: {2}
InvalidAppObjectError=The object for RemoteApp program {0} is corrupted; it refers to a non-existent collection: {1}.
InvalidFtaObjectError=The object for file type association {0} is corrupted; it refers to a non-existent collection: {1}.
TSGetIconResolveEnvVarError=Error resolving environment variables in the icon path:\nComputer name: {0}\nIcon path: {1}\nError: {2}
TSGetIconError=Error retrieving icon contents:\nComputer name: {0}\nIcon path: {1}\nIcon index: {2}\nError: {3}
TSGetIconNoIconFound=Could not find the specified icon:\nComputer name: {0}\nIcon path: {1}\nIcon index: {2}
InvalidIconPath=The specified icon path {0} is not valid. Specify a valid icon path.
RemoteAppValidIconRequiredError=RemoteApp programs must have a valid icon, but the icon you specified does not appear to be valid.
RemoteAppInvalidAlias=The specified AppAlias, {0}, is not valid. Specify an alias that is at least 1 character and does not contain any of the following characters: {1}
RemoteAppInvalidDisplayName=The specified DisplayName, {0}, is not valid. Specify a name that is fewer than {1} characters and does not contain any of the following characters: {2}
RemoteAppInvalidAppPath=The specified AppPath, {0}, is not valid. Specify a valid file path.
RemoteAppInvalidFolder=The specified Folder, {0}, is not valid. Specify a folder name that is fewer than {1} characters, is not '.' or '..', and does not contain any of the following characters: {2}
RemoteAppInvalidFolderLowChars=The specified Folder, {0}, is not valid. Specify a folder name that does not contain special characters.
RemoteAppDoesNotExist=The specified RemoteApp program does not exist.\nCollectionName: {0}\nAppAlias: {1}
NewRemoteAppDoesNotExist=The newly created RemoteApp program does not exist.\nCollectionName: {0}\nAppAlias: {1}
ConfirmRemoveRemoteAppMsg=RemoteApp program '{0}' in collection '{1}'
RemoteAppAlreadyExistsError=A RemoteApp program with alias '{0}' already exists in collection '{1}'; specify a different alias or collection, and then try again.
CouldNotFindRemoteAppByName=Could not find any RemoteApp programs that matched DisplayName '{0}'.
NewAppPreparingVmInProgress=Preparing virtual machine '{0}' to allow publishing RemoteApp programs...
GetAppIconInProgress=Generating the icon for the RemoteApp program...
PublishingAppsInProgress=Publishing the RemoteApp program...
UpdatingAppInProgress=Updating the RemoteApp program...
GetFtaIconInProgress=Generating the icon for the file type association...
UpdateFtaInProgress=Updating the file type association...
ErrorRdshOffline=Cannot reach RD Session Host server {0}.\nError: {1}
ErrorRdshMisconfigured=Could not find any instances of WMI class {0} on RD Session Host server {1}.
ErrorInvalidSessionHostsCollection=Unable to modify publishing settings for collection {0} because one or more of the collection's RD Session Host servers are unreachable or misconfigured. Remove these RD Session Host servers from the collection by using the Remove-RDSessionHost cmdlet, and then try again.\nUnreachable RD Session Host servers: {1}\nMisconfigured RD Session Host servers: {2}
ErrorInvalidSessionHosts=Unable to modify settings, because one or more RD Session Host servers are unreachable or misconfigured. Remove these RD Session Host servers by using the Remove-RDSessionHost cmdlet, and then try again.\nUnreachable RD Session Host servers: {0}\nMisconfigured RD Session Host servers: {1}
RDSHCollectionNotFoundTryVdi=No session collection {0} was found. For virtual desktop collections, please ensure that the -VirtualDesktopName parameter is specified.

    #
    # Sessions
    #
GetSdSessionWmiError=Failed to get user sessions from RD Connection Broker server {0}.
SessionAccessDenied=Access was denied.
SessionNotExist=Specified session does not exist.
SessionVMNotRunning=The virtual desktop that is hosting the session is not running.
HostDoesNotExist=Specified server is not reachable or does not exist.
BrokerConnectError=Error connecting to RD Connection Broker server {0}.
MessageSendSuccess=Message sent.
MessageSendFailure=Failed to send message.
SessionLogoffSuccess=User session signed out.
SessionLogoffFailure=Failed to sign out from user session.
SessionDisconnectSuccess=User session disconnected.
SessionDisconnectFailure=Failed to disconnect user session.
NoUserSessionFound=No user sessions were found matching the specified criteria.
LogoffUsrSessionMsg=The user session {0} will be logged off from the server {1}.
DisconUsrSessionMsg=The user session {0} will be disconnected from the server {1}.

    #
    # Virtual Desktop Collection   
    #
ErrorRetrievingCollection=Virtual desktop collection {0} was not found.
ErrorWritingVDColProps=Error writing out properties for virtual desktop collection: {0}.
FailedToSetDeviceRedirectionOptions=Failed to set device redirection options: {0}
FailedToSetRedirectClientPrinter=Failed to set redirect client printer: {0}
FailedToSetMaxMonitors=Failed to set the number of maximum monitors: {0}
ExceptionDisablingUserVHD=Exception encountered while trying to disable the user profile disk: {0}
FailedToGetDeviceRedirectionOptions=Failed to get device redirection options: {0}
FailedToGetMaxMonitors=Failed to get the number of maximum monitors: {0}
FailedToGetRedirectClientPrinter=Failed to get redirect client printer: {0}
FailedToRetrieveClientProperties=Failed to retrieve client properties: {0}
NoVirtualDesktopsFound=No virtual desktops were found that matched the specified criteria.
'@
