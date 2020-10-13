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
import XCTest

@testable import PPPC_Utility

class ModelTests: XCTestCase {

    var model = Model()

    // MARK: - tests for getExecutableFrom*

    func testGetExecutableBasedOnIdentifierAndCodeRequirement_BundleIdentifierType() {
        //given
            let identifier = "com.example.App"
            let codeRequirement = "testCodeRequirement"

        //when
            let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
            XCTAssertEqual(executable.displayName, "App")
            XCTAssertEqual(executable.codeRequirement, codeRequirement)
            XCTAssertEqual(executable.iconPath, IconFilePath.application)
    }

    func testGetExecutableBasedOnIdentifierAndCodeRequirement_PathIdentifierType() {
        //given
        let identifier = "/myGreatPath/Awesome/Binary"
        let codeRequirement = "testCodeRequirement"

        //when
        let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
        XCTAssertEqual(executable.displayName, "Binary")
        XCTAssertEqual(executable.codeRequirement, codeRequirement)
        XCTAssertEqual(executable.iconPath, IconFilePath.binary)
    }

    func testGetExecutableFromComputerBasedOnIdentifier() {
        //given
            let identifier = "com.apple.Safari"
            let codeRequirement = "randomReq"

        //when
            let executable = model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        //then
            XCTAssertEqual(executable.displayName, "Safari")
            XCTAssertNotEqual(executable.iconPath, IconFilePath.application)
            XCTAssertNotEqual(codeRequirement, executable.codeRequirement)
    }

    func testGetExecutableFromSelectedExecutables() {
        //given
        let expectedIdentifier = "com.something.1"
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executable, executableSecond]

        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        //then
        XCTAssertNotNil(existingExecutable)
        XCTAssertEqual(existingExecutable?.identifier, expectedIdentifier)
        XCTAssertEqual(existingExecutable?.displayName, "1")
        XCTAssertEqual(existingExecutable?.iconPath, IconFilePath.application)
    }

    func testGetExecutableFromSelectedExecutables_Path() {
        //given
        let expectedIdentifier = "/path/something/Special"
        let executableOneMore = model.getExecutableFrom(identifier: "/path/something/Special1", codeRequirement: "testReq")
        let executable = model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
        model.selectedExecutables = [executableOneMore, executable, executableSecond]

        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "/path/something/Special")

        //then
        XCTAssertNotNil(existingExecutable)
        XCTAssertEqual(existingExecutable?.identifier, expectedIdentifier)
        XCTAssertEqual(existingExecutable?.displayName, "Special")
        XCTAssertEqual(existingExecutable?.iconPath, IconFilePath.binary)
    }

    func testGetExecutableFromSelectedExecutables_Empty() {
        //when
        let existingExecutable = model.getExecutableFromSelectedExecutables(bundleIdentifier: "com.something.1")

        //then
        XCTAssertNil(existingExecutable)
    }

    // MARK: - tests for exportProfile

    func testExportProfileWithAppleEventsAndAuthorization() {
        // given
        model.usingLegacyAllowKey = false
        let exe1 = Executable(identifier: "one", codeRequirement: "oneReq")
        let exe2 = Executable(identifier: "two", codeRequirement: "twoReq")

        exe1.appleEvents = [AppleEventRule(source: exe1, destination: exe2, value: true)]
        exe2.policy.SystemPolicyAllFiles = "Let Standard Users Approve"

        model.selectedExecutables = [exe1, exe2]

        // when
        let profile = model.exportProfile(organization: "Org", identifier: "ID", displayName: "Name", payloadDescription: "Desc")

        // then check top level settings
        XCTAssertEqual("Org", profile.organization)
        XCTAssertEqual("ID", profile.identifier)
        XCTAssertEqual("Name", profile.displayName)
        XCTAssertEqual("Desc", profile.payloadDescription)
        XCTAssertEqual("System", profile.scope)
        XCTAssertEqual("Configuration", profile.type)
        XCTAssertNotNil(profile.uuid)
        XCTAssertEqual(1, profile.version)

        // then check policy settings
        // then verify the payload content top level
        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertNotNil(content.uuid)
            XCTAssertEqual(1, content.version)

            // then verify the services
            XCTAssertEqual(2, content.services.count)
            let appleEvents = content.services["AppleEvents"]
            XCTAssertNotNil(appleEvents)
            let appleEventsPolicy = appleEvents?.first
            XCTAssertEqual("one", appleEventsPolicy?.identifier)
            XCTAssertEqual("oneReq", appleEventsPolicy?.codeRequirement)
            XCTAssertEqual("bundleID", appleEventsPolicy?.identifierType)
            XCTAssertEqual("two", appleEventsPolicy?.receiverIdentifier)
            XCTAssertEqual("twoReq", appleEventsPolicy?.receiverCodeRequirement)
            XCTAssertEqual("bundleID", appleEventsPolicy?.receiverIdentifierType)
            XCTAssertTrue(appleEventsPolicy?.authorization == .allow)

            let allFiles = content.services["SystemPolicyAllFiles"]
            XCTAssertNotNil(allFiles)
            let allFilesPolicy = allFiles?.first
            XCTAssertEqual("two", allFilesPolicy?.identifier)
            XCTAssertEqual("twoReq", allFilesPolicy?.codeRequirement)
            XCTAssertEqual("bundleID", allFilesPolicy?.identifierType)
            XCTAssertNil(allFilesPolicy?.receiverIdentifier)
            XCTAssertNil(allFilesPolicy?.receiverCodeRequirement)
            XCTAssertNil(allFilesPolicy?.receiverIdentifierType)
            XCTAssertTrue(allFilesPolicy?.authorization == .allowStandardUserToSetSystemService)
        }
    }

    //swiftlint:disable:next function_body_length
    func testExportProfileWithAppleEventsAndLegacyAllowed() {
        // given
        let exe1 = Executable(identifier: "one", codeRequirement: "oneReq")
        let exe2 = Executable(identifier: "two", codeRequirement: "twoReq")

        exe1.appleEvents = [AppleEventRule(source: exe1, destination: exe2, value: true)]
        exe2.policy.SystemPolicyAllFiles = "Allow"

        model.selectedExecutables = [exe1, exe2]
        model.usingLegacyAllowKey = true

        // when
        let profile = model.exportProfile(organization: "Org", identifier: "ID", displayName: "Name", payloadDescription: "Desc")

        // then check top level settings
        XCTAssertEqual("Org", profile.organization)
        XCTAssertEqual("ID", profile.identifier)
        XCTAssertEqual("Name", profile.displayName)
        XCTAssertEqual("Desc", profile.payloadDescription)
        XCTAssertEqual("System", profile.scope)
        XCTAssertEqual("Configuration", profile.type)
        XCTAssertNotNil(profile.uuid)
        XCTAssertEqual(1, profile.version)

        // then check policy settings
        // then verify the payload content top level
        XCTAssertEqual(1, profile.content.count)
        profile.content.forEach { content in
            XCTAssertNotNil(content.uuid)
            XCTAssertEqual(1, content.version)

            // then verify the services
            XCTAssertEqual(2, content.services.count)
            let appleEvents = content.services["AppleEvents"]
            XCTAssertNotNil(appleEvents)
            let appleEventsPolicy = appleEvents?.first
            XCTAssertEqual("one", appleEventsPolicy?.identifier)
            XCTAssertEqual("oneReq", appleEventsPolicy?.codeRequirement)
            XCTAssertEqual("bundleID", appleEventsPolicy?.identifierType)
            XCTAssertEqual("two", appleEventsPolicy?.receiverIdentifier)
            XCTAssertEqual("twoReq", appleEventsPolicy?.receiverCodeRequirement)
            XCTAssertEqual("bundleID", appleEventsPolicy?.receiverIdentifierType)
            XCTAssertTrue(appleEventsPolicy?.allowed == true)
            XCTAssertNil(appleEventsPolicy?.authorization)

            let allFiles = content.services["SystemPolicyAllFiles"]
            XCTAssertNotNil(allFiles)
            let allFilesPolicy = allFiles?.first
            XCTAssertEqual("two", allFilesPolicy?.identifier)
            XCTAssertEqual("twoReq", allFilesPolicy?.codeRequirement)
            XCTAssertEqual("bundleID", allFilesPolicy?.identifierType)
            XCTAssertNil(allFilesPolicy?.receiverIdentifier)
            XCTAssertNil(allFilesPolicy?.receiverCodeRequirement)
            XCTAssertNil(allFilesPolicy?.receiverIdentifierType)
            XCTAssertTrue(allFilesPolicy?.allowed == true)
            XCTAssertNil(allFilesPolicy?.authorization)
        }
    }

    // MARK: - tests for importProfile

    func testImportProfileUsingAuthorizationKeyAllow() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .allow)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Allow", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingAuthorizationKeyDeny() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .deny)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Deny", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingAuthorizationKeyAllowStandardUsers() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Let Standard Users Approve", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingLegacyAllowKeyTrue() {
        // given
        let profile = TCCProfileBuilder().buildProfile(allowed: true)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Allow", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingLegacyAllowKeyFalse() {
        // given
        let profile = TCCProfileBuilder().buildProfile(allowed: false)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Deny", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingAuthorizationKeyThatIsInvalid() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: "invalidkey")

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Deny", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    func testImportProfileUsingAuthorizationKeyTranslatesToAppleEvents() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: "deny")

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertEqual(1, model.selectedExecutables.count)
        XCTAssertEqual("Deny", model.selectedExecutables.first?.policy.SystemPolicyAllFiles)
    }

    // MARK: - tests for profileToString

    func testPolicyWhenUsingAllowAndAuthorizationKey() {
        // given
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Allow")

        // then
        XCTAssertEqual(policy?.authorization, TCCPolicyAuthorizationValue.allow)
        XCTAssertNil(policy?.allowed)
    }

    func testPolicyWhenUsingDeny() {
        // given
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Deny")

        // then
        XCTAssertEqual(policy?.authorization, TCCPolicyAuthorizationValue.deny)
        XCTAssertNil(policy?.allowed)
    }

    func testPolicyWhenUsingAllowForStandardUsers() {
        // given
        model.usingLegacyAllowKey = false
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Let Standard Users Approve")

        // then
        XCTAssertEqual(policy?.authorization, TCCPolicyAuthorizationValue.allowStandardUserToSetSystemService)
        XCTAssertNil(policy?.allowed)
    }

    func testPolicyWhenUsingUnknownValue() {
        // given
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "For MDM Admins Only")

        // then
        XCTAssertNil(policy, "should have not created the policy with an unknown value")
    }

    func testPolicyWhenUsingLegacyDeny() {
        // given
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Deny")

        // then
        XCTAssertNil(policy?.authorization, "should not set authorization when in legacy mode")
        XCTAssertEqual(policy?.allowed, false)
    }

    func testPolicyWhenUsingLegacyAllow() {
        // given
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Allow")

        // then
        XCTAssertNil(policy?.authorization, "should not set authorization when in legacy mode")
        XCTAssertEqual(policy?.allowed, true)
    }

    // test for the unrecognized strings for both legacy and normal
    func testPolicyWhenUsingLegacyAllowButNonLegacyValueUsed() {
        // given
        let app = Executable(identifier: "id", codeRequirement: "req")
        model.usingLegacyAllowKey = true

        // when
        let policy = model.policyFromString(executable: app, value: "Let Standard Users Approve")

        // then
        XCTAssertNil(policy, "should have errored out because of an invalid value")
    }

    /// MARK: - tests for requiresAuthorizationKey

    func testWhenServiceIsUsingAllowStandarUsersToApprove() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertTrue(model.requiresAuthorizationKey())
    }

    func testWhenServiceIsUsingOnlyAllowKey() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .allow)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertFalse(model.requiresAuthorizationKey())
    }

    func testWhenServiceIsUsingOnlyDenyKey() {
        // given
        let profile = TCCProfileBuilder().buildProfile(authorization: .deny)

        // when
        model.importProfile(tccProfile: profile)

        // then
        XCTAssertFalse(model.requiresAuthorizationKey())
    }

    // MARK: - tests for changeToUseLegacyAllowKey

    func testChangingFromAuthorizationKeyToLegacyAllowKey() {
        // given
        let allowStandard = TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue
        let exeSettings = ["AddressBook": "Allow", "ListenEvent": allowStandard, "ScreenCapture": allowStandard]
        let model = ModelBuilder().addExecutable(settings: exeSettings).build()
        model.usingLegacyAllowKey = false

        // when
        model.changeToUseLegacyAllowKey()

        // then
        XCTAssertEqual(1, model.selectedExecutables.count, "should have only one exe")
        let policy = model.selectedExecutables.first?.policy
        XCTAssertEqual("Allow", policy?.AddressBook)
        XCTAssertEqual("-", policy?.Camera)
        XCTAssertEqual("-", policy?.ListenEvent)
        XCTAssertEqual("-", policy?.ScreenCapture)
        XCTAssertTrue(model.usingLegacyAllowKey)
    }

    func testChangingFromAuthorizationKeyToLegacyAllowKeyWithMoreComplexVaues() {
        // given
        let allowStandard = TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue
        let p1Settings = ["SystemPolicyAllFiles": "Allow",
                           "ListenEvent": allowStandard,
                           "ScreenCapture": "Deny",
                           "Camera": "Deny"]

        let p2Settings = ["SystemPolicyAllFiles": "Deny",
                           "ScreenCapture": allowStandard,
                           "Calendar": "Allow"]
        let builder = ModelBuilder().addExecutable(settings: p1Settings)
        model = builder.addExecutable(settings: p2Settings).build()
        model.usingLegacyAllowKey = false

        // when
        model.changeToUseLegacyAllowKey()

        // then
        XCTAssertEqual(2, model.selectedExecutables.count, "should have only one exe")
        let policy1 = model.selectedExecutables[0].policy
        XCTAssertEqual("Allow", policy1.SystemPolicyAllFiles)
        XCTAssertEqual("-", policy1.ListenEvent)
        XCTAssertEqual("Deny", policy1.ScreenCapture)
        XCTAssertEqual("Deny", policy1.Camera)

        let policy2 = model.selectedExecutables[1].policy
        XCTAssertEqual("Deny", policy2.SystemPolicyAllFiles)
        XCTAssertEqual("-", policy2.ListenEvent)
        XCTAssertEqual("-", policy2.ScreenCapture)
        XCTAssertEqual("Allow", policy2.Calendar)
        XCTAssertTrue(model.usingLegacyAllowKey)
    }

}
