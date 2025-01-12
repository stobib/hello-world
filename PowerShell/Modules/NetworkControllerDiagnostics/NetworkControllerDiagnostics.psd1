#
# Module manifest for diagnostics for network controller
#
# Copyright="© Microsoft Corporation. All rights reserved."
#

@{

# ID used to uniquely identify this module
GUID = 'd6df305a-d5c8-4ad6-9161-5ee6ba44b501'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '© Microsoft Corporation. All rights reserved.'

# Version number of this module.
ModuleVersion = '1.0.0.0'

# Version number of this module.
PowerShellVersion = '3.0'

# Underlying powershell scripts
NestedModules = @(
        'Debug-NetworkController.psm1',
        'Debug-NetworkControllerConfigurationState.psm1',
        'Debug-ServiceFabricNodeStatus.psm1',
        'Get-NetworkControllerReplica.psm1'
)

# Cmdlets to export from this module
CmdletsToExport = '*'

# Functions to export from this module
FunctionsToExport = @(
        'Get-NetworkControllerDeploymentInfo',
        'Get-NetworkControllerManagedDevices',
        'Debug-NetworkController',
        'Debug-NetworkControllerConfigurationState',
        'Debug-ServiceFabricNodeStatus',
        'Get-NetworkControllerReplica'
)

# Variables to export from this module
VariablesToExport = ''

# Aliases to export from this module
AliasesToExport = ''

# HelpInfo URI of this module
HelpInfoURI = 'http://go.microsoft.com/fwlink/?LinkId=799475'
}

