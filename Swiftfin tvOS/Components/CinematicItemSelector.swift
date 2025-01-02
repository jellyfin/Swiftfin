//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

// TODO: make new protocol for cinematic view image provider
// TODO: better name

struct CinematicItemSelector<Item: Poster>: View {

    @State
    private var focusedItem: Item?

    @StateObject
    private var viewModel: CinematicBackgroundView<Item>.ViewModel = .init()

    private var topContent: (Item) -> any View
    private var itemContent: (Item) -> any View
    private var itemImageOverlay: (Item) -> any View
    private var itemContextMenu: (Item) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Item) -> Void

    let items: [Item]

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            Color.clear

            VStack(alignment: .leading, spacing: 10) {

                Spacer()

                if let currentItem = viewModel.currentItem {
                    topContent(currentItem)
                        .eraseToAnyView()
                        .id(currentItem.hashValue)
                        .transition(.opacity)
                }

                PosterHStack(type: .landscape, items: items)
                    .content(itemContent)
                    .imageOverlay(itemImageOverlay)
                    .contextMenu(itemContextMenu)
                    .trailing(trailingContent)
                    .onSelect(onSelect)
                    .focusedItem($focusedItem)
            }
        }
        .background(alignment: .top) {
            ZStack {
                CinematicBackgroundView(
                    viewModel: viewModel,
                    initialItem: items.first
                )

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.5),
                        .init(color: .black.opacity(0.4), location: 0.6),
                        .init(color: .black, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: UIScreen.main.bounds.height)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0.9),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(height: UIScreen.main.bounds.height - 75)
        .frame(maxWidth: .infinity)
        .onChange(of: focusedItem) { _, newValue in
            guard let newValue else { return }
            viewModel.select(item: newValue)
        }
        .onAppear {
            focusedItem = items.first
        }
    }
}

extension CinematicItemSelector {

    init(items: [Item]) {
        self.init(
            topContent: { _ in EmptyView() },
            itemContent: { _ in EmptyView() },
            itemImageOverlay: { _ in EmptyView() },
            itemContextMenu: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in },
            items: items
        )
    }
}

extension CinematicItemSelector {

    func topContent(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.topContent, with: content)
    }

    func content(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.itemContent, with: content)
    }

    func itemImageOverlay(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.itemImageOverlay, with: content)
    }

    func contextMenu<M: View>(@ViewBuilder _ content: @escaping (Item) -> M) -> Self {
        copy(modifying: \.itemContextMenu, with: content)
    }

    func trailingContent<T: View>(@ViewBuilder _ content: @escaping () -> T) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
