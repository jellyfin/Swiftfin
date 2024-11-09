//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension EditPeopleView {

    struct EditPeopleRow: View {

        @Default(.accentColor)
        private var accentColor

        // MARK: - Environment Variables

        @Environment(\.colorScheme)
        private var colorScheme
        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let person: BaseItemPerson

        // MARK: - Actions

        private let onSelect: () -> Void
        private let onDelete: () -> Void

        // MARK: - Initializer

        init(
            person: BaseItemPerson,
            onSelect: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.person = person
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        // MARK: - Label Styling

        private var labelForegroundStyle: some ShapeStyle {
            isEditing ? (isSelected ? .primary : .secondary) : .primary
        }

        // MARK: - Person Image View

        @ViewBuilder
        private var personImage: some View {
            ZStack {
                ImageView(person.portraitImageSources())
                    .pipeline(.Swiftfin.branding)
                    .placeholder { _ in
                        SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                    }
                    .failure {
                        SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                    }
                    .posterStyle(.portrait)

                if isEditing {
                    Color.black
                        .opacity(isSelected ? 0 : 0.5)
                }
            }
            .posterShadow()
            .frame(width: 60, height: 90)
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            let personType = PersonKind(rawValue: person.type ?? "")
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(person.name ?? L10n.unknown)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    TextPairView(
                        L10n.type,
                        value: Text(personType?.displayTitle ?? L10n.unknown)
                    )

                    TextPairView(
                        L10n.role,
                        value: Text(personType == .actor ? person.role ?? L10n.unknown : .emptyDash)
                    )
                    .lineLimit(2)
                }
                .font(.subheadline)
                .foregroundStyle(labelForegroundStyle, .secondary)

                Spacer()

                if isEditing, isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(accentColor.overlayColor, accentColor)
                } else if isEditing {
                    Image(systemName: "circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                personImage
            } content: {
                rowContent
                    .padding(.vertical, 24)
            }
            .onSelect(perform: onSelect)
            .swipeActions {
                Button(
                    L10n.delete,
                    systemImage: "trash",
                    action: onDelete
                )
                .tint(.red)
            }
        }
    }
}
