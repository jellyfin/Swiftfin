//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct SelectUserBottomBar: View {

        @Binding
        private var isEditing: Bool

        @Binding
        private var serverSelection: SelectUserServerSelection

        @ObservedObject
        private var viewModel: SelectUserViewModel

        private let areUsersSelected: Bool
        private let userCount: Int

        private let onDelete: () -> Void
        private let toggleAllUsersSelected: () -> Void

        // MARK: - Advanced Menu

        @ViewBuilder
        private var advancedMenu: some View {
            Menu(L10n.advanced, systemImage: "gearshape.fill") {

                Button(L10n.editUsers, systemImage: "person.crop.circle") {
                    isEditing.toggle()
                }

                // TODO: Do we want to support a grid view and list view like iOS?
//            if !viewModel.servers.isEmpty {
//                Picker(selection: $userListDisplayType) {
//                    ForEach(LibraryDisplayType.allCases, id: \.hashValue) {
//                        Label($0.displayTitle, systemImage: $0.systemImage)
//                            .tag($0)
//                    }
//                } label: {
//                    Text(L10n.layout)
//                    Text(userListDisplayType.displayTitle)
//                    Image(systemName: userListDisplayType.systemImage)
//                }
//                .pickerStyle(.menu)
//            }

                // TODO: Advanced settings on tvOS?
//            Section {
//                Button(L10n.advanced, systemImage: "gearshape.fill") {
//                    router.route(to: \.advancedSettings)
//                }
//            }
            }
            .labelStyle(.iconOnly)
        }

        private var deleteUsersButton: some View {
            Button {
                onDelete()
            } label: {
                ZStack {
                    Color.red

                    Text(L10n.delete)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(areUsersSelected ? .primary : .secondary)

                    if !areUsersSelected {
                        Color.black
                            .opacity(0.5)
                    }
                }
                .frame(width: 400, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!areUsersSelected)
            .buttonStyle(.card)
        }

        init(
            isEditing: Binding<Bool>,
            serverSelection: Binding<SelectUserServerSelection>,
            areUsersSelected: Bool,
            viewModel: SelectUserViewModel,
            userCount: Int,
            onDelete: @escaping () -> Void,
            toggleAllUsersSelected: @escaping () -> Void
        ) {
            self._isEditing = isEditing
            self._serverSelection = serverSelection
            self.viewModel = viewModel
            self.areUsersSelected = areUsersSelected
            self.userCount = userCount
            self.onDelete = onDelete
            self.toggleAllUsersSelected = toggleAllUsersSelected
        }

        @ViewBuilder
        private var contentView: some View {
            HStack(alignment: .center) {
                if isEditing {
                    deleteUsersButton

                    Button {
                        toggleAllUsersSelected()
                    } label: {
                        Text(areUsersSelected ? L10n.removeAll : L10n.selectAll)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }

                    Button {
                        isEditing = false
                    } label: {
                        L10n.cancel.text
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                } else {
                    ServerSelectionMenu(
                        selection: $serverSelection,
                        viewModel: viewModel
                    )

                    if userCount > 1 {
                        advancedMenu
                    }
                }
            }
        }

        var body: some View {
            // `Menu` with custom label has some weird additional
            // frame/padding that differs from default label style
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: 100)
            } content: {
                contentView
            }
        }
    }
}
