//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct EPGCollectionView: UIViewRepresentable {

    @ObservedObject
    var viewModel: EPGViewModel

    let proxy: EPGScrollProxy
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

        private struct ItemID: Hashable {
            let channelID: String
            let blockID: ProgramBlock.ID
            let duplicateIndex: Int
        }

        private struct RenderItem: Equatable {
            let id: ItemID
            let block: ProgramBlock
            let frame: CGRect

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.id == rhs.id && lhs.frame == rhs.frame
            }
        }

        private struct RenderSection: Equatable {
            let id: String
            let items: [RenderItem]
        }

        private struct RenderContentSignature: Equatable {
            let channelIDs: [String]
            let programsRevision: Int
            let startDate: Date
            let layout: EPGLayout
        }

        private struct RenderState: Equatable {
            let sections: [RenderSection]
            let contentWidth: CGFloat
            let nowOffset: CGFloat?
            let now: Date
            let programsRevision: Int
            let rowHeight: CGFloat
        }

        var representable: EPGCollectionView?

        let gridLayout = EPGGridLayout()

        private weak var collectionView: UICollectionView?

        private var accentColor = Defaults[.accentColor]
        private var cancellables: Set<AnyCancellable> = []
        private var dataSource: UICollectionViewDiffableDataSource<String, ItemID>?
        private var didRequestNextPage = false
        private var lastPaginationVerticalOffset: CGFloat?
        private var renderContentSignature: RenderContentSignature?
        private var renderItems: [ItemID: RenderItem] = [:]
        private var renderState: RenderState?
        private let scrollState = EPGScrollState()
        private var wasLoadingNextPage = false

        func configure(_ collectionView: UICollectionView) {
            self.collectionView = collectionView
            lastPaginationVerticalOffset = collectionView.contentOffset.y

            let registration = UICollectionView.CellRegistration<UICollectionViewCell, ItemID> { [weak self] cell, _, itemID in
                cell.configurationUpdateHandler = { [weak self] cell, state in
                    self?.configure(
                        cell,
                        for: itemID,
                        isFocused: state.isFocused
                    )
                }

                self?.configure(
                    cell,
                    for: itemID,
                    isFocused: cell.isFocused
                )
            }

            scrollState.update(visibleLeadingOffset: collectionView.contentOffset.x)

            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemID in
                collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemID)
            }

            Defaults.publisher(.accentColor)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }

                    self.accentColor = Defaults[.accentColor]
                    self.gridLayout.nowColor = UIColor(self.accentColor)
                    self.gridLayout.invalidateLayout()
                    self.refreshVisibleCells()
                }
                .store(in: &cancellables)
        }

        func update(_ collectionView: UICollectionView) {
            guard let representable else { return }

            let viewModel = representable.viewModel
            let layout = representable.layout
            let contentSignature = RenderContentSignature(
                channelIDs: viewModel.channels.compactMap(\.id),
                programsRevision: viewModel.programsRevision,
                startDate: viewModel.startDate,
                layout: layout
            )
            let sections: [RenderSection]

            if contentSignature != renderContentSignature {
                if let renderContentSignature,
                   renderContentSignature.startDate != contentSignature.startDate
                {
                    representable.proxy.reset()
                }

                sections = makeSections(viewModel: viewModel, layout: layout)
                renderItems = sections.reduce(into: [:]) { lookup, section in
                    for item in section.items {
                        lookup[item.id] = item
                    }
                }
                renderContentSignature = contentSignature
            } else {
                sections = renderState?.sections ?? []
            }

            let nowOffset = layout.width(from: viewModel.startDate, to: viewModel.now)
            let nextRenderState = RenderState(
                sections: sections,
                contentWidth: max(1, layout.width(from: viewModel.startDate, to: viewModel.endDate)),
                nowOffset: viewModel.now >= viewModel.startDate ? nowOffset : nil,
                now: viewModel.now,
                programsRevision: viewModel.programsRevision,
                rowHeight: layout.rowHeight
            )

            let sectionsDidChange = renderState?.sections != nextRenderState.sections
            let layoutDidChange = sectionsDidChange ||
                renderState?.contentWidth != nextRenderState.contentWidth ||
                renderState?.nowOffset != nextRenderState.nowOffset ||
                renderState?.rowHeight != nextRenderState.rowHeight
            let cellsDidChange = renderState?.now != nextRenderState.now ||
                renderState?.programsRevision != nextRenderState.programsRevision

            gridLayout.rowHeight = nextRenderState.rowHeight
            gridLayout.contentWidth = nextRenderState.contentWidth
            gridLayout.nowOffset = nextRenderState.nowOffset
            gridLayout.nowColor = UIColor(accentColor)

            if sectionsDidChange {
                gridLayout.sectionFrames = nextRenderState.sections.map { section in
                    section.items.map(\.frame)
                }
                didRequestNextPage = false
                applySnapshot(nextRenderState, to: collectionView)
            } else if layoutDidChange {
                UIView.performWithoutAnimation {
                    gridLayout.invalidateLayout()
                }
            }

            renderState = nextRenderState

            if cellsDidChange {
                refreshVisibleCells()
            }

            if wasLoadingNextPage, !viewModel.background.is(.gettingNextPage) {
                didRequestNextPage = false
            }
            wasLoadingNextPage = viewModel.background.is(.gettingNextPage)

            representable.proxy.registerContent(collectionView, centeringOn: gridLayout.nowOffset)
            representable.proxy.registerVertical(collectionView)
        }

        private func makeSections(
            viewModel: EPGViewModel,
            layout: EPGLayout
        ) -> [RenderSection] {
            viewModel.channels.enumerated().compactMap { section, channel -> RenderSection? in
                guard let channelID = channel.id else { return nil }

                var occurrences: [ProgramBlock.ID: Int] = [:]
                let items = (viewModel.programs[channelID] ?? []).map { block in
                    let duplicateIndex = occurrences[block.id, default: 0]
                    occurrences[block.id] = duplicateIndex + 1
                    let id = ItemID(
                        channelID: channelID,
                        blockID: block.id,
                        duplicateIndex: duplicateIndex
                    )
                    let leadingOffset = layout.width(from: viewModel.startDate, to: block.start)

                    return RenderItem(
                        id: id,
                        block: block,
                        frame: CGRect(
                            x: leadingOffset,
                            y: CGFloat(section) * layout.rowHeight,
                            width: layout.width(from: block.start, to: block.end),
                            height: layout.rowHeight
                        )
                    )
                }

                return RenderSection(id: channelID, items: items)
            }
        }

        private func applySnapshot(_ renderState: RenderState, to collectionView: UICollectionView) {
            var snapshot = NSDiffableDataSourceSnapshot<String, ItemID>()
            snapshot.appendSections(renderState.sections.map(\.id))

            for section in renderState.sections {
                snapshot.appendItems(section.items.map(\.id), toSection: section.id)
            }

            UIView.performWithoutAnimation {
                dataSource?.apply(snapshot, animatingDifferences: false)
                gridLayout.invalidateLayout()
                collectionView.layoutIfNeeded()
            }
        }

        private func configure(
            _ cell: UICollectionViewCell,
            for itemID: ItemID,
            isFocused: Bool
        ) {
            guard let representable,
                  let renderItem = renderItems[itemID]
            else { return }

            let block = renderItem.block

            let action = { [weak self] in
                guard let self else { return }
                select(itemID)
            }

            cell.contentConfiguration = UIHostingConfiguration {
                EPGProgramCell(
                    scrollState: scrollState,
                    block: block,
                    leadingOffset: renderItem.frame.minX,
                    isCurrent: block.isAiring(at: representable.viewModel.now),
                    isFocused: isFocused,
                    accentColor: accentColor,
                    action: action
                )
            }
            .margins(.all, 0)

            cell.backgroundConfiguration = .clear()
            cell.clipsToBounds = true

            #if os(iOS)
            cell.focusEffect = nil
            #endif
        }

        private func select(_ itemID: ItemID) {
            guard let representable,
                  let block = renderItems[itemID]?.block
            else { return }

            if block.isGroup {
                representable.onSelectGroup(block)
            } else if let program = block.programs.first {
                representable.onSelect(program)
            }
        }

        private func refreshVisibleCells() {
            guard let collectionView, let dataSource else { return }

            UIView.performWithoutAnimation {
                for cell in collectionView.visibleCells {
                    guard let indexPath = collectionView.indexPath(for: cell),
                          let itemID = dataSource.itemIdentifier(for: indexPath)
                    else { continue }

                    configure(
                        cell,
                        for: itemID,
                        isFocused: cell.isFocused
                    )
                }
            }
        }

        func collectionView(
            _ collectionView: UICollectionView,
            didSelectItemAt indexPath: IndexPath
        ) {
            guard let itemID = dataSource?.itemIdentifier(for: indexPath) else { return }
            select(itemID)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let representable else { return }

            scrollState.update(visibleLeadingOffset: scrollView.contentOffset.x)

            let verticalOffset = scrollView.contentOffset.y
            let didScrollVertically = lastPaginationVerticalOffset.map {
                abs($0 - verticalOffset) > 0.5
            } ?? true
            lastPaginationVerticalOffset = verticalOffset

            guard didScrollVertically else { return }

            let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height

            guard remaining < 300 else {
                didRequestNextPage = false
                return
            }

            guard !didRequestNextPage,
                  !representable.viewModel.background.is(.gettingNextPage)
            else { return }

            didRequestNextPage = true
            representable.onReachedBottom()
        }
    }
}
