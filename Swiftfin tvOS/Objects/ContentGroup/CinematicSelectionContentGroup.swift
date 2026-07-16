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
        CinematicSelectionView(
            viewModel: viewModel,
            source: .preferred
        )
    }
}

struct CinematicRecentlyAddedContentGroup: ContentGroup {

    let id = "cinematic-recently-added"
    let viewModel: CinematicSelectionContentGroupViewModel

    var _shouldBeResolved: Bool {
        viewModel.hasResumeItems && viewModel.recentlyAddedViewModel.elements.isNotEmpty
    }

    func body(with viewModel: CinematicSelectionContentGroupViewModel) -> some View {
        CinematicSelectionView(
            viewModel: viewModel,
            source: .recentlyAdded
        )
    }
}

final class CinematicSelectionContentGroupViewModel: ViewModel, WithRefresh {

    typealias Background = CinematicSelectionContentGroupViewModel

    let recentlyAddedViewModel: PagingLibraryViewModel<RecentlyAddedLibrary>
    let resumeViewModel: PagingLibraryViewModel<ResumeItemsLibrary>

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
        self.recentlyAddedViewModel = PagingLibraryViewModel(library: recentlyAddedLibrary, pageSize: 20)

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

private struct CinematicSelectionView: View {

    enum Source {
        case preferred
        case recentlyAdded
    }

    @Environment(\.frameForParentView)
    private var frameForParentView

    @ObservedObject
    var viewModel: CinematicSelectionContentGroupViewModel

    let source: Source

    @Router
    private var router

    private var items: [BaseItemDto] {
        switch source {
        case .preferred:
            viewModel.hasResumeItems ? viewModel.resumeViewModel.elements.elements : viewModel.recentlyAddedViewModel.elements.elements
        case .recentlyAdded:
            viewModel.recentlyAddedViewModel.elements.elements
        }
    }

    private var parentFrame: CGRect {
        frameForParentView[.scrollView, default: .zero].frame
    }

    private func itemSelectorImageSource(for item: BaseItemDto) -> ImageSource {
        if item.type == .episode {
            item.imageSource(
                itemID: item.seriesID,
                .logo,
                environment: ImageSourceOptions(
                    maxHeight: 100
                )
            )
        } else {
            item.imageSource(
                .logo,
                environment: ImageSourceOptions(
                    maxHeight: 100
                )
            )
        }
    }

    var body: some View {
        CinematicItemSelector(
            items: items
        ) { item in
            router.route(to: .item(item: item))
        } topContent: { item in
            ImageView(itemSelectorImageSource(for: item))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Text(item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
                .edgePadding(.leading)
                .aspectRatio(contentMode: .fit)
                .frame(height: 100, alignment: .bottomLeading)
        }
        .preference(
            key: ContentGroupCustomizationKey.self,
            value: .ignoreSafeAreaTop
        )
    }
}
