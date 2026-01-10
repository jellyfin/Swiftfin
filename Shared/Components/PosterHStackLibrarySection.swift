//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: move to PosterGroup?

struct SeeAllPoster: Poster {
    var preferredPosterDisplayType: PosterDisplayType { .portrait }
    var displayTitle: String = L10n.seeAll
    var id: String { "see-all" }
    var systemImage: String { "ellipsis" }
}

struct PosterHStackLibrarySection<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    enum Element: Hashable {
        case element(Library.Element)
        case seeAll

        var asAnyPoster: AnyPoster {
            switch self {
            case let .element(element):
                return AnyPoster(element)
            case .seeAll:
                return AnyPoster(BaseItemDto())
            }
        }
    }

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<Library>

    @Router
    private var router

    private var _elements: [Element] {
        #if os(tvOS)
        viewModel.elements.elements
            .prefix(20)
            .map { .element($0) }
            .appending(.seeAll)
        #else
        viewModel.elements.elements
            .map { .element($0) }
        #endif
    }

    private let group: PosterGroup<Library>

    init(viewModel: PagingLibraryViewModel<Library>, group: PosterGroup<Library>) {
        self.group = group
        self.viewModel = viewModel
    }

    private func routeToLibrary() {
        router.route(to: .library(library: viewModel.library))
    }

    @ViewBuilder
    private var header: some View {
        #if os(tvOS)
        Text(viewModel.library.parent.displayTitle)
            .font(.title3)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
            .edgePadding(.horizontal)
        #else
        Button(action: routeToLibrary) {
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
        .accessibilityAction(named: Text("Open library"), routeToLibrary)
        .edgePadding(.horizontal)
        #endif
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            PosterHStack(
                elements: viewModel.elements,
//                elements: _elements.map(\.asAnyPoster),
                type: group.posterDisplayType,
                size: group.posterSize
            ) { _, _ in
                element.libraryDidSelectElement(router: router, in: namespace)
            } header: {
                header
            }
            .animation(.linear(duration: 0.2), value: viewModel.elements)
            .withViewContext(.isThumb)
        }
    }
}
