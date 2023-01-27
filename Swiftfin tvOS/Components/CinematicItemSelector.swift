//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Nuke
import SwiftUI

struct CinematicItemSelector<
    Item: Poster,
    TopContent: View,
    ItemContent: View,
    ItemImageOverlay: View,
    ItemContextMenu: View,
    TrailingContent: View
>: View {

    @ObservedObject
    private var viewModel: CinematicBackgroundView.ViewModel = .init()

    private var topContent: (Item) -> TopContent
    private var itemContent: (Item) -> ItemContent
    private var itemImageOverlay: (Item) -> ItemImageOverlay
    private var itemContextMenu: (Item) -> ItemContextMenu
    private var trailingContent: () -> TrailingContent
    private var onSelect: (Item) -> Void

    let items: [Item]

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            ZStack {
                CinematicBackgroundView(viewModel: viewModel, initialItem: items.first)
                    .ignoresSafeArea()

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

            VStack(alignment: .leading, spacing: 10) {
                if let currentItem = viewModel.currentItem {
                    topContent(currentItem)
                        .id(currentItem.displayName)
                }

                PosterHStack(type: .landscape, items: items)
                    .content(itemContent)
                    .imageOverlay(itemImageOverlay)
                    .contextMenu(itemContextMenu)
                    .trailing(trailingContent)
                    .onSelect(onSelect)
                    .onFocus { item in
                        viewModel.select(item: item)
                    }
            }
        }
        .frame(height: UIScreen.main.bounds.height - 75)
        .frame(maxWidth: .infinity)
    }

    struct CinematicBackgroundView: UIViewRepresentable {

        @ObservedObject
        var viewModel: ViewModel
        var initialItem: Item?

        @ViewBuilder
        private func imageView(for item: Item?) -> some View {
            ImageView(item?.landscapePosterImageSources(maxWidth: UIScreen.main.bounds.width, single: false) ?? [])
        }

        func makeUIView(context: Context) -> UIRotateImageView {
            let hostingController = UIHostingController(rootView: imageView(for: initialItem), ignoreSafeArea: true)
            return UIRotateImageView(initialView: hostingController.view)
        }

        func updateUIView(_ uiView: UIRotateImageView, context: Context) {
            let hostingController = UIHostingController(rootView: imageView(for: viewModel.currentItem), ignoreSafeArea: true)
            uiView.update(with: hostingController.view)
        }

        class ViewModel: ObservableObject {

            @Published
            var currentItem: Item?
            private var cancellables = Set<AnyCancellable>()

            private var currentItemSubject = CurrentValueSubject<Item?, Never>(nil)

            init() {
                currentItemSubject
                    .debounce(for: 0.5, scheduler: DispatchQueue.main)
                    .sink { newItem in
                        self.currentItem = newItem
                    }
                    .store(in: &cancellables)
            }

            func select(item: Item) {
                guard currentItem != item else { return }
                currentItemSubject.send(item)
            }
        }
    }

    class UIRotateImageView: UIView {

        private var currentView: UIView?

        init(initialView: UIView) {
            super.init(frame: .zero)

            initialView.translatesAutoresizingMaskIntoConstraints = false
            initialView.alpha = 0

            addSubview(initialView)
            NSLayoutConstraint.activate([
                initialView.topAnchor.constraint(equalTo: topAnchor),
                initialView.bottomAnchor.constraint(equalTo: bottomAnchor),
                initialView.leftAnchor.constraint(equalTo: leftAnchor),
                initialView.rightAnchor.constraint(equalTo: rightAnchor),
            ])

            self.currentView = initialView
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(with newView: UIView) {
            newView.translatesAutoresizingMaskIntoConstraints = false
            newView.alpha = 0

            addSubview(newView)
            NSLayoutConstraint.activate([
                newView.topAnchor.constraint(equalTo: topAnchor),
                newView.bottomAnchor.constraint(equalTo: bottomAnchor),
                newView.leftAnchor.constraint(equalTo: leftAnchor),
                newView.rightAnchor.constraint(equalTo: rightAnchor),
            ])

            UIView.animate(withDuration: 0.3) {
                newView.alpha = 1
                self.currentView?.alpha = 0
            } completion: { _ in
                self.currentView?.removeFromSuperview()
                self.currentView = newView
            }
        }
    }
}

extension CinematicItemSelector where TopContent == EmptyView,
    ItemContent == EmptyView,
    ItemImageOverlay == EmptyView,
    ItemContextMenu == EmptyView,
    TrailingContent == EmptyView
{
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

    @ViewBuilder
    func topContent<T: View>(@ViewBuilder _ content: @escaping (Item) -> T)
    -> CinematicItemSelector<Item, T, ItemContent, ItemImageOverlay, ItemContextMenu, TrailingContent> {
        CinematicItemSelector<Item, T, ItemContent, ItemImageOverlay, ItemContextMenu, TrailingContent>(
            topContent: content,
            itemContent: itemContent,
            itemImageOverlay: itemImageOverlay,
            itemContextMenu: itemContextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect,
            items: items
        )
    }

    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping (Item) -> C)
    -> CinematicItemSelector<Item, TopContent, C, ItemImageOverlay, ItemContextMenu, TrailingContent> {
        CinematicItemSelector<Item, TopContent, C, ItemImageOverlay, ItemContextMenu, TrailingContent>(
            topContent: topContent,
            itemContent: content,
            itemImageOverlay: itemImageOverlay,
            itemContextMenu: itemContextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect,
            items: items
        )
    }

    @ViewBuilder
    func itemImageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (Item) -> O)
    -> CinematicItemSelector<Item, TopContent, ItemContent, O, ItemContextMenu, TrailingContent> {
        CinematicItemSelector<Item, TopContent, ItemContent, O, ItemContextMenu, TrailingContent>(
            topContent: topContent,
            itemContent: itemContent,
            itemImageOverlay: imageOverlay,
            itemContextMenu: itemContextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect,
            items: items
        )
    }

    @ViewBuilder
    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (Item) -> M)
    -> CinematicItemSelector<Item, TopContent, ItemContent, ItemImageOverlay, M, TrailingContent> {
        CinematicItemSelector<Item, TopContent, ItemContent, ItemImageOverlay, M, TrailingContent>(
            topContent: topContent,
            itemContent: itemContent,
            itemImageOverlay: itemImageOverlay,
            itemContextMenu: contextMenu,
            trailingContent: trailingContent,
            onSelect: onSelect,
            items: items
        )
    }

    @ViewBuilder
    func trailingContent<T: View>(@ViewBuilder _ content: @escaping () -> T)
    -> CinematicItemSelector<Item, TopContent, ItemContent, ItemImageOverlay, ItemContextMenu, T> {
        CinematicItemSelector<Item, TopContent, ItemContent, ItemImageOverlay, ItemContextMenu, T>(
            topContent: topContent,
            itemContent: itemContent,
            itemImageOverlay: itemImageOverlay,
            itemContextMenu: itemContextMenu,
            trailingContent: content,
            onSelect: onSelect,
            items: items
        )
    }

    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
