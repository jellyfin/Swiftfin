//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct LiveTVGuideContentView: View {

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

    var body: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            GuideDateMenu(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .focusSection()
            #endif

            GuideTimeRuler(
                scrollProxy: viewModel.scrollProxy,
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                now: viewModel.now,
                layout: .current
            )

            Divider()

            CollectionVGrid(
                uniqueElements: channels,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { channel in
                GuideChannelRow(
                    guideViewModel: viewModel,
                    channel: channel,
                    layout: .current,
                    playsOnSelect: playsOnSelect,
                    channelAction: { onSelectChannel(channel) },
                    programAction: onSelectProgram
                )
                #if os(tvOS)
                .ignoresSafeArea(edges: .horizontal)
                #endif
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                onReachedBottomEdge()
            }
            .scrollIndicators(.hidden)
            #if os(tvOS)
                .introspect(.scrollView, on: .tvOS(.v15...)) { scrollView in
                    scrollView.contentInsetAdjustmentBehavior = .never
                }
            #endif
        }
        .onFirstAppear {
            viewModel.selectedChannelID = selectedChannelID
            viewModel.loadPrograms(for: channels)
        }
        .backport
        .onChange(of: selectedChannelID) {
            viewModel.selectedChannelID = selectedChannelID
        }
        .backport
        .onChange(of: channels) {
            viewModel.loadPrograms(for: channels)
        }
        .backport
        .onChange(of: viewModel.startDate) {
            viewModel.loadPrograms(for: channels)
        }
    }
}
