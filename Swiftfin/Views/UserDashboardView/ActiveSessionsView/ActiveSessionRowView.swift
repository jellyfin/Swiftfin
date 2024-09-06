//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Defaults
import JellyfinAPI
import SwiftUI

struct ActiveSessionRowView: View {
    @Default(.Customization.Library.posterType)
    private var posterType

    let session: SessionInfo

    @Binding
    var isAllExpanded: Bool
    @State
    private var isExpanded: Bool = false
    @State
    private var posterCache: [String: AnyView] = [:]

    var body: some View {
        VStack(alignment: .leading) {
            userSection
            contentView
                .transition(isExpanded ? .move(edge: .top) : .move(edge: .bottom))
        }
        .onAppear {
            isExpanded = isAllExpanded
        }
        .onChange(of: isAllExpanded) { newValue in
            isExpanded = newValue
        }
    }

    @ViewBuilder
    private var userSection: some View {
        Button(action: {
            isExpanded.toggle()
        }) {
            HStack {
                Text(session.userName ?? L10n.unknown)
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if session.nowPlayingItem != nil {
                playbackContent
            }

            if isExpanded {
                deviceDetails
                playbackDetails
                playbackTimeline
            } else if session.nowPlayingItem != nil {
                HStack {
                    playbackTimeline
                    Spacer()
                    playbackTimestamp
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private var playbackContent: some View {
        HStack(alignment: .top) {
            if let nowPlayingItem = session.nowPlayingItem {
                contentPoster(
                    item: nowPlayingItem,
                    type: posterType
                )
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            VStack(alignment: .leading) {
                if let nowPlayingItem = session.nowPlayingItem {
                    SessionDisplayNameView(item: nowPlayingItem)
                }
            }
        }
    }

    @ViewBuilder
    private var deviceDetails: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let deviceName = session.deviceName {
                    L10n.deviceWithString(String(deviceName)).text
                }
                if let clientName = session.client {
                    L10n.clientWithString(String(clientName)).text
                }
                if let version = session.applicationVersion {
                    L10n.versionWithString(String(version)).text
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            Spacer()
            playbackState
                .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private var playbackState: some View {
        let playState = session.playState
        if playState?.isPaused == true {
            L10n.paused.text
                .foregroundColor(.orange)
                .font(.headline)
        } else if playState?.mediaSourceID != nil {
            L10n.playing.text
                .foregroundColor(.green)
                .font(.headline)
        }
    }

    @ViewBuilder
    private var playbackDetails: some View {
        let displayPlayMethod = SessionPlaybackMethod.getDisplayPlayMethod(session)
        HStack {
            if displayPlayMethod != .unknown {
                Text(displayPlayMethod.displayTitle)
            }
            Spacer()
            playbackTimestamp
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var playbackTimestamp: some View {
        if let positionTicks = session.playState?.positionTicks,
           let totalTicks = session.nowPlayingItem?.runTimeTicks
        {
            let elapsedTime = formattedTime(Int64(positionTicks))
            let totalTime = formattedTime(Int64(totalTicks))
            Text("\(elapsedTime) / \(totalTime)")
        }
    }

    @ViewBuilder
    private var playbackTimeline: some View {
        if let progress = playbackProgress() {
            ZStack(alignment: .leading) {
                if let completionPercentage = session.transcodingInfo?.completionPercentage {
                    ProgressView(value: completionPercentage / 100.0)
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: .gray)
                        )
                        .scaleEffect(x: 1, y: 2)
                }
                ProgressView(value: progress)
                    .progressViewStyle(
                        LinearProgressViewStyle(tint: session.playState?.isPaused ?? false ? .orange : .green)
                    )
                    .scaleEffect(x: 1, y: 2)
            }
            .frame(height: 6)
        }
    }

    private func formattedTime(_ ticks: Int64) -> String {
        let seconds = ticks / 10_000_000
        return seconds.timeLabel
    }

    private func playbackProgress() -> Double? {
        guard let positionTicks = session.playState?.positionTicks,
              let totalTicks = session.nowPlayingItem?.runTimeTicks,
              totalTicks > 0
        else {
            return nil
        }
        return Double(positionTicks) / Double(totalTicks)
    }

    private func contentPoster(item: BaseItemDto, type: PosterDisplayType) -> AnyView {
        var contentWidth: CGFloat
        var imageSource: ImageSource?
        var output: AnyView

        switch type {
        case .portrait:
            contentWidth = 50
            imageSource = item.portraitImageSources().randomElement()
        case .landscape:
            contentWidth = 133
            imageSource = item.landscapeImageSources().randomElement()
        }

        if let cachedPoster = posterCache[item.id] {
            output = cachedPoster
        } else {
            output = AnyView(
                AsyncImage(url: imageSource?.url) { phase in
                    switch phase {
                    case .empty:
                        if let blurHash = item.blurHash(ImageType.primary) {
                            BlurHashView(blurHash: blurHash, size: CGSize(width: contentWidth, height: 75))
                                .frame(width: contentWidth, height: 75)
                        } else {
                            Color.secondarySystemFill
                                .opacity(0.75)
                                .frame(width: contentWidth, height: 75)
                        }
                    case let .success(image):
                        image
                            .resizable()
                            .frame(width: contentWidth, height: 75)
                    case .failure:
                        Color.secondarySystemFill
                            .opacity(0.75)
                            .frame(width: contentWidth, height: 75)
                    @unknown default:
                        EmptyView()
                    }
                }
            )

            Task {
                await MainActor.run {
                    self.posterCache[item.id!] = output
                }
            }
        }
        return output
    }
}
