//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct LiveTVGroupProvider: _ContentGroupProvider {

    let id: String = "live-tv"
    let displayTitle: String = L10n.liveTV

    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {

        LiveTVChannelsPillGroup()

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

import SwiftUI

struct LiveTVChannelsPillGroup: _ContentGroup {

    let id: String = "asdf"
    let displayTitle: String = ""
    let viewModel: Empty = .init()

    @ViewBuilder
    func body(with viewModel: Empty) -> some View {
        WithRouter { router in
            ScrollView(.horizontal) {
                HStack {
                    Button {
                        router.route(to: .library(library: ChannelProgramLibrary()))
                    } label: {
                        Label(
                            L10n.channels,
                            systemImage: "play.square.stack"
                        )
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(8)
                        .background {
                            Color.systemFill
                                .cornerRadius(10)
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                }
                .edgePadding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
