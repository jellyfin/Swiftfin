//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct BaseItemDtoPosterLabel: View {

    @Environment(\.posterConfiguration)
    private var posterConfiguration

    @Environment(\.posterDisplayType)
    private var posterDisplayType

    let item: BaseItemDto

    private var title: String {
        item.posterTitle(using: posterConfiguration.subtitleField)
    }

    private var isTitlePresented: Bool {
        switch item.type {
        case .audio, .audioBook, .book, .boxSet, .episode, .liveTvProgram, .movie, .musicAlbum, .musicVideo,
             .photo, .photoAlbum, .playlist, .program, .recording, .season, .series, .trailer, .tvProgram, .video:
            posterConfiguration.isTitlePresented
        default:
            true
        }
    }

    private var episodeLocator: String? {
        guard item.type == .episode else { return nil }
        return item.seasonEpisodeLabel ?? item.episodeLocator
    }

    private var subtitle: String? {
        guard item.type != .episode,
              let subtitle = item.posterSubtitle(using: posterConfiguration.subtitleField),
              subtitle != title else { return nil }
        return subtitle
    }

    private var isProgram: Bool {
        item.type == .program || item.type == .liveTvProgram || item.type == .tvProgram
    }

    private var hasSubtitle: Bool {
        isProgram || episodeLocator != nil || subtitle != nil
    }

    @ViewBuilder
    private var programSchedule: some View {
        if let startDate = item.startDate {
            ViewThatFits {
                SeparatorHStack {
                    Text(String.hyphen)
                } content: {
                    programStartDate(startDate)

                    if let endDate = item.endDate {
                        Text(endDate, style: .time)
                    }
                }

                programStartDate(startDate)
            }
        } else {
            Text(String.emptyRuntime)
        }
    }

    @ViewBuilder
    private func programStartDate(_ date: Date) -> some View {
        if Calendar.current.isDateInToday(date) {
            Text(date, style: .time)
        } else {
            Text(date, format: .dateTime.weekday(.abbreviated).hour().minute())
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        if isProgram {
            DotHStack {
                programSchedule
                    .layoutPriority(1)

                if posterDisplayType == .landscape, let channelName = item.channelName {
                    Text(channelName)
                }
            }
        } else if hasSubtitle {
            DotHStack {
                if let episodeLocator {
                    Text(episodeLocator)
                        .fixedSize()
                        .layoutPriority(1)
                }

                if let subtitle {
                    Text(subtitle)
                }
            }
        }
    }

    var body: some View {
        AlternateLayoutView(alignment: .topLeading) {
            VStack(spacing: 2) {
                Text(String.space)
                Text(String.space)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity)
        } content: {
            if isTitlePresented || hasSubtitle {
                VStack(alignment: .leading, spacing: 2) {
                    if isTitlePresented {
                        Text(title)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .lineLimit(hasSubtitle ? 1 : 2, reservesSpace: true)
                    }

                    subtitleView
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
