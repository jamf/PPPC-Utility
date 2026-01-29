//
//  HelpButton.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

/// A help button that shows a popover with explanatory text
struct HelpButton: View {
    let helpText: String
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            Text(helpText)
                .padding()
                .frame(maxWidth: 300)
        }
        .help("Click for more information")
    }
}

#Preview {
    HelpButton(helpText: "This is helpful information about the feature.\n\nMDM Key: AddressBook\nRelated entitlements: com.apple.security.personal-information.addressbook")
        .padding()
}
