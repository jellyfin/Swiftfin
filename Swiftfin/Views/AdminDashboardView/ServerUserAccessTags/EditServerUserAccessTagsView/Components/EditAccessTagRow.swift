//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension EditServerUserAccessTagsView {

    struct EditAccessTagRow: View {

        // MARK: - Enviroment Variables

        @Environment(\.isEditing)
        var isEditing
        @Environment(\.isSelected)
        var isSelected

        // MARK: - Metadata Variables

        let item: String
        let access: Bool

        // MARK: - Row Actions

        let onSelect: () -> Void
        let onDelete: () -> Void

        // MARK: - Body

        var body: some View {
            ListRow {} content: {
                rowContent
            }
            .onSelect(perform: onSelect)
            .isSeparatorVisible(false)
            .swipeActions {
                Button(L10n.delete, systemImage: "trash", action: onDelete)
                    .tint(.red)
            }
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    TextPairView(
                        leading: item,
                        trailing: access ? "Allowed" : "Blocked"
                    )
                    .foregroundStyle(
                        isEditing ? (isSelected ? .primary : .secondary) : .primary
                    )
                    .font(.headline)
                }

                if isEditing {
                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
            }
        }
    }
}
