//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

enum VideoPlayerSupplementPresentationStyle: Equatable {

    case regular
    case expanded
}

@MainActor
protocol VideoPlayerSupplement: Displayable, Identifiable, View {

    var id: String { get }

    var presentationStyle: VideoPlayerSupplementPresentationStyle { get }
    var preferredFocusID: String { get }
}

extension VideoPlayerSupplement {

    var presentationStyle: VideoPlayerSupplementPresentationStyle {
        .regular
    }

    var preferredFocusID: String {
        VideoPlayer.ViewState.Focus.supplementContent(id)
    }
}

extension VideoPlayerSupplementType {

    @MainActor
    func makeSupplement(for item: MediaPlayerItem, queue: (any MediaPlayerQueue)?) -> (any VideoPlayerSupplement)? {
        switch self {
        case .info:
            return MediaInfoSupplement(item: item.baseItem)

        case .chapters:
            guard !item.chapters.isEmpty else { return nil }

            return MediaChaptersSupplement(id: "Chapters-\(item.baseItem.id ?? "any")", chapters: item.chapters)

        case .queue:
            switch queue {
            case let queue as EpisodeMediaPlayerQueue:
                guard item.baseItem.type == .episode, let seasonID = item.baseItem.seasonID?.nilIfBlank else { return nil }

                let season = BaseItemDto(id: seasonID, name: item.baseItem.seasonName, seriesID: item.baseItem.seriesID, type: .season)

                return QueueSupplement(id: "Queue-\(ObjectIdentifier(queue))", displayTitle: L10n.episodes) {
                    EpisodeQueueView(season: season)
                        .id(seasonID)
                }

            default:
                return nil
            }

        case .people:
            guard let people = item.baseItem.mergedPeople?.filter({ $0.type?.isSupported == true }), !people.isEmpty else { return nil }

            return MediaPeopleSupplement(people: people)

        case .playbackInformation:
            return item.baseItem.id.map { PlaybackInfoSupplement(itemID: $0) }
        }
    }
}
