//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

        // MARK: - Environment Variable

        @Environment(\.colorScheme)
        private var colorScheme

        // MARK: - Advanced Menu

        @ViewBuilder
        private var advancedMenu: some View {
            Menu(L10n.advanced, systemImage: "gearshape.fill") {

//                if userCount > 1 { // TODO: conditional prevents menu from working?
                Button(L10n.editUsers, systemImage: "person.crop.circle") {
                    isEditing.toggle()
                }
//                }

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
                Text(L10n.delete)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(areUsersSelected ? .primary : .secondary)
            }
            .disabled(!areUsersSelected)
        }

        init(
            isEditing: Binding<Bool>,
            serverSelection: Binding<SelectUserServerSelection>,
            areUsersSelected: Bool,
            viewModel: SelectUserViewModel,
            userCount: Int,
            onDelete: @escaping () -> Void
        ) {
            self._isEditing = isEditing
            self._serverSelection = serverSelection
            self.viewModel = viewModel
            self.areUsersSelected = areUsersSelected
            self.userCount = userCount
            self.onDelete = onDelete
        }

        var body: some View {
            HStack(alignment: .center) {
                if isEditing {
                    Group {
                        deleteUsersButton

                        Button {
                            isEditing = false
                        } label: {
                            L10n.cancel.text
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.bottom, 50)
                } else {
                    ServerSelectionMenu(
                        selection: $serverSelection,
                        viewModel: viewModel
                    )
                    .padding(.bottom, 50)

                    advancedMenu
                }
            }
        }
    }
}
