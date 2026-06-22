//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterHStackLibrarySection<Library: PagingLibrary>: View
    where Library.Element: LibraryElement, Library.Element: Poster
{

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<Library>

    @Router
    private var router

    @Namespace
    private var namespace

    private let group: PosterGroup<Library>

    init(viewModel: PagingLibraryViewModel<Library>, group: PosterGroup<Library>) {
        self.group = group
        self.viewModel = viewModel
    }

    private func routeToLibrary() {
        router.route(to: .library(library: viewModel.library))
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            #if os(tvOS)
            PosterHStack(
                title: viewModel.library.parent.displayTitle,
                type: group.posterDisplayType,
                items: viewModel.elements.elements
            ) { element in
                element.libraryDidSelectElement(router: router, in: namespace)
            }
            #else
            PosterHStack(
                title: viewModel.library.parent.displayTitle,
                type: group.posterDisplayType,
                items: viewModel.elements.elements
            ) { element, namespace in
                element.libraryDidSelectElement(router: router, in: namespace)
            }
            .trailing {
                Button(L10n.seeAll, systemImage: "chevron.forward") {
                    routeToLibrary()
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel(L10n.seeAll)
            }
            #endif
        }
    }
}
