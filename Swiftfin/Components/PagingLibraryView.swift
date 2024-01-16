//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: find better way to init layout
// - is onAppear good enough since it's fast?

struct PagingLibraryView: View {

    @Default(.Customization.Library.viewType)
    private var libraryViewType
    @Default(.Customization.Library.listColumnCount)
    private var listColumnCount

    @ObservedObject
    var viewModel: PagingLibraryViewModel

    @State
    private var layout: CollectionVGridLayout

    private var onSelect: (BaseItemDto) -> Void

    // lists will add their own insets to manually add the dividers
    private func padLayout(libraryViewType: LibraryViewType) -> CollectionVGridLayout {
        switch libraryViewType {
        case .landscapeGrid:
            .minWidth(220)
        case .portraitGrid:
            .minWidth(150)
        case .list:
            .columns(listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    private func phoneLayout(libraryViewType: LibraryViewType) -> CollectionVGridLayout {
        switch libraryViewType {
        case .portraitGrid:
            .columns(3)
        case .landscapeGrid:
            .columns(2)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    private func landscapeGridItemView(item: BaseItemDto) -> some View {
        PosterButton(item: item, type: .landscape)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                }
            }
            .onSelect {
                onSelect(item)
            }
    }

    private func portraitGridItemView(item: BaseItemDto) -> some View {
        PosterButton(item: item, type: .portrait)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                }
            }
            .onSelect {
                onSelect(item)
            }
    }

    private func listItemView(item: BaseItemDto) -> some View {
        LibraryItemRow(item: item)
            .onSelect {
                onSelect(item)
            }
            .padding(10)
            .overlay(alignment: .bottom) {
                Divider()
            }
    }

    // MARK: body

    var body: some View {
        CollectionVGrid(
            $viewModel.items,
            layout: $layout
        ) { item in
            switch libraryViewType {
            case .landscapeGrid:
                landscapeGridItemView(item: item)
            case .portraitGrid:
                portraitGridItemView(item: item)
            case .list:
                listItemView(item: item)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if UIDevice.isPhone {
                layout = phoneLayout(libraryViewType: libraryViewType)
            } else {
                layout = padLayout(libraryViewType: libraryViewType)
            }
        }
        .onChange(of: libraryViewType) { _ in
            if UIDevice.isPhone {
                layout = phoneLayout(libraryViewType: libraryViewType)
            } else {
                layout = padLayout(libraryViewType: libraryViewType)
            }
        }
    }
}

extension PagingLibraryView {

    init(viewModel: PagingLibraryViewModel) {
        self.init(
            viewModel: viewModel,
            layout: .columns(3),
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
