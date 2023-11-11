//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import JellyfinAPI
import SwiftUI

// TODO: find cleaner way to pass all of the button extensions?

struct PagingCollectionView: UIViewRepresentable {
    
    @Binding
    private var items: OrderedSet<BaseItemDto>
    @Binding
    private var viewType: LibraryViewType
    
    private var onBottom: () -> Void
    private var makeView: (BaseItemDto) -> any View
    
    init(
        items: Binding<OrderedSet<BaseItemDto>>,
        viewType: Binding<LibraryViewType>,
        @ViewBuilder makeView: @escaping (BaseItemDto) -> any View
    ) {
        self._items = items
        self._viewType = viewType
        self.onBottom = { }
        self.makeView = makeView
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
//        context.coordinator.updateLayout(type: viewType)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            items: .constant([]),
            viewType: viewType,
            onBottom: onBottom,
            makeView: makeView
        )
    }
    
    class Coordinator: NSObject, UICollectionViewDelegate {
        
        var collectionView: UICollectionView!
        var items: Binding<OrderedSet<BaseItemDto>>
        var viewType: LibraryViewType
        var dataSource: UICollectionViewDiffableDataSource<Int, BaseItemDto.ID>!
        var makeView: (BaseItemDto) -> any View
        
        private var onBottom: () -> Void
        
        init(
            items: Binding<OrderedSet<BaseItemDto>>,
            viewType: LibraryViewType,
            onBottom: @escaping () -> Void,
            makeView: @escaping (BaseItemDto) -> any View
        ) {
            self.items = items
            self.viewType = viewType
            self.onBottom = onBottom
            self.dataSource = nil
            self.makeView = makeView
            super.init()
        }
        
        func configureDataSource() {
            let cellRegistration = UICollectionView.CellRegistration<PosterButtonCell, BaseItemDto> { cell, indexPath, item in
                cell.setupHostingView(with: self.makeView(item))
            }
            
            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemID in
                // TODO: what should happen if out of sync and not found, since nil will crash?
                guard let item = self.items.wrappedValue.first(where: { $0.id == itemID }) else {
                    return nil
                }
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
        
        // TODO: new vs old state checking
        func updateItems(with newItems: Binding<OrderedSet<BaseItemDto>>) {
            
            print("Updating snapshot.")
            
            guard items.wrappedValue.count != newItems.wrappedValue.count else { return }
            items = newItems
            
            var snapshot = NSDiffableDataSourceSnapshot<Int, BaseItemDto.ID>()
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
            let layout = NSCollectionLayoutSection.list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
            layout.contentInsets = .init(vertical: 10, horizontal: 5)
            return layout
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
        copy(modifying: \.onBottom, with: action)
    }
}

class PosterButtonCell: UICollectionViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
    func setupHostingView(with view: any View) {
        let hostingController = UIHostingController(rootView: AnyView(view))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
