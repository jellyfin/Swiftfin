//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

struct PagingCollectionView<Item: Poster>: UIViewRepresentable {
    
    @Binding
    var items: OrderedSet<Item>
    @Binding
    var viewType: LibraryViewType
    
    private var onBottom: () -> Void
    private var onSelect: (Item) -> Void
    
    init(items: Binding<OrderedSet<Item>>, viewType: Binding<LibraryViewType>) {
        self._items = items
        self._viewType = viewType
        self.onBottom = { }
        self.onSelect = { _ in }
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.layout(for: viewType))
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = context.coordinator
        
        context.coordinator.collectionView = collectionView
        context.coordinator.configureDataSource()
        context.coordinator.updateItems(with: $items)
        
        return collectionView
    }
    
    func updateUIView(_ view: UICollectionView, context: Context) {
        
        context.coordinator.updateItems(with: $items)
        context.coordinator.updateLayout(type: viewType)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, viewType: viewType, onBottom: onBottom)
    }
    
    class Coordinator: NSObject, UICollectionViewDelegate {
        
        var collectionView: UICollectionView!
        var items: Binding<OrderedSet<Item>>
        var viewType: LibraryViewType
        
        private var lastItemHash: Int = -1
        var onBottom: () -> Void
        var dataSource: UICollectionViewDiffableDataSource<Int, Item.ID>!
        
        init(items: Binding<OrderedSet<Item>>, viewType: LibraryViewType, onBottom: @escaping () -> Void) {
            self.items = items
            self.viewType = viewType
            self.onBottom = onBottom
            self.dataSource = nil
            super.init()
        }
        
        func configureDataSource() {
            let cellRegistration = UICollectionView.CellRegistration<PosterButtonCell, Item> { cell, indexPath, item in
                cell.setupHostingView(with: item, indexPath: indexPath, type: self.viewType)
            }
            
            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemID in
                // TODO: Fix as you can't return nil
                guard let item = self.items.wrappedValue.first(where: { $0.id == itemID }) else {
                    return nil
                }
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
        
        func updateItems(with newItems: Binding<OrderedSet<Item>>) {
            
            print("Updating snapshot.")
            
//            guard items.wrappedValue.count != newItems.wrappedValue.count else { return }
            items = newItems
            
            var snapshot = NSDiffableDataSourceSnapshot<Int, Item.ID>()
            snapshot.appendSections([0])
            snapshot.appendItems(newItems.elements.map(\.id))
            dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            
            let bottomOffset: CGFloat = 200
            let adjustedHeight = scrollView.contentSize.height - scrollView.frame.height + scrollView.adjustedContentInset.bottom - bottomOffset
            let reachedBottom = scrollView.contentOffset.y >= adjustedHeight
            
            if reachedBottom {
                onBottom()
            }
        }
        
        func updateLayout(type: LibraryViewType) {
            
            guard viewType != type else { return }
            viewType = type
            
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
            
            let layout = layout(for: type)
            
            // stay at top when transitioning between the layouts while at the top since the cells have different heights
            let isAtTop = collectionView.contentOffset.y <= -collectionView.adjustedContentInset.top
            
            collectionView.setCollectionViewLayout(layout, animated: false) { _ in
                if isAtTop {
                    self.collectionView.setContentOffset(.init(x: 0, y: -self.collectionView.adjustedContentInset.top), animated: false)
                }
            }
        }
        
        func layout(for type: LibraryViewType) -> UICollectionViewLayout {
            switch type {
            case .grid:
                return UICollectionViewCompositionalLayout(sectionProvider: landscapePosterLayoutProvider(index:layoutEnvironment:))
            case .list:
                return UICollectionViewCompositionalLayout(sectionProvider: listLayoutProvider(index:layoutEnvironment:))
            }
        }
        
        private func listLayoutProvider(index: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
            let a = NSCollectionLayoutSection.list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
            a.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            a.interGroupSpacing = 5
            return a
        }
        
        private func landscapePosterLayoutProvider(index: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
            
            let minWidth: CGFloat
            
            // TODO: potential for reading accessibility settings and making items bigger
            // TODO: make bigger for larger frames
            switch viewType {
            case .grid:
                minWidth = 150
            default:
                minWidth = 180
            }
            
            let perRow: CGFloat = CGFloat(Int(layoutEnvironment.container.contentSize.width / minWidth))
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / perRow),
                heightDimension: .estimated(50)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(50)
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 5
            section.contentInsets = .init(constant: 10)
            
            return section
        }
    }
}

extension PagingCollectionView {
    
    func onBottom(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onBottom = action
        return copy
    }
    
    func onSelect(_ action: @escaping (Item) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}

class PosterButtonCell<Item: Poster>: UICollectionViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
    func setupHostingView(with item: Item, indexPath: IndexPath, type: LibraryViewType) {
        let newHost = makeHost(with: item, indexPath: indexPath, type: type)
        addSubview(newHost.view)
        
        NSLayoutConstraint.activate([
            newHost.view.topAnchor.constraint(equalTo: topAnchor),
            newHost.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            newHost.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            newHost.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func makePosterButton(with item: Item, indexPath: IndexPath, viewType: LibraryViewType, onSelect: @escaping (Item) -> Void) -> some View {
        PosterButton(item: item, type: .portrait)
    }
    
    private func makeListButton(with item: Item, indexPath: IndexPath) -> some View {
        LibraryItemRow(item: item)
    }
    
    private func makeHost(with item: Item, indexPath: IndexPath, type: LibraryViewType) -> UIHostingController<AnyView> {
        
        let v: AnyView
        
        switch type {
        case.grid:
            v = AnyView(makePosterButton(with: item, indexPath: indexPath, viewType: type, onSelect: { _ in }))
        case .list:
            v = AnyView(makeListButton(with: item, indexPath: indexPath))
        }
        
        let hostingController = UIHostingController(rootView: v)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }
}
