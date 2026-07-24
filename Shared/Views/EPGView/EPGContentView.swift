//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import IdentifiedCollections
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct EPGContentView: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var viewModel: EPGViewModel
    @ObservedObject
    private var channelsViewModel: PagingLibraryViewModel<EPGChannelsLibrary>

    private let selectedChannelID: String?
    private let action: (BaseItemDto) -> Void

    private let layout = EPGLayout()

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in
            let contentWidth = max(1, layout.width(from: viewModel.startDate, to: viewModel.endDate))
            let nowOffset = layout.width(from: viewModel.startDate, to: viewModel.now)

            HStack(spacing: 0) {
                EPGChannelColumn(
                    viewModel: viewModel,
                    channels: channelsViewModel.displayedElements,
                    selectedChannelID: selectedChannelID,
                    bottomInset: frame.safeAreaInsets.bottom
                ) { item in
                    action(item)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        EPGTimeRuler(viewModel: viewModel)

                        Divider()

                        EPGCollectionView(
                            viewModel: viewModel,
                            channels: channelsViewModel.displayedElements,
                            bottomInset: frame.safeAreaInsets.bottom,
                            onReachedBottom: { channelsViewModel.getNextPage() },
                            onSelect: { action($0) }
                        )
                    }
                    .frame(width: contentWidth)
                    .overlay(alignment: .topLeading) {
                        if viewModel.now >= viewModel.startDate {
                            Rectangle()
                                .fill(accentColor)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .offset(x: nowOffset)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                    #if os(tvOS)
                    scrollView.contentInsetAdjustmentBehavior = .never
                    #endif

                    viewModel.proxy.register(scrollView, centeringOn: nowOffset)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .backport
        .onChange(of: channelsViewModel.displayedElements) {
            viewModel.getNextPage(channels: channelsViewModel.displayedElements)
        }
    }
}

// MARK: - Initializers

extension EPGContentView {

    /// Guide called from View.
    init(
        viewModel: EPGViewModel,
        channelsViewModel: PagingLibraryViewModel<EPGChannelsLibrary>,
        action: @escaping (BaseItemDto) -> Void
    ) {
        self.init(
            viewModel: viewModel,
            channelsViewModel: channelsViewModel,
            selectedChannelID: nil,
            action: action
        )
    }

    /// Guide called from Supplement.
    init(
        viewModel: EPGViewModel,
        channelsViewModel: PagingLibraryViewModel<EPGChannelsLibrary>,
        playing channelID: String?,
        action: @escaping (BaseItemDto) -> Void
    ) {
        self.init(
            viewModel: viewModel,
            channelsViewModel: channelsViewModel,
            selectedChannelID: channelID,
            action: action
        )
    }
}
