fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
### clean
```
fastlane clean
```
Deletes build directory
### test_spm_package
```
fastlane test_spm_package
```
Runs the unit tests for a Swift Package Manager package; junit format test results will be in <base>/build/spm_test_results.xml
### test_cocoapods_pod
```
fastlane test_cocoapods_pod
```
Runs the tests to verify a CocoaPod builds correctly; junit format test results will be in <base>/build/pod_test_results.xml

----

## Mac
### mac build
```
fastlane mac build
```

### mac run_tests
```
fastlane mac run_tests
```
Runs the unit tests
### mac notarize_build
```
fastlane mac notarize_build
```
Notarizes the PPPC Utility

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
