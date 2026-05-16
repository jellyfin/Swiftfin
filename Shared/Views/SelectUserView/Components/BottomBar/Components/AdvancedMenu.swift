//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SelectUserView {

    struct AdvancedMenu: View {

        @Default(.selectUserDisplayType)
        private var userListDisplayType
        @Default(.selectUserSortOrder)
        private var userSortOrder

        @Router
        private var router

        let hasUsers: Bool
        let isEditing: Binding<Bool>

        var body: some View {
            if hasUsers {
                Toggle(
                    L10n.editUsers,
                    systemImage: "person.crop.circle",
                    isOn: isEditing
                )
            }

            Picker(selection: $userListDisplayType) {
                ForEach(LibraryDisplayType.allCases, id: \.hashValue) {
                    Label($0.displayTitle, systemImage: $0.systemImage)
                        .tag($0)
                }
            } label: {
                Text(L10n.layout)
                Text(userListDisplayType.displayTitle)
                Image(systemName: userListDisplayType.systemImage)
            }
            .pickerStyle(.menu)

            Picker(selection: $userSortOrder) {
                ForEach(SelectUserSortOrder.allCases, id: \.hashValue) {
                    Label($0.displayTitle, systemImage: $0.systemImage)
                        .tag($0)
                }
            } label: {
                Text(L10n.sort)
                Text(userSortOrder.displayTitle)
                Image(systemName: userSortOrder.systemImage)
            }
            .pickerStyle(.menu)

            Section {
                Button(L10n.advanced, systemImage: "gearshape.fill") {
                    router.route(to: .appSettings)
                }
            }
        }
    }
}
