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

extension DevicesView {
    struct DeviceRow: View {
        @CurrentDate
        private var currentDate: Date

        private let accentColor = Defaults[.accentColor]

        // MARK: - Environment Variables

        @Environment(\.colorScheme)
        private var colorScheme

        // MARK: - Binding Variables

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Observed Objects

        @ObservedObject
        private var box: BindingBox<DeviceInfo?>

        // MARK: - Actions

        private let onSelect: () -> Void
        private let onDelete: () -> Void

        // MARK: - Device Mapping

        private var deviceInfo: DeviceInfo {
            box.value ?? .init()
        }

        // MARK: - Initializer

        init(
            box: BindingBox<DeviceInfo?>,
            onSelect: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.box = box
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
                deviceInfo.device.clientColor

                Image(deviceInfo.device.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)

                if isEditing {
                    Color.black
                        .opacity(isSelected ? 0 : 0.5)
                }
            }
            .squarePosterStyle()
            .frame(width: 60, height: 60)
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {

                VStack(alignment: .leading, spacing: 5) {
                    Text(deviceInfo.name ?? L10n.unknown)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(labelForegroundStyle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(deviceInfo.lastUserName ?? L10n.never)
                        .fontWeight(.semibold)
                        .foregroundStyle(labelForegroundStyle)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    TextPairView(
                        deviceInfo.appName ?? L10n.unknown,
                        value: Text(deviceInfo.appVersion ?? .emptyDash)
                    )

                    TextPairView(
                        L10n.lastSeen,
                        value: {
                            if let dateLastActivity = deviceInfo.dateLastActivity {
                                Text(dateLastActivity, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                            } else {
                                Text(L10n.never)
                            }
                        }()
                    )
                    .id(currentDate)
                    .monospacedDigit()
                }

                Spacer()

                if isEditing, isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .backport
                        .fontWeight(.bold)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(accentColor.overlayColor, accentColor)

                } else if isEditing {
                    Image(systemName: "circle")
                        .resizable()
                        .backport
                        .fontWeight(.bold)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: 8)) {
                deviceImage
                    .padding(.trailing, 8)
            } content: {
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
