//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// This standalone style sample intentionally uses fixed English labels.
// swiftlint:disable hard_coded_display_string

import SwiftUI

@main
struct CapsuleStylesApp: App {

    var body: some Scene {
        WindowGroup {
            CapsuleStylesScreen()
                .preferredColorScheme(.dark)
        }
    }
}

private struct CapsuleStylesScreen: View {

    @State
    private var selectedSizes: Set<String> = []
    @State
    private var isSelected = true
    @State
    private var isInactiveSelected = true
    @State
    private var isTintedSelected = false

    private let sizes: [(String, ControlSize)] = [
        ("Mini", .mini),
        ("Small", .small),
        ("Regular", .regular),
        ("Large", .large),
        ("Extra large", .extraLarge),
    ]

    @ContentBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Capsule styles")
                    .font(.system(size: 44, weight: .bold))
                Text("Move up or down to focus. Press Select to toggle selection.")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            ForEach(sizes, id: \.0) { title, size in
                Button {
                    if !selectedSizes.insert(title).inserted {
                        selectedSizes.remove(title)
                    }
                } label: {
                    Label(title, systemImage: "play.fill")
                }
                .buttonStyle(.capsule)
                .controlSize(size)
                .environment(\.isSelected, selectedSizes.contains(title))
            }

            Button {
                isSelected.toggle()
            } label: {
                Label("Selected · purple", systemImage: "checkmark")
            }
            .buttonStyle(.capsule(selectionTint: .purple))
            .environment(\.isSelected, isSelected)

            Button {
                isInactiveSelected.toggle()
            } label: {
                Label("Inactive selection", systemImage: "checkmark")
            }
            .buttonStyle(.capsule(selectionTint: .purple, isSelectionActive: false))
            .environment(\.isSelected, isInactiveSelected)

            Button {
                isTintedSelected.toggle()
            } label: {
                Label("Custom focus · mint", systemImage: "sparkles")
            }
            .buttonStyle(.capsule(selectionTint: .purple, focusTint: .mint))
            .environment(\.isSelected, isTintedSelected)

            Button {} label: {
                Label("Disabled", systemImage: "lock.fill")
            }
            .buttonStyle(.capsule)
            .disabled(true)
        }
        .labelStyle(.leadingIcon)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(64)
        .background {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.12, blue: 0.24), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
