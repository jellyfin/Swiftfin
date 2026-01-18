//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeGroup<Library: PagingLibrary>: ContentGroup where Library.Element == BaseItemDto {

    let displayTitle: String
    let id: String
    let library: Library
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        library: Library
    ) {
        self.displayTitle = library.parent.displayTitle
        self.id = UUID().uuidString
        self.library = library
        self.viewModel = .init(library: library, pageSize: 20)
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        WithRouter { router in
            EpisodeHStack(
                viewModel: viewModel,
                playButtonItemID: nil
            ) {
                #if os(tvOS)
                Text(viewModel.library.parent.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                    .edgePadding(.horizontal)
                #else
                Button {
                    router.route(to: .library(library: viewModel.library))
                } label: {
                    HStack(spacing: 3) {
                        Text(viewModel.library.parent.displayTitle)
                            .font(.title2)
                            .lineLimit(1)

                        Image(systemName: "chevron.forward")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .fontWeight(.semibold)
                }
                .foregroundStyle(.primary, .secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityAction(named: Text("Open library")) { router.route(to: .library(library: viewModel.library)) }
                .edgePadding(.horizontal)
                #endif
            }
        }
    }
}
