//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension DevicesView {

    struct DeviceRow: View {

        @Default(.accentColor)
        private var accentColor

        // MARK: - Environment Variables

        @Environment(\.colorScheme)
        private var colorScheme
        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        @CurrentDate
        private var currentDate: Date

        // MARK: - Properties

        let device: DeviceInfoDto
        let onSelect: () -> Void
        let onDelete: (() -> Void)?

        // MARK: - Initializer

        init(
            device: DeviceInfoDto,
            onSelect: @escaping () -> Void,
            onDelete: (() -> Void)? = nil
        ) {
            self.device = device
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        // MARK: - Label Styling

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else { return .primary }
            return isSelected ? .primary : .secondary
        }

        // MARK: - Device Image View

        @ViewBuilder
        private var deviceImage: some View {
            ZStack {
                device.type.clientColor

                Image(device.type.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)

                if isEditing {
                    Color.black
                        .opacity(isSelected ? 0 : 0.5)
                }
            }
            .squarePosterStyle()
            .posterShadow()
            .frame(width: 60, height: 60)
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.customName ?? device.name ?? L10n.unknown)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    LabeledContent(
                        L10n.user,
                        value: device.lastUserName ?? L10n.unknown
                    )
                    .lineLimit(1)

                    LabeledContent(
                        L10n.client,
                        value: device.appName ?? L10n.unknown
                    )
                    .lineLimit(1)

                    LabeledContent(L10n.lastSeen, value: device.dateLastActivity, format: .lastSeen)
                        .id(currentDate)
                        .lineLimit(1)
                        .monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(labelForegroundStyle, .secondary)

                Spacer()

                ListRowCheckbox()
            }
        }

        // MARK: - Body

        var body: some View {
            ListRow {
                deviceImage
            } content: {
                rowContent
            }
            .onSelect(perform: onSelect)
            .isSeparatorVisible(false)
            .swipeActions {
                if let onDelete = onDelete {
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
}
