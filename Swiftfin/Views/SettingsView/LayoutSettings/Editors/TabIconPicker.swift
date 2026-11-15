//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TabIconPicker: View {

    @AppTheme
    private var theme

    @Environment(\.dismiss)
    private var dismiss

    @Binding
    private var selection: String

    @State
    private var draftSelection: String

    init(selection: Binding<String>) {
        _selection = selection
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    private var choices: [TabIcon] {
        guard !TabIcon.choices.contains(where: { $0.systemImage == selection }) else { return TabIcon.choices }

        return [.init(title: L10n.userView, systemImage: selection)] + TabIcon.choices
    }

    private var selectedIcon: TabIcon {
        choices.first { $0.systemImage == draftSelection } ?? .init(title: L10n.icon, systemImage: draftSelection)
    }

    private func confirmSelection() {
        selection = draftSelection
        dismiss()
    }

    @ContentBuilder
    private var confirmButton: some View {
        if #available(iOS 26, *) {
            Button(role: .confirm, action: confirmSelection)
        } else {
            Button(L10n.confirm, systemImage: "checkmark", action: confirmSelection)
                .labelStyle(.iconOnly)
                .backport
                .buttonStyle(.glassProminent)
                .controlSize(.small)
        }
    }

    @ContentBuilder
    private var preview: some View {
        Image(systemName: selectedIcon.systemImage)
            .font(.system(size: 34, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(theme.accentColor)
            .frame(width: 72, height: 72)
            .background(Color(uiColor: .tertiarySystemFill), in: Circle())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .accessibilityLabel(L10n.icon)
            .accessibilityValue(selectedIcon.title)
    }

    @ContentBuilder
    private func iconButton(_ icon: TabIcon) -> some View {
        let isSelected = draftSelection == icon.systemImage

        Button {
            draftSelection = icon.systemImage
        } label: {
            Image(systemName: icon.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(isSelected ? theme.accentColor : Color.primary)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? theme.accentColor : .clear, lineWidth: 2)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityRemoveTraits(isSelected ? [] : .isSelected)
    }

    @ContentBuilder
    var body: some View {
        NavigationStack {
            List {
                Section {
                    preview
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 16) {
                        ForEach(choices) { iconButton($0) }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.icon)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton { dismiss() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    confirmButton
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
