//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import IdentifiedCollections
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct LiveTVGuideContentView: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var viewModel: GuideViewModel
    @ObservedObject
    private var channelsViewModel: PagingLibraryViewModel<GuideChannelsLibrary>

    private let selectedChannelID: String?
    private let action: (BaseItemDto) -> Void

    private let layout = LiveTVGuideLayout()

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in
            let contentWidth = max(1, layout.width(from: viewModel.startDate, to: viewModel.endDate))
            let nowOffset = layout.width(from: viewModel.startDate, to: viewModel.now)

            HStack(spacing: 0) {
                GuideChannelColumn(
                    guideViewModel: viewModel,
                    channels: channelsViewModel.displayedElements,
                    bottomInset: frame.safeAreaInsets.bottom
                ) { item in
                    action(item)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        GuideTimeRuler(viewModel: viewModel)

                        Divider()

                        CollectionVGrid(
                            uniqueElements: channelsViewModel.displayedElements,
                            layout: .columns(
                                1,
                                insets: .init(
                                    top: 0,
                                    leading: 0,
                                    bottom: frame.safeAreaInsets.bottom,
                                    trailing: 0
                                ),
                                itemSpacing: 0,
                                lineSpacing: 0
                            )
                        ) { channel in
                            GuideChannelRow(
                                guideViewModel: viewModel,
                                channel: channel
                            ) { item in
                                action(item)
                            }
                            #if os(tvOS)
                            .ignoresSafeArea(edges: .horizontal)
                            #endif
                        }
                        .onReachedBottomEdge(offset: .offset(300)) {
                            channelsViewModel.getNextPage()
                        }
                        .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                            #if os(tvOS)
                            scrollView.contentInsetAdjustmentBehavior = .never
                            #endif

                            viewModel.proxy.registerVertical(scrollView)
                        }
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
        .onFirstAppear {
            viewModel.selectedChannelID = selectedChannelID
        }
        .backport
        .onChange(of: selectedChannelID) {
            viewModel.selectedChannelID = selectedChannelID
        }
        .backport
        .onChange(of: channelsViewModel.displayedElements) {
            viewModel.getNextPage(channels: channelsViewModel.displayedElements)
        }
    }
}

// MARK: - Initializers

extension LiveTVGuideContentView {

    /// Guide called from View.
    init(
        viewModel: GuideViewModel,
        channelsViewModel: PagingLibraryViewModel<GuideChannelsLibrary>,
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
        viewModel: GuideViewModel,
        channelsViewModel: PagingLibraryViewModel<GuideChannelsLibrary>,
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
