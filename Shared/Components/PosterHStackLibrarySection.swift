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
    var viewModel: PagingLibraryViewModel<Library>

    @Namespace
    private var namespace

    @Router
    private var router

    let group: PosterGroup<Library>

    private func routeToLibrary() {
        router.route(to: .library(library: viewModel.library))
    }

    @ViewBuilder
    private var header: some View {
//        #if os(tvOS)
//        Text(viewModel.library.parent.displayTitle)
//            .font(.title3)
//            .lineLimit(1)
//            .accessibilityAddTraits(.isHeader)
//            .edgePadding(.horizontal)
//        #else
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
//        .accessibilityAction(named: Text("Open library"), routeToLibrary)
        .edgePadding(.horizontal)
//        #endif
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Section {
                    PosterHStack(
                        elements: viewModel.elements.elements,
                        displayType: group.posterDisplayType,
                        size: group.posterSize
                    ) { element, namespace in
                        element.libraryDidSelectElement(router: router, in: namespace)
                    }
                    .withViewContext(.isThumb)
                    .focusSection()
//                .prefersDefaultFocus(in: namespace)
                } header: {
                    header
//                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
//            .focusScope(namespace)
//            .debugBackground()
        }
    }
}
