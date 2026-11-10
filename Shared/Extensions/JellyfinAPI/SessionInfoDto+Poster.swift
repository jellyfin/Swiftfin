//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

extension SessionInfoDto: Poster {

    typealias Environment = BaseItemDto.Environment

    var displayTitle: String {
        userName ?? L10n.unknown
    }

    var subtitle: String? {
        nowPlayingItem?.displayTitle ?? deviceName
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .landscape
    }

    var systemImage: String {
        nowPlayingItem?.systemImage ?? "person.fill"
    }

    var posterLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayTitle)
                .font(.footnote)
                .lineLimit(1, reservesSpace: true)

            Text(subtitle ?? .emptyDash)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var posterContextMenu: some View {
        SessionPosterContextMenu(session: self)
    }

    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        SessionPosterOverlay(session: self, displayType: displayType)
    }

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Environment
    ) -> [ImageSource] {
        guard let nowPlayingItem,
              displayType != .square || nowPlayingItem.type?.preferredPosterDisplayType == .square
        else { return [] }

        return nowPlayingItem.imageSources(for: displayType, environment: environment)
    }
}

private struct SessionPosterContextMenu: View {

    @Router
    private var router

    let session: SessionInfoDto

    private var isPaused: Bool {
        session.playState?.isPaused == true
    }

    private var canControl: Bool {
        guard let user = Container.shared.currentUserSession()?.userData else { return false }

        return user.policy?.enableRemoteControlOfOtherUsers == true
            || session.userID == nil
            || session.userID == user.id
            || session.additionalUsers?.contains { $0.userID == user.id } == true
    }

    var body: some View {
        if let itemID = session.nowPlayingItem?.id {
            Button(L10n.goToItem, systemImage: "info.circle") {
                router.route(to: .item(id: itemID))
            }
        }

        if canControl, session.isSupportsMediaControl == true, session.nowPlayingItem != nil {
            Button(isPaused ? L10n.play : L10n.pause, systemImage: isPaused ? "play.fill" : "pause.fill") {
                Task {
                    await sendPlaystateCommand(isPaused ? .unpause : .pause)
                }
            }

            Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                Task {
                    await sendPlaystateCommand(.stop)
                }
            }
        }
    }

    @MainActor
    private func sendPlaystateCommand(_ command: PlaystateCommand) async {
        guard let userSession = Container.shared.currentUserSession(), let id = session.id else { return }

        do {
            try await userSession.client.send(Paths.sendPlaystateCommand(sessionID: id, command: command.rawValue))
        } catch {
            userSession.itemActionErrors.send(error)
        }
    }
}

private struct SessionPosterOverlay: View {

    @AppTheme
    private var theme

    let session: SessionInfoDto
    let displayType: PosterDisplayType

    @ArrayBuilder<QuadrantItem>
    private func indicators(_ playState: PlayerStateInfo) -> [QuadrantItem] {
        if playState.playMethod == .transcode, let transcodeReasons = session.transcodingInfo?.transcodeReasons {
            for systemImage in Set(transcodeReasons.map(\.systemImage)).sorted() {
                QuadrantItem(color: .orange) {
                    Text(Image(systemName: systemImage))
                }
            }
        }
    }

    var body: some View {
        if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
            VStack(spacing: 0) {
                Quadrant(.topTrailing) {
                    QuadrantItem(color: theme.accentColor) {
                        Text(Image(systemName: playState.isPaused == true ? "pause.fill" : "play.fill"))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                ProgressIndicator(
                    title: (playState.position ?? .zero).formatted(.runtime),
                    progress: Double(playState.positionTicks ?? 0) / Double(nowPlayingItem.runTimeTicks ?? 1),
                    posterDisplayType: displayType
                ) {
                    indicators(playState)
                }
            }
            .posterCornerRadius(displayType)
        } else if session.nowPlayingItem == nil {
            ZStack {
                session.device.clientColor

                ContainerRelativeView(ratio: 0.6) {
                    Image(session.device.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
    }
}
