//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct LiveTVGuideContentView: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var viewModel: GuideViewModel

    private let channels: [BaseItemDto]
    private let selectedChannelID: String?
    private let playsOnSelect: Bool
    private let onReachedBottomEdge: () -> Void
    private let onSelectChannel: (BaseItemDto) -> Void
    private let onSelectProgram: (BaseItemDto) -> Void

    init(
        viewModel: GuideViewModel,
        channels: [BaseItemDto],
        selectedChannelID: String? = nil,
        playsOnSelect: Bool = false,
        onReachedBottomEdge: @escaping () -> Void,
        onSelectChannel: @escaping (BaseItemDto) -> Void,
        onSelectProgram: @escaping (BaseItemDto) -> Void
    ) {
        self.viewModel = viewModel
        self.channels = channels
        self.selectedChannelID = selectedChannelID
        self.playsOnSelect = playsOnSelect
        self.onReachedBottomEdge = onReachedBottomEdge
        self.onSelectChannel = onSelectChannel
        self.onSelectProgram = onSelectProgram
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * GuideLayout.current.pointsPerMinute)
    }

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in
            contentBody(bottomInset: frame.safeAreaInsets.bottom)
        }
        .onFirstAppear {
            viewModel.selectedChannelID = selectedChannelID
            viewModel.refresh(channels: channels)
        }
        .backport
        .onChange(of: selectedChannelID) {
            viewModel.selectedChannelID = selectedChannelID
        }
        .backport
        .onChange(of: channels) {
            viewModel.refresh(channels: channels)
        }
        .backport
        .onChange(of: viewModel.startDate) {
            viewModel.refresh(channels: channels)
        }
    }

    @ViewBuilder
    private func contentBody(bottomInset: CGFloat) -> some View {
        let layout = GuideLayout.current
        let contentWidth = max(1, width(from: viewModel.startDate, to: viewModel.endDate))
        let nowOffset = width(from: viewModel.startDate, to: viewModel.now)

        HStack(spacing: 0) {
            GuideChannelColumn(
                guideViewModel: viewModel,
                channels: channels,
                layout: layout,
                playsOnSelect: playsOnSelect,
                bottomInset: bottomInset,
                onSelectChannel: onSelectChannel
            )

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    GuideTimeRuler(
                        startDate: viewModel.startDate,
                        endDate: viewModel.endDate,
                        layout: layout
                    )

                    Divider()

                    CollectionVGrid(
                        uniqueElements: channels,
                        layout: .columns(
                            1,
                            insets: .init(top: 0, leading: 0, bottom: bottomInset, trailing: 0),
                            itemSpacing: 0,
                            lineSpacing: 0
                        )
                    ) { channel in
                        GuideChannelRow(
                            guideViewModel: viewModel,
                            channel: channel,
                            layout: layout,
                            playsOnSelect: playsOnSelect,
                            programAction: onSelectProgram
                        )
                        #if os(tvOS)
                        .ignoresSafeArea(edges: .horizontal)
                        #endif
                    }
                    .onReachedBottomEdge(offset: .offset(300)) {
                        onReachedBottomEdge()
                    }
                    .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                        #if os(tvOS)
                        scrollView.contentInsetAdjustmentBehavior = .never
                        #endif

                        viewModel.verticalSync.register(scrollView)
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

                viewModel.scrollProxy.register(scrollView, nowOffset: nowOffset)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
