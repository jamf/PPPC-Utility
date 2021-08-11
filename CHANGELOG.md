# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
<!-- Add any information here about changes in master that have yet to be released -->

## [1.4.0]

### Added
- (@ty-wilson) Issue #79 Changed the property labels to match System Preferces with the MDM key listed in the help
- (@macblazer) Issue #85 Application list and Apple Events app list both support multiple apps being dragged into the list.

### Fixed
- (@ty-wilson) Fixed issue #54 where the code signing label was truncated
- (@ty-wilson) Fixed issue #83 where removing an apple event always removed the first one in the list instead of the selected item


## [1.3.0]

### Added

- (@hisaac) Added this changelog file
- (@ty-wilson) Fixed issue #72 changing the default value on Apple Events to "Allow"
- (@watkyn) Added support for the new Authorization key in Big Sur
- (@watkyn) Changed minimum deployment target to macOS 10.15


## [1.2.1] - 2020-09-17

Thank you to all the contributors in this release!

### Added

-   Added swiftlint to the project (@stavares843)
-   Added a swiftlint GitHub Action (@stavares843)
-   Added some alerts for better error reporting (@BIG-RAT)

### Fixed

-   Fixed an issue where buttons could go off the screen in certain circumstances (@BIG-RAT)
-   Fixed an issue where PPPC Utility would fail to upload profiles to Jamf Pro version 10.23 and greater (@kkot)

## [1.2.0] - 2020-04-29

### Added

-   Added a feature to import existing profiles from disk (@adku)

### Fixed

-   TCC properties are ordered alphabetically (@ty-wilson)
-   Duplicate apps are not added to the view (@BIG-RAT)
-   TCC profile xml properties fixes (@pirkla) - This resolved an issue so profiles created with the PPPC Utility can be added to Jamf Now
-   Updated labels and placeholders (@pirkla)

## [1.1.2] - 2019-10-07

### Fixed

-   A fix for issue #2 reported by @golbiga and issue #25 reported by @bartreardon, fixed by @adku in pull request #16

## [1.1.1] - 2019-09-20

### Fixed

-   A fix for for issue #18 reported by @drunkonmusic, fixed by @adku in pull request #19

## [1.1.0] - 2019-09-10

### Changed

-   Updated with the new macOS 10.15 Privacy Preferences Policy Control keys
-   Minor user interface updates

## [1.0.1] - 2018-10-03

### Fixed

-   Fixed an issue discovered by @Lotusshaney where rules using `SystemPolicySysAdminFiles` were not created correctly.

## [1.0.0] - 2018-09-21

Initial release

<!--  -->

[unreleased]: https://github.com/jamf/PPPC-Utility/compare/1.2.1...master
[1.2.1]: https://github.com/jamf/PPPC-Utility/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/jamf/PPPC-Utility/compare/1.1.2...1.2.0
[1.1.2]: https://github.com/jamf/PPPC-Utility/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/jamf/PPPC-Utility/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/jamf/PPPC-Utility/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/jamf/PPPC-Utility/compare/1.0.1...1.0.1
[1.0.0]: https://github.com/jamf/PPPC-Utility/compare/047786dad486e8cc1e159d3f315adb695a566465...1.0.0
