//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import JellyfinAPI
import SwiftUI

struct EPGCollectionView: UIViewRepresentable {

    @ObservedObject
    var viewModel: EPGViewModel

    let channels: IdentifiedArrayOf<BaseItemDto>
    let bottomInset: CGFloat
    let onReachedBottom: () -> Void
    let onSelect: (BaseItemDto) -> Void

    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.selfSizingInvalidation = .disabled
        collectionView.delegate = context.coordinator

        context.coordinator.representable = self
        context.coordinator.configure(collectionView)
        viewModel.proxy.registerVertical(collectionView)

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.representable = self

        if collectionView.contentInset.bottom != bottomInset {
            collectionView.contentInset.bottom = bottomInset
        }

        context.coordinator.apply(channels)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

extension EPGCollectionView {

    final class Coordinator: NSObject, UICollectionViewDelegateFlowLayout {

        var representable: EPGCollectionView?

        private let layout = EPGLayout()
        private var appliedChannelIDs: [String] = []
        private var dataSource: UICollectionViewDiffableDataSource<Int, String>?

        let flowLayout: UICollectionViewFlowLayout = {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.minimumLineSpacing = 0
            flowLayout.estimatedItemSize = .zero
            return flowLayout
        }()

        func configure(_ collectionView: UICollectionView) {
            let registration = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, channelID in
                guard let representable = self?.representable,
                      let channel = representable.channels[id: channelID]
                else { return }

                cell.automaticallyUpdatesContentConfiguration = false
                cell.contentConfiguration = UIHostingConfiguration {
                    EPGChannelRow(
                        viewModel: representable.viewModel,
                        channel: channel
                    ) { item in
                        representable.onSelect(item)
                    }
                    #if os(tvOS)
                    .ignoresSafeArea(edges: .horizontal)
                    #endif
                }
                .margins(.all, 0)
            }

            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, channelID in
                collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: channelID)
            }
        }

        func apply(_ channels: IdentifiedArrayOf<BaseItemDto>) {
            let channelIDs = channels.elements.compactMap(\.id)

            guard channelIDs != appliedChannelIDs else { return }

            appliedChannelIDs = channelIDs

            var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
            snapshot.appendSections([0])
            snapshot.appendItems(channelIDs)
            dataSource?.apply(snapshot, animatingDifferences: false)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            CGSize(width: collectionView.bounds.width, height: layout.rowHeight)
        }

        /// Indexes vary per channel (Program A is 90m and Program B is 10m) so use SwiftUI Focus
        func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            false
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height

            if remaining < 300 {
                representable?.onReachedBottom()
            }
        }
    }
}
