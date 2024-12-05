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

        let item: Element
        let type: ItemArrayElements
        let onSelect: () -> Void
        let onDelete: () -> Void

        var body: some View {
            ListRow(insets: .init()) {
                if type == .people {
                    let person = (item as! BaseItemPerson)

                    ZStack {
                        Color.clear
                        ImageView(person.portraitImageSources(maxWidth: 30))
                            .failure {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.primary)
                            }
                    }
                    .posterStyle(.portrait)
                    .frame(width: 30, height: 90)
                    .padding(.horizontal)
                }
            } content: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(type.getName(for: item))
                            .foregroundColor(isEditing ? (isSelected ? .primary : .secondary) : .primary)
                            .font(.headline)
                            .lineLimit(1)

                        if type == .people {
                            let person = (item as! BaseItemPerson)

                            TextPairView(
                                leading: person.type ?? .emptyDash,
                                trailing: person.role ?? .emptyDash
                            )
                            .foregroundColor(isEditing ? (isSelected ? .primary : .secondary) : .primary)
                            .font(.subheadline)
                            .lineLimit(1)
                        }
                    }

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
