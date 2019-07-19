# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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