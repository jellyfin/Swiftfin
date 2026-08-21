//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct LiveTVGroupProvider: ContentGroupProvider {

    private enum LiveTVPill: Displayable, SystemImageable {
        case channels
        case guide
        case recordings

        var displayTitle: String {
            switch self {
            case .channels:
                L10n.channels
            case .guide:
                L10n.guide
            case .recordings:
                L10n.recordings
            }
        }

        var systemImage: String {
            switch self {
            case .channels:
                "play.square.stack"
            case .guide:
                "tablecells"
            case .recordings:
                "record.circle"
            }
        }
    }

    let id: String = "live-tv"
    let displayTitle: String = L10n.liveTV

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {

        PillGroup(
            displayTitle: "",
            id: "live-tv-channels",
            elements: [LiveTVPill.channels, .guide, .recordings]
        ) { router, pill in
            switch pill {
            case .channels:
                router.route(
                    to: .library(
                        library: ItemLibrary(
                            parent: BaseItemDto(name: L10n.channels),
                            filters: .init(itemTypes: [.liveTvChannel])
                        )
                    )
                )
            case .guide:
                router.route(to: .liveGuide)
            case .recordings:
                router.route(
                    to: .library(library: RecordingsLibrary())
                )
            }
        }

        PosterGroup(
            id: "programs-recommended",
            library: RecommendedProgramsLibrary(),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        [
            ProgramSection.series,
            .movies,
            .kids,
            .sports,
            .news,
        ]
            .map { section in
                PosterGroup(
                    id: "programs-\(section.rawValue)",
                    library: ProgramsLibrary(section: section),
                    posterDisplayType: .landscape,
                    posterSize: .small
                )
            }

        PosterGroup(
            id: "recordings",
            library: RecordingsLibrary(),
            posterDisplayType: .landscape,
            posterSize: .small
        )
    }
}
