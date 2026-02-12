//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct PagingLibraryView<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    typealias Element = Library.Element

    @Default(.Customization.Library.rememberLayout)
    private var rememberIndividualLibraryStyle

    @StoredValue(.User.libraryStyle(id: nil))
    private var defaultLibraryStyle: LibraryStyle
    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    @ForTypeInEnvironment<Element.Type, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>(\.libraryStyleRegistry)
    private var libraryStyleRegistry

    @Namespace
    private var namespace

    @Router
    private var router

    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    private var libraryStyle: LibraryStyle {
        libraryStyleRegistry?(Element.self).0 ?? .default
    }

    init(library: Library) {
        self._parentLibraryStyle = StoredValue(.User.libraryStyle(id: library.parent.libraryID))
        self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: library))
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
        case .content:
            if viewModel.elements.isEmpty {
                Text(L10n.noResults)
            } else {
                ElementsView(viewModel: viewModel)
                    .ignoresSafeArea()
                    .libraryStyle(for: Element.self) { environment, _ in
                        if rememberIndividualLibraryStyle {
                            return (parentLibraryStyle, $parentLibraryStyle)
                        } else {
                            return environment
                        }
                    }
            }
        case .error:
            viewModel.error.map(ErrorView.init)
        }
    }

    var body: some View {
        viewModel.library.makeLibraryBody(viewModel: viewModel) {
            contentView
                .frame(maxWidth: .infinity)
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(viewModel.library.parent.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .backport
        .onChange(of: viewModel.environment) { _, _ in
            viewModel.refresh()
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.refresh()
            }
        }
        #if os(iOS)
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.retrievingNextPage)
        ) {}
        #endif
    }
}
