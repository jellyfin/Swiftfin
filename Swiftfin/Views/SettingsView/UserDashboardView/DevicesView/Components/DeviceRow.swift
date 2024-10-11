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

        // MARK: - Device Mapping

        private var device: DeviceInfo {
            box.value ?? .init()
        }

        // MARK: - Initializer

        init(
            box: BindingBox<DeviceInfo?>,
            onSelect editAction: @escaping () -> Void,
            onDelete deleteAction: @escaping () -> Void
        ) {
            self.box = box
            self.onSelect = editAction
            self.onDelete = deleteAction
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                rowLeading
            } content: {
                deviceDetails
            }
            .onSelect(perform: onSelect)
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
            ZStack {
                DeviceType(
                    client: device.appName,
                    deviceName: device.name
                ).clientColor

                Image(DeviceType(
                    client: device.appName,
                    deviceName: device.name
                ).systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
            }
            .posterStyle(.portrait)
            .frame(width: 60)
            .posterShadow()
            .padding(.vertical, 8)
        }

        // MARK: - Row Device Details

        @ViewBuilder
        private var deviceDetails: some View {
            VStack(alignment: .leading) {
                // TODO: Change t0 (CustomName ?? DeviceName) when available
                Text(device.name ?? L10n.unknown)
                    .font(.headline)

                Text(device.lastUserName ?? L10n.unknown)

                TextPairView(
                    leading: device.appName ?? L10n.unknown,
                    trailing: device.appVersion ?? .emptyDash
                )

                TextPairView(
                    L10n.lastSeen,
                    value: {
                        if let dateLastActivity = device.dateLastActivity {
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
