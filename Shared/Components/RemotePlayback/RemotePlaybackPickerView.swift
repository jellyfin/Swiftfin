//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct RemotePlaybackPickerView: View {

    @Router
    private var router

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private var castableSessions: [SessionInfoDto] {
        viewModel.sessions.values
            .compactMap(\.value)
            .filter {
                $0.isSupportsRemoteControl ?? false
            }
    }

    var body: some View {
        List {
            FormItemSection(item: manager.item)

            Section {
                airPlayRow
            }

            if castableSessions.isNotEmpty {
                Section(L10n.devices) {
                    ForEach(castableSessions, id: \.id) { session in
                        sessionRow(session)
                    }
                }
            }
        }
        .navigationTitle(L10n.output)
        .navigationBarTitleDisplayMode(.inline)
        .if(UIDevice.isPhone) { view in
            view
                .presentationDetents([.medium, .large])
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
    }

    private var airPlayRow: some View {
        ListRow {
            Image(systemName: "airplayvideo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
                .frame(width: 60, height: 60)
        } content: {
            // swiftlint:disable:next hard_coded_display_string
            Text("\(L10n.airPlay) & \(L10n.bluetooth)")
                .font(.headline)
        }
        .isSeparatorVisible(false)
        .overlay {
            PlaybackRoutePickerView()
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: SessionInfoDto) -> some View {
        ListRow {
            ZStack {
                session.device.clientColor

                Image(session.device.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            }
            .posterStyle(.square)
            .frame(width: 60, height: 60)
            .posterShadow()
        } content: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    Text(session.userName ?? L10n.unknown)
                        .font(.headline)

                    if let client = session.client {
                        LabeledContent(
                            L10n.client,
                            value: client
                        )
                    }

                    if let device = session.deviceName {
                        LabeledContent(
                            L10n.device,
                            value: device
                        )
                    }
                }
                .font(.subheadline)

                Spacer()

                ListRowCheckbox()
            }
            // TODO: Hook up when we can track if we're casting to something
            .isEditing(false)
            .isSelected(false)
        }
        .isSeparatorVisible(false)
    }
}
