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

extension EditGenreView {

    struct EditGenreRow: View {

        @Default(.accentColor)
        private var accentColor

        // MARK: - Environment Variables

        @Environment(\.colorScheme)
        private var colorScheme
        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let genre: String

        // MARK: - Actions

        private let onSelect: () -> Void
        private let onDelete: () -> Void

        // MARK: - Initializer

        init(
            genre: String,
            onSelect: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.genre = genre
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        // MARK: - Label Styling

        private var labelForegroundStyle: some ShapeStyle {
            isEditing ? (isSelected ? .primary : .secondary) : .primary
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(genre)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(labelForegroundStyle as? Color)
                }

                Spacer()

                if isEditing {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                    } else {
                        Image(systemName: "circle")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {}
                content: {
                    rowContent
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
