//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemSubtitlesView {

    struct SubtitleButton: View {

        // MARK: - Environment Variables

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Subtitle Variables

        private let subtitle: MediaStream

        // MARK: - Row Actions

        private let action: () -> Void
        private let deleteAction: (() -> Void)?

        // MARK: - Body

        var body: some View {
            ListRow {} content: {
                rowContent
            }
            .onSelect(perform: action)
            .isSeparatorVisible(false)
            .ifLet(deleteAction) { button, deleteAction in
                button
                    .swipeActions {
                        Button(
                            L10n.delete,
                            systemImage: "trash",
                            action: deleteAction
                        )
                        .tint(.red)
                    }
            }
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                Text(subtitle.displayTitle ?? L10n.unknown)
                    .foregroundStyle(isEditing && !isSelected ? .secondary : .primary)

                Spacer()

                ListRowCheckbox()
            }
        }
    }
}

extension ItemSubtitlesView.SubtitleButton {

    // MARK: - Initialize

    init(
        _ subtitle: MediaStream,
        action: @escaping () -> Void,
        deleteAction: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.action = action
        self.deleteAction = deleteAction
    }

    // MARK: - Initialize without Delete Action

    init(_ subtitle: MediaStream, action: @escaping () -> Void) {
        self.subtitle = subtitle
        self.action = action
        self.deleteAction = nil
    }
}
