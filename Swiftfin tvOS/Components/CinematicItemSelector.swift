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

struct CinematicItemSelector<Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View>: View {
    
    @ObservedObject
    private var viewModel: CinematicBackgroundView.ViewModel = .init()
    
    private var content: (Item) -> Content
    private var imageOverlay: (Item) -> ImageOverlay
    private var contextMenu: (Item) -> ContextMenu
    private var onSelect: (Item) -> Void

    let items: [Item]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            CinematicBackgroundView(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                if let currentItem = viewModel.currentItem {
                    Text(currentItem.displayName)
                }
                
                PosterHStack(type: .landscape, items: items)
                    .content(content)
                    .imageOverlay(imageOverlay)
                    .contextMenu(contextMenu)
                    .onSelect(onSelect)
                    .onFocus { item in
//                        self.viewModel.select(item: item)
                    }
            }
        }
        .frame(height: UIScreen.main.bounds.height - 100)
        .frame(maxWidth: .infinity)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0.9),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
    }
    
    struct CinematicBackgroundView: UIViewRepresentable {

        @ObservedObject
        var viewModel: ViewModel
        
        @ViewBuilder
        private func imageView(for item: BaseItemDto?) -> some View {
            ImageView(item?.landscapePosterImageSources(maxWidth: UIScreen.main.bounds.width) ?? [])
        }

        func makeUIView(context: Context) -> UIRotateImageView {
            let hostingController = UIHostingController(rootView: imageView(for: viewModel.currentItem), ignoreSafeArea: true)
            return UIRotateImageView(initialView: hostingController.view)
        }

        func updateUIView(_ uiView: UIRotateImageView, context: Context) {
            let hostingController = UIHostingController(rootView: imageView(for: viewModel.currentItem), ignoreSafeArea: true)
            uiView.update(with: hostingController.view)
        }
        
        class ViewModel: ObservableObject {
            
            @Published
            var currentItem: BaseItemDto?
            private var cancellables = Set<AnyCancellable>()
            
            private var currentItemSubject = CurrentValueSubject<BaseItemDto?, Never>(nil)
            
            init() {
                currentItemSubject
                    .debounce(for: 0.5, scheduler: DispatchQueue.main)
                    .sink { newItem in
                        self.currentItem = newItem
                    }
                    .store(in: &cancellables)
            }
            
            func select(item: BaseItemDto) {
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

extension CinematicItemSelector where Content == EmptyView,
                                      ImageOverlay == EmptyView,
                                      ContextMenu == EmptyView {
    init(items: [Item]) {
        self.init(content: { _ in EmptyView() },
                  imageOverlay: { _ in EmptyView() },
                  contextMenu: { _ in EmptyView() },
                  onSelect: { _ in },
                  items: items)
        
//        if let firstItem = items.first {
//            viewModel.select(item: firstItem)
//        }
    }
}

extension CinematicItemSelector {
    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping (Item) -> C) -> CinematicItemSelector<Item, C, ImageOverlay, ContextMenu> {
        CinematicItemSelector<Item, C, ImageOverlay, ContextMenu>(
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            items: items)
    }
    
    @ViewBuilder
    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (Item) -> O) -> CinematicItemSelector<Item, Content, O, ContextMenu> {
        CinematicItemSelector<Item, Content, O, ContextMenu>(
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            items: items)
    }
    
    @ViewBuilder
    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (Item) -> M) -> CinematicItemSelector<Item, Content, ImageOverlay, M> {
        CinematicItemSelector<Item, Content, ImageOverlay, M>(
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            items: items)
    }
    
    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
