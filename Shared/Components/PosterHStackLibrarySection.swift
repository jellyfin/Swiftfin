//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PosterHStackLibrarySection<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    @Router
    private var router

    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    private let group: PosterGroup<Library>

    init(viewModel: PagingLibraryViewModel<Library>, group: PosterGroup<Library>) {
        self.group = group
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @ViewBuilder
    private var header: some View {

        let action: () -> Void = {
            router.route(to: .library(library: viewModel.library))
        }

        Button(action: action) {
            HStack(spacing: 3) {
                Text(viewModel.library.parent.displayTitle)
                    .font(.title2)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.forward")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.semibold)
        }
        .foregroundStyle(.primary, .secondary)
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction(named: Text("Open library"), action)
        .edgePadding(.horizontal)
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            PosterHStack(
                elements: viewModel.elements,
                type: group.posterDisplayType,
                size: group.posterSize
            ) { element, namespace in

                switch element {
                case let element as BaseItemDto:
                    switch element.type {
                    case .program, .liveTvChannel, .tvProgram, .tvChannel:
                        router.route(
                            to: .videoPlayer(
                                provider: element.getPlaybackItemProvider(userSession: viewModel.userSession)
                            )
                        )
                    default:
                        router.route(to: .item(item: element), in: namespace)
                    }
                case let element as BaseItemPerson: ()
                    router.route(to: .item(item: .init(person: element)), in: namespace)
                default: ()
                }
            } header: {
                header
            }
            .animation(.linear(duration: 0.2), value: viewModel.elements)
            .withViewContext(.isThumb)
        }
    }
}
