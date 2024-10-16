//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension DevicesView {
    struct DeviceRow: View {

        @CurrentDate
        private var currentDate: Date

        @ObservedObject
        private var box: BindingBox<DeviceInfo?>

        let onSelect: () -> Void
        let onDelete: () -> Void

        @Binding
        var selectMode: Bool
        @Binding
        var selected: Bool

        // MARK: - Device Mapping

        private var deviceInfo: DeviceInfo {
            box.value ?? .init()
        }

        // MARK: - Initializer

        init(
            box: BindingBox<DeviceInfo?>,
            onSelect editAction: @escaping () -> Void,
            onDelete deleteAction: @escaping () -> Void,
            selectMode: Binding<Bool>,
            selected: Binding<Bool>
        ) {
            self.box = box
            self.onSelect = editAction
            self.onDelete = deleteAction
            self._selectMode = selectMode
            self._selected = selected
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: 0)) {
                rowLeading
            } content: {
                deviceDetails
            }
            .onSelect {
                if selectMode {
                    selected.toggle()
                } else {
                    onSelect()
                }
            }
            .swipeActions {
                Button {
                    onDelete()
                } label: {
                    Label(L10n.delete, systemImage: "trash")
                }
                .tint(.red)
            }
        }

        // MARK: - Row Leading Image

        @ViewBuilder
        private var rowLeading: some View {
            HStack {
                if selectMode {
                    Button(action: {
                        selected.toggle()
                    }) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 24, height: 24)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .padding(.leading, 0)
                    .padding(.trailing, 8)
                    .buttonStyle(PlainButtonStyle())
                }

                ZStack {
                    deviceInfo.device.clientColor

                    Image(deviceInfo.device.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40)
                }
                .squarePosterStyle()
                .frame(width: 60, height: 60)
                .padding(.vertical, 8)
            }
        }

        // MARK: - Row Device Details

        @ViewBuilder
        private var deviceDetails: some View {
            VStack(alignment: .leading) {
                // TODO: Change to (CustomName ?? DeviceName) when available
                Text(deviceInfo.name ?? L10n.unknown)
                    .font(.headline)

                Text(deviceInfo.lastUserName ?? L10n.unknown)

                TextPairView(
                    leading: deviceInfo.appName ?? L10n.unknown,
                    trailing: deviceInfo.appVersion ?? .emptyDash
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
            .font(.subheadline)
        }
    }
}
