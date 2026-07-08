//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct CinematicSelectionContentGroup: ContentGroup {

    let id = "cinematic-selection"
    let viewModel: CinematicSelectionContentGroupViewModel

    var _shouldBeResolved: Bool {
        viewModel.hasContent
    }

    init(
        resumeLibrary: ResumeItemsLibrary,
        recentlyAddedLibrary: RecentlyAddedLibrary
    ) {
        self.viewModel = CinematicSelectionContentGroupViewModel(
            resumeLibrary: resumeLibrary,
            recentlyAddedLibrary: recentlyAddedLibrary
        )
    }

    func body(with viewModel: CinematicSelectionContentGroupViewModel) -> some View {
        SelectionView(viewModel: viewModel)
            .preference(
                key: ContentGroupCustomizationKey.self,
                value: .ignoreSafeAreaTop
            )
    }

    private struct SelectionView: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @Router
        private var router

        @ObservedObject
        var viewModel: CinematicSelectionContentGroupViewModel

        var body: some View {
            if viewModel.hasResumeItems {
                CinematicItemSelector(
                    items: viewModel.resumeViewModel.elements.elements,
                    action: select
                ) { item in
                    topContent(for: item)
                }
            } else {
                CinematicItemSelector(
                    items: viewModel.recentlyAddedViewModel.elements.elements,
                    action: select
                ) { item in
                    topContent(for: item)
                }
            }
        }

        private var parentFrame: CGRect {
            frameForParentView[.scrollView, default: .zero].frame
        }

        private func itemSelectorImageSource(for item: BaseItemDto) -> ImageSource {
            let maxWidth = max(parentFrame.width * CinematicSelectionLayout.logoMaxWidthPercentage, 1)

            if item.type == .episode {
                return item.imageSource(
                    itemID: item.seriesID,
                    .logo,
                    environment: ImageSourceOptions(
                        maxWidth: maxWidth,
                        maxHeight: CinematicSelectionLayout.logoMaxHeight
                    )
                )
            } else {
                return item.imageSource(
                    .logo,
                    environment: ImageSourceOptions(
                        maxWidth: maxWidth,
                        maxHeight: CinematicSelectionLayout.logoMaxHeight
                    )
                )
            }
        }

        private func titleView(for item: BaseItemDto) -> some View {
            Text(item.displayTitle)
                .font(.largeTitle)
                .fontWeight(.semibold)
        }

        private func topContent(for item: BaseItemDto) -> some View {
            ImageView(itemSelectorImageSource(for: item))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    titleView(for: item)
                }
                .edgePadding(.leading)
                .aspectRatio(contentMode: .fit)
                .frame(height: CinematicSelectionLayout.logoMaxHeight, alignment: .bottomLeading)
        }

        private func select(_ item: BaseItemDto) {
            router.route(to: .item(item: item))
        }
    }
}

struct CinematicRecentlyAddedContentGroup: ContentGroup {

    let id = "cinematic-recently-added"
    let viewModel: CinematicSelectionContentGroupViewModel

    var _shouldBeResolved: Bool {
        viewModel.hasResumeItems && viewModel.recentlyAddedViewModel.elements.isNotEmpty
    }

    func body(with viewModel: CinematicSelectionContentGroupViewModel) -> some View {
        PosterHStackLibrarySection(
            viewModel: viewModel.recentlyAddedViewModel,
            group: viewModel.recentlyAddedGroup
        )
    }
}

final class CinematicSelectionContentGroupViewModel: ViewModel, WithRefresh {

    typealias Background = CinematicSelectionContentGroupViewModel

    let recentlyAddedGroup: PosterGroup<RecentlyAddedLibrary>
    let resumeViewModel: PagingLibraryViewModel<ResumeItemsLibrary>

    var recentlyAddedViewModel: PagingLibraryViewModel<RecentlyAddedLibrary> {
        recentlyAddedGroup.viewModel
    }

    var background: CinematicSelectionContentGroupViewModel {
        get { self }
        set {}
    }

    var hasResumeItems: Bool {
        resumeViewModel.elements.isNotEmpty
    }

    var hasContent: Bool {
        hasResumeItems || recentlyAddedViewModel.elements.isNotEmpty
    }

    init(
        resumeLibrary: ResumeItemsLibrary,
        recentlyAddedLibrary: RecentlyAddedLibrary
    ) {
        self.resumeViewModel = PagingLibraryViewModel(library: resumeLibrary, pageSize: 20)
        self.recentlyAddedGroup = PosterGroup(library: recentlyAddedLibrary)

        super.init()

        resumeViewModel.objectWillChange
            .merge(with: recentlyAddedViewModel.objectWillChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        Task {
            await refresh()
        }
    }

    func refresh() async {
        async let resume: Void = resumeViewModel.refresh()
        async let recentlyAdded: Void = recentlyAddedViewModel.refresh()

        _ = await (resume, recentlyAdded)
    }
}

private enum CinematicSelectionLayout {

    static let logoMaxHeight: CGFloat = 200
    static let logoMaxWidthPercentage: CGFloat = 0.4
}
