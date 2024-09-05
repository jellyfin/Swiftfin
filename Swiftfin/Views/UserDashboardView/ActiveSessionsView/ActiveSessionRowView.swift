//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ActiveSessionRowView: View {
    @State
    private var isExpanded: Bool = false

    let session: SessionInfo

    var body: some View {
        VStack(alignment: .leading) {
            userSection
            VStack(alignment: .leading, spacing: 8) {
                if isExpanded {
                    expandedPlaybackSection
                        .transition(.move(edge: .top))
                } else {
                    collapsedPlaybackSection
                        .transition(.move(edge: .bottom))
                }
            }
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
    private var collapsedPlaybackSection: some View {
        if let nowPlayingItem = session.nowPlayingItem {
            VStack(alignment: .leading, spacing: 4) {
                Text(nowPlayingItem.name ?? "Unknown")
                    .font(.subheadline)
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
    private var expandedPlaybackSection: some View {
        Divider()
            .padding(.vertical, 8)
        if session.nowPlayingItem != nil {
            playbackSection
            deviceDetails
            Divider()
                .padding(.vertical, 8)
            playbackDetails
            playbackTimeline
        } else {
            deviceDetails
        }
    }

    @ViewBuilder
    private var playbackSection: some View {
        HStack {
            if let imageSource = session.nowPlayingItem?.portraitImageSources().first,
               let url = imageSource.url
            {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 75)
                        .clipShape(Rectangle())
                } placeholder: {
                    ProgressView()
                        .frame(width: 50, height: 75)
                }
            }
            VStack(alignment: .leading) {
                SessionDisplayNameView(item: session.nowPlayingItem!)
            }
            Spacer()
            playbackState
                .padding(.leading, 4)
        }
        Divider()
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var deviceDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let deviceName = session.deviceName {
                Text("Device: \(deviceName)")
            }
            if let clientName = session.client {
                Text("Client: \(clientName)")
            }
            if let version = session.applicationVersion {
                Text("Version: \(version)")
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var playbackState: some View {
        let playState = session.playState
        if playState?.isPaused == true {
            Text("Paused").foregroundColor(.orange)
        } else if playState?.mediaSourceID != nil {
            Text("Playing").foregroundColor(.green)
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
                        .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                        .scaleEffect(x: 1, y: 2)
                }
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: session.playState?.isPaused ?? false ? .orange : .green))
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
}
