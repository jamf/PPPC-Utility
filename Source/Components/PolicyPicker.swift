//
//  PolicyPicker.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

/// The type of permission options available for a policy
enum PolicyPickerType {
    case allowDeny
    case denyOnly
    case standardUserAllowDeny
}

/// A reusable picker for TCC policy permissions
struct PolicyPicker: View {
    let label: String
    @Binding var selection: String
    let type: PolicyPickerType
    let helpText: String?
    let onSelectionChange: (() -> Void)?

    init(
        _ label: String,
        selection: Binding<String>,
        type: PolicyPickerType = .allowDeny,
        helpText: String? = nil,
        onSelectionChange: (() -> Void)? = nil
    ) {
        self.label = label
        self._selection = selection
        self.type = type
        self.helpText = helpText
        self.onSelectionChange = onSelectionChange
    }

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)

            Picker("", selection: $selection) {
                Text("-").tag("-")
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .frame(width: 200)
            .onChange(of: selection) {
                onSelectionChange?()
            }

            if let helpText = helpText {
                HelpButton(helpText: helpText)
            }

            Spacer()
        }
    }

    private var options: [String] {
        switch type {
        case .allowDeny:
            return [
                TCCProfileDisplayValue.allow.rawValue,
                TCCProfileDisplayValue.deny.rawValue
            ]
        case .denyOnly:
            return [
                TCCProfileDisplayValue.deny.rawValue
            ]
        case .standardUserAllowDeny:
            return [
                TCCProfileDisplayValue.allowStandardUsersToApprove.rawValue,
                TCCProfileDisplayValue.deny.rawValue
            ]
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PolicyPicker("Address Book", selection: .constant("-"), type: .allowDeny, helpText: "Access to contacts")
        PolicyPicker("Camera", selection: .constant("Deny"), type: .denyOnly, helpText: "Camera access")
        PolicyPicker("Screen Capture", selection: .constant("-"), type: .standardUserAllowDeny)
    }
    .padding()
}
