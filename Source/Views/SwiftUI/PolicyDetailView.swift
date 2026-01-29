//
//  PolicyDetailView.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

/// Detail view showing all policy settings for a selected executable
struct PolicyDetailView: View {
    @Bindable var executable: Executable
    @Bindable var model: Model
    let services = PPPCServicesManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with executable info
                executableHeader
                    .padding()

                Divider()

                // Policy settings
                VStack(alignment: .leading, spacing: 8) {
                    policySection
                }
                .padding()

                Divider()

                // Apple Events section
                appleEventsSection
                    .padding()
            }
        }
    }

    // MARK: - Header

    private var executableHeader: some View {
        HStack(spacing: 12) {
            ExecutableIcon(iconPath: executable.iconPath)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(executable.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(executable.identifier)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(executable.codeRequirement)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    // MARK: - Policy Pickers

    private var policySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Permissions")
                .font(.headline)
                .padding(.bottom, 4)

            Group {
                PolicyPicker("Address Book", selection: $executable.policy.AddressBook,
                           type: .allowDeny, helpText: services.allServices["AddressBook"]?.userHelp)
                PolicyPicker("Calendar", selection: $executable.policy.Calendar,
                           type: .allowDeny, helpText: services.allServices["Calendar"]?.userHelp)
                PolicyPicker("Reminders", selection: $executable.policy.Reminders,
                           type: .allowDeny, helpText: services.allServices["Reminders"]?.userHelp)
                PolicyPicker("Photos", selection: $executable.policy.Photos,
                           type: .allowDeny, helpText: services.allServices["Photos"]?.userHelp)
                PolicyPicker("Camera", selection: $executable.policy.Camera,
                           type: .denyOnly, helpText: services.allServices["Camera"]?.userHelp)
                PolicyPicker("Microphone", selection: $executable.policy.Microphone,
                           type: .denyOnly, helpText: services.allServices["Microphone"]?.userHelp)
            }

            Divider().padding(.vertical, 8)

            Group {
                PolicyPicker("Accessibility", selection: $executable.policy.Accessibility,
                           type: .allowDeny, helpText: services.allServices["Accessibility"]?.userHelp)
                PolicyPicker("Post Event", selection: $executable.policy.PostEvent,
                           type: .allowDeny, helpText: services.allServices["PostEvent"]?.userHelp)
                PolicyPicker("System Admin Files", selection: $executable.policy.SystemPolicySysAdminFiles,
                           type: .allowDeny, helpText: services.allServices["SystemPolicySysAdminFiles"]?.userHelp)
                PolicyPicker("All Files", selection: $executable.policy.SystemPolicyAllFiles,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyAllFiles"]?.userHelp)
            }

            Divider().padding(.vertical, 8)

            Group {
                PolicyPicker("File Provider Presence", selection: $executable.policy.FileProviderPresence,
                           type: .allowDeny, helpText: services.allServices["FileProviderPresence"]?.userHelp)
                PolicyPicker("Listen Event", selection: $executable.policy.ListenEvent,
                           type: .standardUserAllowDeny, helpText: services.allServices["ListenEvent"]?.userHelp) {
                    checkBigSurCompatibility()
                }
                PolicyPicker("Media Library", selection: $executable.policy.MediaLibrary,
                           type: .allowDeny, helpText: services.allServices["MediaLibrary"]?.userHelp)
                PolicyPicker("Screen Capture", selection: $executable.policy.ScreenCapture,
                           type: .standardUserAllowDeny, helpText: services.allServices["ScreenCapture"]?.userHelp) {
                    checkBigSurCompatibility()
                }
                PolicyPicker("Speech Recognition", selection: $executable.policy.SpeechRecognition,
                           type: .allowDeny, helpText: services.allServices["SpeechRecognition"]?.userHelp)
            }

            Divider().padding(.vertical, 8)

            Group {
                PolicyPicker("Desktop Folder", selection: $executable.policy.SystemPolicyDesktopFolder,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyDesktopFolder"]?.userHelp)
                PolicyPicker("Documents Folder", selection: $executable.policy.SystemPolicyDocumentsFolder,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyDocumentsFolder"]?.userHelp)
                PolicyPicker("Downloads Folder", selection: $executable.policy.SystemPolicyDownloadsFolder,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyDownloadsFolder"]?.userHelp)
                PolicyPicker("Network Volumes", selection: $executable.policy.SystemPolicyNetworkVolumes,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyNetworkVolumes"]?.userHelp)
                PolicyPicker("Removable Volumes", selection: $executable.policy.SystemPolicyRemovableVolumes,
                           type: .allowDeny, helpText: services.allServices["SystemPolicyRemovableVolumes"]?.userHelp)
            }
        }
    }

    private func checkBigSurCompatibility() {
        if model.requiresAuthorizationKey() {
            model.usingLegacyAllowKey = false
        }
    }

    // MARK: - Apple Events

    private var appleEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Apple Events")
                    .font(.headline)

                Spacer()

                Button {
                    addAppleEvent()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add Apple Event target")
            }

            if executable.appleEvents.isEmpty {
                Text("No Apple Event rules configured")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                ForEach(executable.appleEvents) { rule in
                    AppleEventRow(rule: rule)
                }
                .onDelete { indexSet in
                    executable.appleEvents.remove(atOffsets: indexSet)
                }
            }
        }
    }

    private func addAppleEvent() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application, .unixExecutable, .bundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)

        if panel.runModal() == .OK, let url = panel.url {
            model.loadExecutable(url: url) { result in
                if case .success(let destination) = result {
                    let rule = AppleEventRule(source: executable, destination: destination, value: true)
                    if !executable.appleEvents.contains(rule) {
                        executable.appleEvents.append(rule)
                    }
                }
            }
        }
    }
}

#Preview {
    let exe = Executable(identifier: "com.apple.Safari", codeRequirement: "anchor apple")
    exe.displayName = "Safari"
    exe.iconPath = IconFilePath.application

    return PolicyDetailView(executable: exe, model: Model.shared)
        .frame(width: 500, height: 800)
}
