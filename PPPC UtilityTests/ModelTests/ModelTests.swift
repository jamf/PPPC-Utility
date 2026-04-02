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
    func getExecutableBasedOnIdentifierAndCodeRequirement_BundleIdentifierType() async {
        let identifier = "com.example.App"
        let codeRequirement = "testCodeRequirement"

        // when
        let executable = await model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "App")
        #expect(executable.codeRequirement == codeRequirement)
        #expect(executable.iconPath == IconFilePath.application)
    }

    @Test
    func getExecutableBasedOnIdentifierAndCodeRequirement_PathIdentifierType() async {
        let identifier = "/myGreatPath/Awesome/Binary"
        let codeRequirement = "testCodeRequirement"

        // when
        let executable = await model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "Binary")
        #expect(executable.codeRequirement == codeRequirement)
        #expect(executable.iconPath == IconFilePath.binary)
    }

    @Test
    func getExecutableFromComputerBasedOnIdentifier() async {
        let identifier = "com.apple.Safari"
        let codeRequirement = "randomReq"

        // when
        let executable = await model.getExecutableFrom(identifier: identifier, codeRequirement: codeRequirement)

        // then
        #expect(executable.displayName == "Safari")
        #expect(executable.iconPath != IconFilePath.application)
        #expect(executable.codeRequirement != codeRequirement)
    }

    @Test
    func getExecutableFromSelectedExecutables() async {
        let expectedIdentifier = "com.something.1"
        let executable = await model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = await model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
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
    func getExecutableFromSelectedExecutables_Path() async {
        let expectedIdentifier = "/path/something/Special"
        let executableOneMore = await model.getExecutableFrom(identifier: "/path/something/Special1", codeRequirement: "testReq")
        let executable = await model.getExecutableFrom(identifier: expectedIdentifier, codeRequirement: "testReq")
        let executableSecond = await model.getExecutableFrom(identifier: "com.something.2", codeRequirement: "testReq2")
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

    // MARK: - tests for importProfile

    @Test
    func importProfileUsingAuthorizationKeyAllow() async {
        let profile = TCCProfileBuilder().buildProfile(authorization: .allow)

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Allow")
    }

    @Test
    func importProfileUsingAuthorizationKeyDeny() async {
        let profile = TCCProfileBuilder().buildProfile(authorization: .deny)

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyAllowStandardUsers() async {
        let profile = TCCProfileBuilder().buildProfile(authorization: .allowStandardUserToSetSystemService)

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Let Standard Users Approve")
    }

    @Test
    func importProfileUsingLegacyAllowKeyTrue() async {
        let profile = TCCProfileBuilder().buildProfile(allowed: true)

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Allow")
    }

    @Test
    func importProfileUsingLegacyAllowKeyFalse() async {
        let profile = TCCProfileBuilder().buildProfile(allowed: false)

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyThatIsInvalid() async {
        let profile = TCCProfileBuilder().buildProfile(authorization: "invalidkey")

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    @Test
    func importProfileUsingAuthorizationKeyTranslatesToAppleEvents() async {
        let profile = TCCProfileBuilder().buildProfile(authorization: "deny")

        // when
        await model.importProfile(tccProfile: profile)

        // then
        #expect(model.selectedExecutables.count == 1)
        #expect(model.selectedExecutables.first?.policy.SystemPolicyAllFiles == "Deny")
    }

    // MARK: - tests for policyFromString

    @Test
    func policyWhenUsingAllow() {
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Allow")

        // then
        #expect(policy?.authorization == .allow)
    }

    @Test
    func policyWhenUsingDeny() {
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Deny")

        // then
        #expect(policy?.authorization == .deny)
    }

    @Test
    func policyWhenUsingAllowForStandardUsers() {
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "Let Standard Users Approve")

        // then
        #expect(policy?.authorization == .allowStandardUserToSetSystemService)
    }

    @Test
    func policyWhenUsingUnknownValue() {
        let app = Executable(identifier: "id", codeRequirement: "req")

        // when
        let policy = model.policyFromString(executable: app, value: "For MDM Admins Only")

        // then
        #expect(policy == nil, "should have not created the policy with an unknown value")
    }

}
