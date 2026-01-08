# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.1.0] - 2025-12-05
- Fixed `Invoke-IntuneBackupPolicySet` to handle API limitation where $expand is not supported on collection queries. Now queries each policy set individually with expand.
- Fixed `Invoke-IntuneRestoreDeviceEnrollmentConfiguration` to use Beta API endpoint (required by Microsoft Graph).
- Fixed `Invoke-IntuneRestoreDeviceEnrollmentConfiguration` priority conflict handling with automatic priority increment.
- Fixed `Invoke-IntuneRestoreDeviceEnrollmentConfiguration` to correctly include `deviceEnrollmentConfigurationType` property.
- Fixed `Invoke-IntuneRestoreDeviceEnrollmentConfiguration` to add [int] casting for priority values to prevent type conversion errors.
- Fixed `Invoke-IntuneRestoreNotificationTemplate` to use two-step process: create template first, then add localized messages separately.
- Fixed `Invoke-IntuneRestoreNotificationTemplate` to remove `defaultLocale` and `description` properties during creation (causes BadRequest errors).
- Fixed `Invoke-IntuneRestoreConditionalAccessPolicy` and `Invoke-IntuneRestoreNamedLocation` to use Beta API and require Policy.ReadWrite.ConditionalAccess scope.
- Fixed `Invoke-IntuneBackupConfigurationPolicyAssignment` to use pagination so more than 25 assignments are returned
- Fixed scope validation in `Start-IntuneBackup` and `Start-IntuneRestoreConfig` to include all 8 required scopes including Policy.ReadWrite.ConditionalAccess.
- Added comprehensive verbose logging throughout restore functions for debugging.
- Updated `Start-IntuneBackup` scope validation from 4 scopes to 8 scopes (added DeviceManagementScripts, Policy.Read.All, Policy.ReadWrite.ConditionalAccess).
- Updated `Start-IntuneRestoreConfig` scope validation to match backup requirements.
- Improved error handling to continue restore operations even when individual policy types fail.

## [5.0.0] - 2025-12-01
- Added function `Invoke-IntuneBackupAssignmentFilter`.
- Added function `Invoke-IntuneRestoreAssignmentFilter`.
- Added function `Invoke-IntuneBackupRoleScopeTag`.
- Added function `Invoke-IntuneRestoreRoleScopeTag`.
- Added function `Invoke-IntuneBackupDeviceEnrollmentConfiguration`.
- Added function `Invoke-IntuneRestoreDeviceEnrollmentConfiguration`.
- Added function `Invoke-IntuneBackupNamedLocation`.
- Added function `Invoke-IntuneRestoreNamedLocation`.
- Added function `Invoke-IntuneBackupConditionalAccessPolicy`.
- Added function `Invoke-IntuneRestoreConditionalAccessPolicy`.
- Added function `Invoke-IntuneBackupWindowsFeatureUpdateProfile`.
- Added function `Invoke-IntuneRestoreWindowsFeatureUpdateProfile`.
- Added function `Invoke-IntuneBackupWindowsQualityUpdateProfile`.
- Added function `Invoke-IntuneRestoreWindowsQualityUpdateProfile`.
- Added function `Invoke-IntuneBackupWindowsDriverUpdateProfile`.
- Added function `Invoke-IntuneRestoreWindowsDriverUpdateProfile`.
- Added function `Invoke-IntuneBackupMobileAppConfiguration`.
- Added function `Invoke-IntuneRestoreMobileAppConfiguration`.
- Added function `Invoke-IntuneBackupTargetedManagedAppConfiguration`.
- Added function `Invoke-IntuneRestoreTargetedManagedAppConfiguration`.
- Added function `Invoke-IntuneBackupNotificationTemplate`.
- Added function `Invoke-IntuneRestoreNotificationTemplate`.
- Added function `Invoke-IntuneBackupIntuneBrandingProfile`.
- Added function `Invoke-IntuneRestoreIntuneBrandingProfile`.
- Added function `Invoke-IntuneBackupTermsAndConditions`.
- Added function `Invoke-IntuneRestoreTermsAndConditions`.
- Added function `Invoke-IntuneBackupRoleDefinition`.
- Added function `Invoke-IntuneRestoreRoleDefinition`.
- Added function `Invoke-IntuneBackupPolicySet`.
- Added function `Invoke-IntuneRestorePolicySet`.
- Added function `Invoke-IntuneBackupDeviceManagementIntentAssignment`.
- Embedded all new backup functions in the `Start-IntuneBackup` cmdlet.
- Embedded all new restore functions in the `Start-IntuneRestoreConfig` cmdlet.
- Updated `Start-IntuneBackup` and `Start-IntuneRestoreConfig` with try-catch error handling for all function calls.
- Updated required permissions to include `DeviceManagementRBAC.ReadWrite.All` and `Policy.Read.All`.
- Fixed issue where Graph API terminating errors would stop the entire backup/restore process.
- Backup and restore operations now continue even if individual policy types fail due to permissions or API errors.
## [4.0.1] - 2025-12-16
- Updated Microsoft.Graph Required Scopes. Special thanks to @Felix4567 #93
- Fixed an issue where the Microsoft Graph $apiVersion was missing in a command. Special thanks to @magfrank #82
- Fixed an issue where a Device Health Script was referring to an empty variable. Special thanks to @SirBeredan #85

## [4.0.0] - 2025-01-07
- Updated to Microsoft.Graph PowerShell Module. Special thanks to @mhu4711
- Added support for backing up and restoring Autopilot Deployment Profiles.
- Added support for restoring Proactive Remediations.

## [3.2.0] - 2021-12-10
- Added support for backing up Proactive Remediations. Special thanks to @ztrhgf and @Kosipeich
- Added support for backing up Proactive Remediation Assignments. Special thanks to @ztrhgf and @Kosipeich
- Added additional improvements for Comparing Files and Directories. Special thanks to @ztrhgf
- Added an additional check for encrypted OMA-URI settings.

## [3.1.1] - 2021-08-19
- Added check if Custom OMA-URI is encrypted before attempting to decrypt.

## [3.1.0] - 2021-08-12
- Microsoft has started to encrypt Custom OMA-URI values in Device Configuration profiles. Because encrypted values are now stored in newer backups, restoration fails. This update decrypts those values prior to backing up the profile, enabling restoration again.

## [3.0.1] - 2021-06-21
- Minor bug fixes. 

## [3.0.0] - 2021-06-17
- Added support for backing up and restoring App Protection Policy assignments.
- Added support for backing up and restoring Settings Catalog profiles.
- Added support for backing up and restoring Settings Catalog assignments.
- Updated backup and restore output using a [PSCustomObject].
- Updated JSON depth across all functions for uniformity and to prevent (future) issues depending on the data that is being backed up/restored.
- Updated Device Management Intents, such as Windows 10 Security Baselines, where backups use a shorter filename, as users could run into issues with too long filepaths.
- Fixed an issue that would backup non-configured apps. (#38)


## [2.1.1] - 2021-02-20
- Fixed an issue where some properties in certain configurations, such as iOS Device restrictions, would not back-up, and would result in a failure during restore. 

## [2.1.0] - 2021-02-17
Special thanks to @sleeuwenhoek pull #23
- Added function `Invoke-IntuneBackupAppProtectionPolicy`.
- Added function `Invoke-IntuneRestoreDeviceManagementIntent`.

## [2.0.0] - 2020-06-15
### BREAKING
- Refactored the IntuneBackupAndRestore module to depend on Microsoft.Graph.Intune module, instead of the custom MSGraphFunctions module.
- Fixed an issue where restoring assignments could result in an error. Now also supports restoring assignments for Line-of-Business Client Apps.


## [1.5.0] - 2020-04-02
- Added function `Invoke-IntuneBackupDeviceManagementIntent`.
- Added function `Invoke-IntuneRestoreDeviceManagementIntent`.
- Embedded `Invoke-IntuneBackupDeviceManagementIntent` in the `Start-IntuneBackup` cmdlet.
- Embedded `Invoke-IntuneRestoreDeviceManagementIntent` in the `Start-IntuneRestoreConfig` cmdlet.

## [1.4.3] - 2019-12-22
- Added `Compare-IntuneBackupDirectories` to compare backup files from two backup sets. Co-authored-by: [Bradley Wyatt](https://github.com/bwya77)
- Fixed an issue with `Compare-IntuneBackupFile`, which would ignore JSON files that had no depth.

## [1.4.2] - 2019-07-19
- Update `Invoke-IntuneBackupClientApp` to include details such as detection rules, requirement rules and return codes.

## [1.4.1] - 2019-07-19
- Embedded function `Invoke-IntuneBackupClientApp` in the `Start-IntuneBackup` cmdlet.

## [1.4.0] - 2019-07-19
- Added function `Invoke-IntuneBackupClientApp`. Now supports backing up Intune Client App configurations.

## [1.3.2] - 2019-06-19
- Fixed an issue where Invoke-IntuneREstoreGroupPolicyAssignment was not recognized as the name of a cmdlet.

## [1.3.1] - 2019-05-01
- Fixed an issue introduced in v1.3.0 where Device Management Script Content would not be saved, because the file name was $null.

## [1.3.0] - 2019-04-29
- Fixed issue [#5 - Compare-IntuneBackupFile does not compare sub properties](https://github.com/jseerden/IntuneBackupAndRestore/issues/5)
- Fixed known issue: Intune Configurations that contain characters in their display name that are known to be invalid file name characters for Desktop Operating Systems are now backed up without error. Specifically, the invalid characters are replaced with underscores `_`, restores however use the displayName field available in the exported JSON.
- Fixed issue [#4 - Policies with brackets in their name cannot be saved](https://github.com/jseerden/IntuneBackupAndRestore/issues/4)
- Fixed typo: `Succesfully` is now displayed as `Successfully`.

## [1.2.1] - 2019-04-12
### Fixed
- Fixed an issue where backing up Group Policy Configurations (Administrative Templates) would generate incorrect JSON output for several settings.

## [1.2.0] - 2019-04-11
### Added
- Backing up Group Policy Configurations (Administrative Templates) added.
- Backing up Group Policy Configuration (Administrative Template) Assignments added.
- Restoring Group Policy Configurations (Administrative Templates) added.
- Restoring Group Policy Configuration (Administrative Template) Assignments added.

## [1.1.0] - 2019-03-17
### Added
- Added function `Compare-IntuneBackupFile`

## [1.0.1] - 2019-03-17
### Changed
- Fixed exported cmdlets in Module Manifest

## [1.0.0] - 2019-03-15
### Added
- PowerShell module initial release
- CHANGELOG file
- README file
- LICENSE