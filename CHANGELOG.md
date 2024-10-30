# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
<!-- Add any information here about changes in master that have yet to be released -->

### Added
- Connection to Jamf Pro can now use client credentials with Jamf Pro v10.49+ ([Issue #120](https://github.com/jamf/PPPC-Utility/issues/120)) [@macblazer](https://github.com/macblazer).

### Changed
- Update print and os_log calls to the modern OSLog class calls for updated logging. ([Issue #112](https://github.com/jamf/PPPC-Utility/issues/112)) [@SkylerGodfrey](https://github.com/SkylerGodfrey)
- Now using [Haversack](https://github.com/jamf/Haversack) for simplified access to the keychain ([Issue #124](https://github.com/jamf/PPPC-Utility/issues/124)) [@macblazer](https://github.com/macblazer).
- PPPC Utility now requires macOS 11+ to run.  It can still produce profiles usable on older versions of macOS.

## [1.5.0] - 2022-10-04

### Added
- Help buttons now list related codesigning entitlements ([Issue #105](https://github.com/jamf/PPPC-Utility/issues/105)) [@macblazer](https://github.com/macblazer).

### Changed
- Uses token authentication to Jamf Pro API and falls back to Basic authentication if that fails ([Issue #113](https://github.com/jamf/PPPC-Utility/issues/113)) [@macblazer](https://github.com/macblazer).
- Now reads profile keys in a case-insensitive manner during import ([Issue #88](https://github.com/jamf/PPPC-Utility/issues/88)) [@macblazer](https://github.com/macblazer).
- The items in this changelog have been formatted for consistency with links to GitHub issues and contributor profiles.


## [1.4.0] - 2021-08-11

### Added
- Changed the property labels to match System Preferences with the MDM key listed in the help ([Issue #79](https://github.com/jamf/PPPC-Utility/issues/79)) [@ty-wilson](https://github.com/ty-wilson).
- Application list and Apple Events app list both support multiple apps being dragged into the list ([Issue #85](https://github.com/jamf/PPPC-Utility/issues/85)) [@macblazer](https://github.com/macblazer).

### Fixed
- The code signing label will no longer be truncated ([Issue #54](https://github.com/jamf/PPPC-Utility/issues/54)) [@ty-wilson](https://github.com/ty-wilson).
- Deleting an Apple Event removes the selected item instead of always removing the first one in the list ([Issue #83](https://github.com/jamf/PPPC-Utility/issues/83)) [@ty-wilson](https://github.com/ty-wilson).


## [1.3.0] - 2020-10-22

### Added
- Added this Changelog.md file [@hisaac](https://github.com/hisaac).
- The default value on Apple Events is now "Allow" ([Issue #72](https://github.com/jamf/PPPC-Utility/issues/72)) [@ty-wilson](https://github.com/ty-wilson).
- Added support for the new `Authorization` key in Big Sur [@watkyn](https://github.com/watkyn).
- Changed minimum deployment target to macOS 10.15 [@watkyn](https://github.com/watkyn).


## [1.2.1] - 2020-09-17

Thank you to all the contributors in this release!

### Added
- Added swiftlint to the project [@stavares843](https://github.com/stavares843).
- Added a swiftlint GitHub Action [@stavares843](https://github.com/stavares843).
- Added some alerts for better error reporting [@BIG-RAT](https://github.com/BIG-RAT).

### Fixed
- Buttons can no longer go off the screen in certain circumstances [@BIG-RAT](https://github.com/BIG-RAT).
- PPPC Utility now properly uploads profiles to Jamf Pro version 10.23 and greater [@kkot](https://github.com/kkot).


## [1.2.0] - 2020-04-29

### Added
- Can now import existing profiles from disk [@adku](https://github.com/adku).

### Fixed
- TCC properties are ordered alphabetically [@ty-wilson](https://github.com/ty-wilson).
- Duplicate apps can no longer be added to the view [@BIG-RAT](https://github.com/BIG-RAT).
- TCC profile xml properties fixes so profiles can be added to Jamf Now [@pirkla](https://github.com/pirkla).
- Updated labels and placeholders [@pirkla](https://github.com/pirkla).


## [1.1.2] - 2019-10-07

### Fixed
- Locally saved profiles are now properly signed if that option is selected while saving. ([Issues #2](https://github.com/jamf/PPPC-Utility/issues/2) and [#25](https://github.com/jamf/PPPC-Utility/issues/25)) [@adku](https://github.com/adku).


## [1.1.1] - 2019-09-20

### Fixed
- Updated old app name that was used in PPPC Utility menu. ([Issue #18](https://github.com/jamf/PPPC-Utility/issues/18)) [@adku](https://github.com/adku).


## [1.1.0] - 2019-09-10

### Changed
- Updated with the new macOS 10.15 Privacy Preferences Policy Control keys [@mm512](https://github.com/mm512).
- Minor user interface updates [@mm512](https://github.com/mm512).


## [1.0.1] - 2018-10-03

### Fixed
- Rules using `SystemPolicySysAdminFiles` are now created correctly ([Issue #4](https://github.com/jamf/PPPC-Utility/issues/4)) [@cyrusingraham](https://github.com/cyrusingraham).


## [1.0.0] - 2018-09-21

Initial release [@cyrusingraham](https://github.com/cyrusingraham).

<!--  -->

[unreleased]: https://github.com/jamf/PPPC-Utility/compare/1.5.0...master
[1.5.0]: https://github.com/jamf/PPPC-Utility/compare/1.4.0...1.5.0
[1.4.0]: https://github.com/jamf/PPPC-Utility/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/jamf/PPPC-Utility/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/jamf/PPPC-Utility/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/jamf/PPPC-Utility/compare/1.1.2...1.2.0
[1.1.2]: https://github.com/jamf/PPPC-Utility/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/jamf/PPPC-Utility/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/jamf/PPPC-Utility/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/jamf/PPPC-Utility/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/jamf/PPPC-Utility/compare/047786dad486e8cc1e159d3f315adb695a566465...1.0.0
