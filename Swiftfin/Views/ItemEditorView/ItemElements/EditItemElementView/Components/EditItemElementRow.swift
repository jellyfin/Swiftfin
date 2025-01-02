//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension EditItemElementView {

    struct EditItemElementRow: View {

        // MARK: - Enviroment Variables

        @Environment(\.isEditing)
        var isEditing
        @Environment(\.isSelected)
        var isSelected

        // MARK: - Metadata Variables

        let item: Element
        let type: ItemArrayElements

        // MARK: - Row Actions

        let onSelect: () -> Void
        let onDelete: () -> Void

        // MARK: - Body

        var body: some View {
            ListRow {
                if type == .people {
                    personImage
                }
            } content: {
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
                    Text(type.getName(for: item))
                        .foregroundStyle(
                            isEditing ? (isSelected ? .primary : .secondary) : .primary
                        )
                        .font(.headline)
                        .lineLimit(1)

                    if type == .people {
                        let person = (item as! BaseItemPerson)

                        TextPairView(
                            leading: person.type ?? .emptyDash,
                            trailing: person.role ?? .emptyDash
                        )
                        .foregroundStyle(
                            isEditing ? (isSelected ? .primary : .secondary) : .primary,
                            .secondary
                        )
                        .font(.subheadline)
                        .lineLimit(1)
                    }
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

        // MARK: - Person Image

        @ViewBuilder
        private var personImage: some View {
            let person = (item as! BaseItemPerson)

            ZStack {
                Color.clear

                ImageView(person.portraitImageSources(maxWidth: 30))
                    .failure {
                        SystemImageContentView(systemName: "person.fill")
                    }
            }
            .posterStyle(.portrait)
            .posterShadow()
            .frame(width: 30, height: 90)
            .padding(.horizontal)
        }
    }
}
