# Localized	12/07/2019 05:48 AM (GMT)	303:6.40.20520 	Configure-ServerManagerStandardUserRemoting.psd1


ConvertFrom-StringData @'
###PSLOC
ErrorOnUsernameMessage=The specified object does not exist or is not a user: {0}
ConfirmEnableMessage=Add users to groups {0}?\nThis action also gives users "Enable Account" and "Read Security" access rights to the root\\cimv2 WMI namespace, and grants users access rights to the following in Service Control Manager: SC_MANAGER_CONNECT, SC_MANAGER_ENUMERATE_SERVICE, SC_MANAGER_QUERY_LOCK_STATUS, and STANDARD_RIGHTS_READ
ConfirmDisableMessage=Remove users from groups {0}?\nThis action also removes all access rights for these users to the root\\cimv2 WMI namespace, and removes all access rights for these users from Service Control Manager.
ShouldProcessForUserMessage=Enable remote management for standard user {0}
ShouldProcessForUserMessageDisable=Disable remote management for standard user {0}
###PSLOC

'@
