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
@_spi(Advanced) import SwiftUIIntrospect

struct EPGContentView: View {

    @State
    private var selectedGroup: ProgramBlock?

    @ObservedObject
    private var viewModel: EPGViewModel
    @ObservedObject
    private var channelsViewModel: PagingLibraryViewModel<EPGChannelsLibrary>

    private let selectedChannelID: String?
    private let action: (BaseItemDto) -> Void

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in
            HStack(spacing: 0) {
                EPGChannelColumn(
                    viewModel: viewModel,
                    channels: channelsViewModel.displayedElements,
                    selectedChannelID: selectedChannelID,
                    bottomInset: frame.safeAreaInsets.bottom
                ) { item in
                    action(item)
                }

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        EPGTimeRuler(viewModel: viewModel)
                    }
                    .scrollDisabled(true)
                    .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                        viewModel.proxy.registerHorizontal(scrollView)
                    }

                    Divider()

                    EPGCollectionView(
                        viewModel: viewModel,
                        channels: channelsViewModel.displayedElements,
                        bottomInset: frame.safeAreaInsets.bottom,
                        onReachedBottom: {
                            channelsViewModel.getNextPage()
                        },
                        onSelect: {
                            action($0)
                        },
                        onSelectGroup: {
                            selectedGroup = $0
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: channelsViewModel.displayedElements) {
            viewModel.getNextPage(channels: channelsViewModel.displayedElements)
        }
        .confirmationDialog(
            L10n.programs,
            isPresented: isPresentingGroup,
            titleVisibility: .hidden,
            presenting: selectedGroup
        ) { block in
            ForEach(block.programs, id: \.id) { program in
                Button(programTitle(for: program)) {
                    action(program)
                }
            }
        }
    }

    private var isPresentingGroup: Binding<Bool> {
        Binding(
            get: { selectedGroup != nil },
            set: { isPresented in
                if !isPresented {
                    selectedGroup = nil
                }
            }
        )
    }

    private func programTitle(for program: BaseItemDto) -> String {
        guard let start = program.startDate else { return program.displayTitle }
        return "\(start.formatted(date: .omitted, time: .shortened)) \(String.bullet) \(program.displayTitle)"
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
