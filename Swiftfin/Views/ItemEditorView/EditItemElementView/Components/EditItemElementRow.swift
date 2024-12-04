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

extension EditItemElementView {

    struct EditItemElementRow: View {

        @Environment(\.isEditing)
        var isEditing
        @Environment(\.isSelected)
        var isSelected

        private let item: Element

        private let displayName: String

        private let onSelect: () -> Void
        private let onDelete: () -> Void

        init(item: Element, type: ItemElementType, onSelect: @escaping () -> Void, onDelete: @escaping () -> Void) {
            self.item = item
            self.onSelect = onSelect
            self.onDelete = onDelete

            switch type {
            case .tags, .genres:
                self.displayName = item as! String
            case .studios:
                self.displayName = (item as! NameGuidPair).name ?? L10n.unknown
            case .people:
                self.displayName = (item as! BaseItemPerson).name ?? L10n.unknown
            }
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {} content: {
                HStack {
                    Text(displayName)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(isEditing ? (isSelected ? .primary : .secondary) : .primary)

                    Spacer()

                    if isEditing {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    }
                }
            }
            .onSelect(perform: onSelect)
            .swipeActions {
                Button(L10n.delete, systemImage: "trash", action: onDelete)
                    .tint(.red)
            }
            .listRowSeparator(.hidden)
        }
    }
}
