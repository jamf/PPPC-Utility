//
//  ModelTests.swift
//  PPPC UtilityTests
//
//  MIT License
//
//  Copyright (c) 2019 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Testing

@testable import PPPC_Utility

@Suite
struct ModelTests {

    let model = Model()

    // MARK: - tests for getExecutableFrom*

    @Test
    func getExecutableBasedOnIdentifierAndCodeRequirement_BundleIdentifierType() {
        let identifier = "com.example.App"
        let codeRequirement = "testCodeRequirement"

        // when
        let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "App")
        #expect(executable.codeRequirement == codeRequirement)
        #expect(executable.iconPath == IconFilePath.application)
    }

    @Test
    func getExecutableBasedOnIdentifierAndCodeRequirement_PathIdentifierType() {
        let identifier = "/myGreatPath/Awesome/Binary"
        let codeRequirement = "testCodeRequirement"

        // when
        let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "Binary")
        #expect(executable.codeRequirement == codeRequirement)
        #expect(executable.iconPath == IconFilePath.binary)
    }

    @Test
    func getExecutableFromComputerBasedOnIdentifier() {
        let identifier = "com.apple.Safari"
        let codeRequirement = "randomReq"

        // when
        let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "Safari")
        #expect(executable.iconPath != IconFilePath.application)
        #expect(executable.codeRequirement != codeRequirement)
    }

    @Test
    func getExecutableFromSelectedExecutables() {
        let expectedIdentifier = "com.something.1"
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executable, executableSecond]

        // when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        // then
        #expect(existingExecutable != nil)
        #expect(existingExecutable?.identifier == expectedIdentifier)
        #expect(existingExecutable?.displayName == "1")
        #expect(existingExecutable?.iconPath == IconFilePath.application)
    }

    @Test
    func getExecutableFromSelectedExecutables_Path() {
        let expectedIdentifier = "/path/something/Special"
        let executableOneMore = model.getExecutableFrom(identifier: "/path/something/Special1", codeRequirement: "testReq")
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executableOneMore, executable, executableSecond]

        // when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "/path/something/Special")

        // then
        #expect(existingExecutable != nil)
        #expect(existingExecutable?.identifier == expectedIdentifier)
        #expect(existingExecutable?.displayName == "Special")
        #expect(existingExecutable?.iconPath == IconFilePath.binary)
    }

    @Test
    func getExecutableFromSelectedExecutables_Empty() {
        // when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        // then
        #expect(existingExecutable == nil)
    }

    // MARK: - tests for exportProfile

    @Test
    func exportProfileWithAppleEventsAndAuthorization() {
        model.usingLegacyAllowKey = false
        let exe1 = Executable(identifier: "one", codeRequirement: "oneReq")
        let exe2 = Executable(identifier: "two", codeRequirement: "twoReq")

        exe1.appleEvents = [AppleEventRule(source: exe1, destination: exe2, value: true)]
        exe2.policy.SystemPolicyAllFiles = "Let Standard Users Approve"

        model.selectedExecutables = [exe1, exe2]

        // when
        let profile = model.exportProfile(organization: "Org", identifier: "ID", displayName: "Name", payloadDescription: "Desc")

        // then check top level settings
        #expect(profile.organization == "Org")
        #expect(profile.identifier == "ID")
        #expect(profile.displayName == "Name")
        #expect(profile.payloadDescription == "Desc")
        #expect(profile.scope == "System")
        #expect(profile.type == "Configuration")
        #expect(!profile.uuid.isEmpty)
        #expect(profile.version == 1)

        // then check policy settings
        // then verify the payload content top level
        #expect(profile.content.count == 1)
        profile.content.forEach { content in
            #expect(!content.uuid.isEmpty)
            #expect(content.version == 1)

            // then verify the services
            #expect(content.services.count == 2)
            let appleEvents = content.services["AppleEvents"]
            #expect(appleEvents != nil)
            let appleEventsPolicy = appleEvents?.first
            #expect(appleEventsPolicy?.identifier == "one")
            #expect(appleEventsPolicy?.codeRequirement == "oneReq")
            #expect(appleEventsPolicy?.identifierType == "bundleID")
            #expect(appleEventsPolicy?.receiverIdentifier == "two")
            #expect(appleEventsPolicy?.receiverCodeRequirement == "twoReq")
            #expect(appleEventsPolicy?.receiverIdentifierType == "bundleID")
            #expect(appleEventsPolicy?.authorization == .allow)

            let allFiles = content.services["SystemPolicyAllFiles"]
            #expect(allFiles != nil)
            let allFilesPolicy = allFiles?.first
            #expect(allFilesPolicy?.identifier == "two")
            #expect(allFilesPolicy?.codeRequirement == "twoReq")
            #expect(allFilesPolicy?.identifierType == "bundleID")
            #expect(allFilesPolicy?.receiverIdentifier == nil)
            #expect(allFilesPolicy?.receiverCodeRequirement == nil)
            #expect(allFilesPolicy?.receiverIdentifierType == nil)
            #expect(allFilesPolicy?.authorization == .allowStandardUserToSetSystemService)
        }
    }

    @Test
    func exportProfileWithAppleEventsAndLegacyAllowed() {
        let exe1 = Executable(identifier: "one", codeRequirement: "oneReq")
        let exe2 = Executable(identifier: "two", codeRequirement: "twoReq")
        exe1.appleEvents = [AppleEventRule(source: exe1, destination: exe2, value: true)]
        exe2.policy.SystemPolicyAllFiles = "Allow"
        model.selectedExecutables = [exe1, exe2]
        model.usingLegacyAllowKey = true

        // when
        let profile = model.exportProfile(organization: "Org", identifier: "ID", displayName: "Name", payloadDescription: "Desc")

        // then check top level settings
        #expect(profile.organization == "Org")
        #expect(profile.identifier == "ID")
        #expect(profile.displayName == "Name")
        #expect(profile.payloadDescription == "Desc")
        #expect(profile.scope == "System")
        #expect(profile.type == "Configuration")
        #expect(!profile.uuid.isEmpty)
        #expect(profile.version == 1)

        // then verify the payload content top level
        #expect(profile.content.count == 1)
        profile.content.forEach { content in
            #expect(!content.uuid.isEmpty)
            #expect(content.version == 1)

            // then verify the services
            #expect(content.services.count == 2)
            let appleEventsPolicy = content.services["AppleEvents"]?.first
            #expect(appleEventsPolicy != nil)
            #expect(appleEventsPolicy?.identifier == "one")
            #expect(appleEventsPolicy?.codeRequirement == "oneReq")
            #expect(appleEventsPolicy?.identifierType == "bundleID")
            #expect(appleEventsPolicy?.receiverIdentifier == "two")
            #expect(appleEventsPolicy?.receiverCodeRequirement == "twoReq")
            #expect(appleEventsPolicy?.receiverIdentifierType == "bundleID")
            #expect(appleEventsPolicy?.allowed == true)
            #expect(appleEventsPolicy?.authorization == nil)

            let allFilesPolicy = content.services["SystemPolicyAllFiles"]?.first
            #expect(allFilesPolicy != nil)
            #expect(allFilesPolicy?.identifier == "two")
            #expect(allFilesPolicy?.codeRequirement == "twoReq")
            #expect(allFilesPolicy?.identifierType == "bundleID")
            #expect(allFilesPolicy?.receiverIdentifier == nil)
            #expect(allFilesPolicy?.receiverCodeRequirement == nil)
            #expect(allFilesPolicy?.receiverIdentifierType == nil)
            #expect(allFilesPolicy?.allowed == true)
            #expect(allFilesPolicy?.authorization == nil)
        }
    }

    // MARK: - tests for importProfile

    @Test
    func importProfileUsingAuthorizationKeyAllow() {
        let profile = TCCProfileBuilder().buildProfile(authorization: .allow)

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Allow")
    }

    @Test
    func importProfileUsingAuthorizationKeyDeny() {
        let profile = TCCProfileBuilder().buildProfile(authorization: .deny)

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyAllowStandardUsers() {
        let profile = TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService)

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Let Standard Users Approve")
    }

    @Test
    func importProfileUsingLegacyAllowKeyTrue() {
        let profile = TCCProfileBuilder().buildProfile(allowed: true)

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Allow")
    }

    @Test
    func importProfileUsingLegacyAllowKeyFalse() {
        let profile = TCCProfileBuilder().buildProfile(allowed: false)

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyThatIsInvalid() {
        let profile = TCCProfileBuilder().buildProfile(authorization: "invalidkey")

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyTranslatesToAppleEvents() {
        let profile = TCCProfileBuilder().buildProfile(authorization: "deny")

        // when
        model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    // MARK: - tests for profileToString

    @Test
    func policyWhenUsingAllowAndAuthorizationKey() {
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Allow")

        // then
        #expect(policy?.authorization == .allow)
        #expect(policy?.allowed == nil)
    }

    @Test
    func policyWhenUsingDeny() {
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Deny")

        // then
        #expect(policy?.authorization == .deny)
        #expect(policy?.allowed == nil)
    }

    @Test
    func policyWhenUsingAllowForStandardUsers() {
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Let Standard Users Approve")

        // then
        #expect(policy?.authorization == .allowStandardUserToSetSystemService)
        #expect(policy?.allowed == nil)
    }

    @Test
    func policyWhenUsingUnknownValue() {
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "For MDM Admins Only")

        // then
        #expect(policy == nil, "should have not created the policy with an unknown value")
    }

    @Test
    func policyWhenUsingLegacyDeny() {
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Deny")

        // then
        #expect(policy?.authorization == nil, "should not set authorization when in legacy mode")
        #expect(policy?.allowed == false)
    }

    @Test
    func policyWhenUsingLegacyAllow() {
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Allow")

        // then
        #expect(policy?.authorization == nil, "should not set authorization when in legacy mode")
        #expect(policy?.allowed == true)
    }

    // test for the unrecognized strings for both legacy and normal
    @Test
    func policyWhenUsingLegacyAllowButNonLegacyValueUsed() {
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Let Standard Users Approve")

        // then
        #expect(policy == nil, "should have errored out because of an invalid value")
    }

    // MARK: - tests for requiresAuthorizationKey

    @Test(arguments: [
        (TCCPolicyAuthorizationValue.allowStandardUserToSetSystemService, true),
        (TCCPolicyAuthorizationValue.allow, false),
        (TCCPolicyAuthorizationValue.deny, false),
    ])
    func requiresAuthorizationKey(authorization: TCCPolicyAuthorizationValue, expected: Bool) {
        let profile = TCCProfileBuilder().buildProfile(authorization: authorization)
        model.importProfile(tccProfile: profile)
        #expect(model.requiresAuthorizationKey() == expected)
    }

    // MARK: - tests for changeToUseLegacyAllowKey

    @Test
    func changingFromAuthorizationKeyToLegacyAllowKey() {
        let allowStandard = TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue
        let exeSettings = ["AddressBook": "Allow", "ListenEvent": allowStandard, "ScreenCapture": allowStandard]
        let model = ModelBuilder().addExecutable(settings: exeSettings).build()
        model.usingLegacyAllowKey = false

        // when
        model.changeToUseLegacyAllowKey()

        // then
        #expect(model.selectedExecutables.count == 1, "should have only one exe")
        let policy = model.selectedExecutables.first?.policy
        #expect(policy?.AddressBook == "Allow")
        #expect(policy?.Camera == "-")
        #expect(policy?.ListenEvent == "-")
        #expect(policy?.ScreenCapture == "-")
        #expect(model.usingLegacyAllowKey)
    }

    @Test
    func changingFromAuthorizationKeyToLegacyAllowKeyWithMoreComplexVaues() {
        let allowStandard = TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue
        let p1Settings = [
            "SystemPolicyAllFiles": "Allow",
            "ListenEvent": allowStandard,
            "ScreenCapture": "Deny",
            "Camera": "Deny"
        ]

        let p2Settings = [
            "SystemPolicyAllFiles": "Deny",
            "ScreenCapture": allowStandard,
            "Calendar": "Allow"
        ]
        let builder = ModelBuilder().addExecutable(settings: p1Settings)
        let model = builder.addExecutable(settings: p2Settings).build()
        model.usingLegacyAllowKey = false

        // when
        model.changeToUseLegacyAllowKey()

        // then
        #expect(model.selectedExecutables.count == 2, "should have only one exe")
        let policy1 = model.selectedExecutables[0].policy
        #expect(policy1.SystemPolicyAllFiles == "Allow")
        #expect(policy1.ListenEvent == "-")
        #expect(policy1.ScreenCapture == "Deny")
        #expect(policy1.Camera == "Deny")

        let policy2 = model.selectedExecutables[1].policy
        #expect(policy2.SystemPolicyAllFiles == "Deny")
        #expect(policy2.ListenEvent == "-")
        #expect(policy2.ScreenCapture == "-")
        #expect(policy2.Calendar == "Allow")
        #expect(model.usingLegacyAllowKey)
    }

}
