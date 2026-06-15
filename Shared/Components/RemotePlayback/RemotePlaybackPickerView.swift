//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct RemotePlaybackPickerView: View {

    @Default(.accentColor)
    private var accentColor
    @Default(.VideoPlayer.mediaPlaybackStrategy)
    private var mediaPlaybackStrategy

    @Router
    private var router

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @State
    private var presentRoutePicker: Bool = false

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private var castableSessions: [SessionInfoDto] {
        viewModel.sessions.values
            .compactMap(\.value)
            .filter {
                $0.isSupportsRemoteControl ?? false
            }
    }

    private func isCasting(to session: SessionInfoDto) -> Bool {
        guard let active = manager.remote.activeSession, active.route == .jellyfin else { return false }
        return active.deviceName == (session.deviceName ?? session.client)
    }

    private func toggleCast(to session: SessionInfoDto) {
        if isCasting(to: session) {
            manager.remote.end(route: .jellyfin)
        } else {
            Task { await manager.remote.select(JellyfinPlaybackSession(session: session)) }
        }

        router.dismiss()
    }

    private var isAirPlayAvailable: Bool {
        mediaPlaybackStrategy != .player(.vlc)
    }

    private var hasNoTargets: Bool {
        !isAirPlayAvailable && castableSessions.isEmpty
    }

    var body: some View {
        List {
            FormItemSection(item: manager.item)

            if isAirPlayAvailable {
                Section {
                    airPlayRow
                }
            }

            if castableSessions.isNotEmpty {
                Section(L10n.devices) {
                    ForEach(castableSessions, id: \.id) { session in
                        sessionRow(session)
                    }
                }
            }

            if hasNoTargets {
                Section {
                    // swiftlint:disable:next hard_coded_display_string
                    Text("No valid targets")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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

    private var isAirPlaying: Bool {
        manager.remote.state?.type == .airPlay
    }

    private var airPlayRow: some View {
        ListRow {
            Image(systemName: "airplayvideo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
                .frame(width: 60, height: 60)
                .foregroundStyle(isAirPlaying ? AnyShapeStyle(accentColor) : AnyShapeStyle(.primary))
        } content: {
            HStack {
                // swiftlint:disable:next hard_coded_display_string
                Text("\(L10n.airPlay) & \(L10n.bluetooth)")
                    .font(.headline)

                Spacer()

                ListRowCheckbox()
            }
        } action: {
            presentRoutePicker = true
        }
        .isSeparatorVisible(false)
        .isSelected(isAirPlaying)
        .background {
            PlaybackRoutePickerView(present: $presentRoutePicker) {
                router.dismiss()
            }
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
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
            .isEditing(true)
            .isSelected(isCasting(to: session))
        } action: {
            toggleCast(to: session)
        }
        .isSeparatorVisible(false)
    }
}
