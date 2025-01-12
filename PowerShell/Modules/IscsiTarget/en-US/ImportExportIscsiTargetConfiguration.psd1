# Localized	12/07/2019 05:48 AM (GMT)	303:6.40.20520 	ImportExportIscsiTargetConfiguration.psd1
#/*++
#
#    Copyright (c) Microsoft Corporation.  All rights reserved.
#
#    Abstract:
#
#        String table for the Windows PowerShell script enables persistence of
#        iSCSI Target settings for import and export across computers.
#
#--*/

#
# Data table for the format strings
#
ConvertFrom-StringData @'
###PSLOC - Localizable string
ComputerNotReachable=The specified computer '{0}' is not accessible. Ensure you entered a valid computer name and that the computer is powered on.
TargetNotInstalled=Microsoft iSCSI Target Server does not appear to be installed.
VersionUnsupported=Microsoft iSCSI Target Server version '{0}' is not supported.
SettingsVersionUnsupported=Microsoft iSCSI Target Server version '{0}' settings cannot be imported on this platform.
FileNotFound=The specified file '{0}' does not exist.
ResourceGroupNotFoundTarget=Resource group '{0}' referenced by iSCSI target '{1}' could not be found.
ResourceGroupNotFoundVirtualDisk=Resource group '{0}' referenced by virtual disk '{1}' could not be found.
DevicePathAlreadyExists=The virtual disk with DevicePath '{0}' already exists.
NotDeletedDevicePathAlreadyExists=The virtual disk with DevicePath '{0}' already exists and was not deleted during Force mode.
DevicePathInvalidType=The virtual disk with DevicePath '{0}' has an invalid VHD type of '{1}'.
NewWTDiskMethodInvocationFailure=Invocation of Wt_Disk::NewWTDisk/NewDiffWTDisk failed for DevicePath '{0}'.
NewWTDiskMethodInvocationFailureMsg=Invocation of Wt_Disk::NewWTDisk/NewDiffWTDisk failed for DevicePath '{0}'. Error:\r\n{1}
NewHostMethodInvocationFailure=Invocation of Wt_Host::NewHost failed for iSCSI target name '{0}'.
NewHostMethodInvocationFailureMsg=Invocation of Wt_Host::NewHost failed for iSCSI target name '{0}'. Error: {1}
NewHostPutInvocationFailureMsg=One or more setting properties have failed. Default values are in effect. Exception message: {0}
VirtualDiskDeleteInvocationFailureMsg=Existing virtual disk with DevicePath '{0}' was not deleted during Force mode. Error:\r\n{1}
TargetDeleteInvocationFailureMsg=Existing iSCSI target name '{0}' was not deleted during Force mode. Error:\r\n{1}
TargetNameAlreadyExists=iSCSI target name '{0}' already exists.
NotDeletedTargetNameAlreadyExists=iSCSI target name '{0}' already exists and was not deleted during Force mode.
TargetIQNNameAlreadyExists=iSCSI target IQN name '{0}' already exists.
TargetLunMappingError=The LUN mapping for disk ID '{0}' was not found after import. This may be due to an exported snapshot or an import failure.
TargetChapError=iSCSI Target had CHAP authentication enabled with username '{0}' and requires manual configuration.
TargetReverseChapError=iSCSI Target had reverse CHAP authentication enabled with username '{0}' and requires manual configuration.
TargetIdMethodError=iSCSI Initiator identification method of type '{0}' is not allowed.
SettingsFileExists=The specified settings file '{0}' exists and cannot be overwritten unless Force mode is specified.
SettingsFileFolderNotFound=The folder '{0}' specified for the settings file does not exist.
HeaderStandalone=\r\nExporting iSCSI Target settings in file '{0}'.\r\nThis may take a long time.\r\nConfiguration: Standalone computer '{1}'.
HeaderClusterName=\r\nExporting iSCSI Target settings in file '{0}'.\r\nThis may take a long time.\r\nConfiguration: Failover cluster '{1}': all resources owned by the cluster node owning the 'Cluster name'.
HeaderNodeName=\r\nExporting iSCSI Target settings in file '{0}'.\r\nThis may take a long time.\r\nConfiguration: Failover cluster '{1}': all resources owned by cluster node '{2}'.
HeaderClientAccessPointName=\r\nExporting iSCSI Target settings in file '{0}'.\r\nThis may take a long time.\r\nConfiguration: Failover cluster '{1}': only resources owned by client access point '{2}' in resource group '{3}'.
FooterExportedTargets=\r\nNumber of iSCSI targets saved during export: {0}.\r\niSCSI Target names:
FooterExportedVirtualDisks=\r\nNumber of virtual disks saved during export: {0}.\r\nVirtual Disk DevicePaths:
FooterNotExportedVirtualDisks=\r\nNumber of virtual disks not saved during export: {0}.\r\nVirtual Disk DevicePaths:
ImportHeader=\r\nImporting iSCSI settings from file '{0}'.\r\nThis may take a long time.
FooterImportedTargets=\r\nNumber of iSCSI targets imported: {0}.\r\niSCSI Targets:
FooterNotImportedTargets=\r\nNumber of iSCSI targets not imported: {0}.\r\niSCSI Targets:
FooterImportedVirtualDisks=\r\nNumber of virtual disks imported: {0}.\r\nVirtual Disks:
FooterNotImportedVirtualDisks=\r\nNumber of virtual disks not imported: {0}.\r\nVirtual Disks:
FooterNotImportedResourceGroups=\r\nNumber of resource groups(s) not found after import: {0}.\r\nResource Groups:
TargetError=\x20\x20\x20\x20\x20\x20\x20\x20Error: {0}
TargetNameError=\x20\x20\x20\x20{0}. Error: {1}
VirtualDiskNameError=\x20\x20\x20\x20{0}. Error: {1}\r\n
ErrorHeader=\x20\x20\x20\x20The iSCSI target was created, but with the following errors:
TargetSingleError=\x20\x20\x20\x20\x20\x20\x20\x20{0}
AllTargetServerResourcesMustBeOnline=iSCSI Target Server resource Name '{0}' is not online. Bring the resource online and retry the import or export operation.
NameResolutionFailed=Name resolution for '{0}' has failed, it may not be online or network is down.
###PSLOC - End of localizable string
'@
