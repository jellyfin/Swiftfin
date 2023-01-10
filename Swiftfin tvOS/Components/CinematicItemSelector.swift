//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Nuke
import SwiftUI

struct CinematicItemSelector<Item: Poster>: View {

    @State
    private var focusedItem: Item?

    @StateObject
    private var viewModel: CinematicBackgroundView.ViewModel = .init()

    private var topContent: (Item) -> any View
    private var itemContent: (Item) -> any View
    private var itemImageOverlay: (Item) -> any View
    private var itemContextMenu: (Item) -> any View
    private var trailingContent: () -> any View
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
        .frame(height: UIScreen.main.bounds.height - 75)
        .frame(maxWidth: .infinity)
        .onChange(of: focusedItem) { newValue in
            guard let newValue else { return }
            viewModel.select(item: newValue)
        }
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
