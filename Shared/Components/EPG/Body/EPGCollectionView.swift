//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
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
    let onSelectGroup: (ProgramBlock) -> Void

    private let layout = EPGLayout()

    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.gridLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.selfSizingInvalidation = .disabled
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.delegate = context.coordinator

        context.coordinator.representable = self
        context.coordinator.configure(collectionView)

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.representable = self

        if collectionView.contentInset.bottom != bottomInset {
            collectionView.contentInset.bottom = bottomInset
        }

        context.coordinator.update(collectionView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

extension EPGCollectionView {

    final class Coordinator: NSObject, UICollectionViewDelegate {

        var representable: EPGCollectionView?

        let gridLayout = EPGGridLayout()

        private weak var collectionView: UICollectionView?

        private var appliedItemIDs: [[String]] = []
        private var appliedNowOffset: CGFloat?
        private var blocks: [String: ProgramBlock] = [:]
        private var cancellables: Set<AnyCancellable> = []
        private var dataSource: UICollectionViewDiffableDataSource<String, String>?

        func configure(_ collectionView: UICollectionView) {
            self.collectionView = collectionView

            let registration = UICollectionView.CellRegistration<EPGProgramCell, String> { [weak self] cell, _, blockID in
                guard let self, let block = self.blocks[blockID] else { return }

                self.style(cell, with: block)
                cell.stickyLeadingOffset = collectionView.contentOffset.x
            }

            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, blockID in
                collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: blockID)
            }

            Defaults.publisher(.Customization.EPG.programColorSelection)
                .map { _ in () }
                .merge(
                    with: Defaults.publisher(.Customization.EPG.programColor).map { _ in () },
                    Defaults.publisher(.accentColor).map { _ in () }
                )
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.refreshVisibleCells()
                }
                .store(in: &cancellables)
        }

        func update(_ collectionView: UICollectionView) {
            guard let representable else { return }

            let viewModel = representable.viewModel
            let layout = representable.layout

            let channelIDs = representable.channels.elements.compactMap(\.id)
            let sections = channelIDs.map { viewModel.programs[$0] ?? [] }
            let itemIDs = sections.map { $0.map(\.id) }

            let nowOffset = layout.width(from: viewModel.startDate, to: viewModel.now)

            gridLayout.rowHeight = layout.rowHeight
            gridLayout.contentWidth = max(1, layout.width(from: viewModel.startDate, to: viewModel.endDate))
            gridLayout.nowOffset = viewModel.now >= viewModel.startDate ? nowOffset : nil
            gridLayout.nowColor = UIColor(Defaults[.accentColor])

            if itemIDs != appliedItemIDs {
                appliedItemIDs = itemIDs
                appliedNowOffset = gridLayout.nowOffset

                blocks = sections.reduce(into: [:]) { lookup, channelBlocks in
                    for block in channelBlocks {
                        lookup[block.id] = block
                    }
                }

                gridLayout.sectionFrames = sections.enumerated().map { section, channelBlocks in
                    channelBlocks.map { block in
                        CGRect(
                            x: block.leadingOffset,
                            y: CGFloat(section) * layout.rowHeight,
                            width: block.width,
                            height: layout.rowHeight
                        )
                    }
                }

                var snapshot = NSDiffableDataSourceSnapshot<String, String>()
                snapshot.appendSections(channelIDs)

                for (channelID, ids) in zip(channelIDs, itemIDs) {
                    snapshot.appendItems(ids, toSection: channelID)
                }

                UIView.performWithoutAnimation {
                    dataSource?.apply(snapshot, animatingDifferences: false)
                    gridLayout.invalidateLayout()
                    collectionView.layoutIfNeeded()
                }
            } else if appliedNowOffset != gridLayout.nowOffset {
                appliedNowOffset = gridLayout.nowOffset

                UIView.performWithoutAnimation {
                    gridLayout.invalidateLayout()
                }

                refreshVisibleCells()
            }

            viewModel.proxy.registerContent(collectionView, centeringOn: gridLayout.nowOffset)
            viewModel.proxy.registerVertical(collectionView)
        }

        private func style(_ cell: EPGProgramCell, with block: ProgramBlock) {
            guard let representable else { return }

            let selectedTypes = Defaults[.Customization.EPG.programColorSelection]
            let typeColors = Defaults[.Customization.EPG.programColor]

            let typeColor = block.programs.first.flatMap { program in
                ProgramType.allCases
                    .first { selectedTypes.contains($0) && $0.matches(program) }
                    .map { UIColor(typeColors[$0] ?? $0.color) }
            }

            cell.configure(
                block: block,
                isCurrent: block.isAiring(at: representable.viewModel.now),
                typeColor: typeColor
            )
        }

        private func refreshVisibleCells() {
            guard let collectionView else { return }

            UIView.performWithoutAnimation {
                for case let cell as EPGProgramCell in collectionView.visibleCells {
                    guard let block = cell.block else { continue }
                    style(cell, with: block)
                }
            }
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: false)

            guard let blockID = dataSource?.itemIdentifier(for: indexPath),
                  let block = blocks[blockID]
            else { return }

            if block.isGroup {
                representable?.onSelectGroup(block)
            } else if let program = block.programs.first {
                representable?.onSelect(program)
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let collectionView else { return }

            for case let cell as EPGProgramCell in collectionView.visibleCells {
                cell.stickyLeadingOffset = scrollView.contentOffset.x
            }

            let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height

            if remaining < 300 {
                representable?.onReachedBottom()
            }
        }
    }
}
