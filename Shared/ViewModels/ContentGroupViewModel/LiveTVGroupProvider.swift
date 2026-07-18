//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct LiveTVGroupProvider: ContentGroupProvider {

    private enum LiveTVPill: Displayable, SystemImageable {
        case channels

        var displayTitle: String {
            switch self {
            case .channels:
                L10n.channels
            }
        }

        var systemImage: String {
            switch self {
            case .channels:
                "play.square.stack"
            }
        }
    }

    let id: String = "live-tv"
    let displayTitle: String = L10n.liveTV

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {

        PillGroup(
            displayTitle: "",
            id: "live-tv-channels",
            elements: [LiveTVPill.channels]
        ) { router, pill in
            switch pill {
            case .channels:
                router.route(to: .library(library: LiveTVChannelLibrary()))
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
    }
}
