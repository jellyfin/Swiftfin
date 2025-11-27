//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct LiveTVGroupProvider: _ContentGroupProvider {

    let id: String = "live-tv"
    let displayTitle: String = L10n.liveTV

    @ArrayBuilder<any _ContentGroup>
    func makeGroups(environment: Void) async throws -> [any _ContentGroup] {

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

    @ViewBuilder
    func body(with viewModel: VoidContentGroupViewModel) -> some View {
        _Body()
    }

    private struct _Body: View {

        @Router
        private var router

        var body: some View {
            ScrollView(.horizontal) {
                HStack {
                    Button {
//                        router.route(to: .channels)
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
