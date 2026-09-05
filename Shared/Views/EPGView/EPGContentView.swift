//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct EPGLoadableView<Content: View>: View {

    @ObservedObject
    private var viewModel: EPGViewModel

    private let content: Content

    init(
        viewModel: EPGViewModel,
        @ViewBuilder content: () -> Content
    ) {
        self.viewModel = viewModel
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
        case .error:
            if let error = viewModel.error {
                ErrorView(error: error)
            }
        case .content:
            if viewModel.channels.isEmpty {
                ContentUnavailableView(L10n.noPrograms, systemImage: "tv")
            } else {
                content
            }
        }
    }
}

struct EPGContentView: View {

    @ObservedObject
    private var viewModel: EPGViewModel

    @StateObject
    private var proxy = EPGScrollProxy()

    @State
    private var selectedGroup: ProgramBlock?

    private let action: (BaseItemDto) -> Void
    private let selectedChannelID: String?

    init(
        viewModel: EPGViewModel,
        selectedChannelID: String? = nil,
        action: @escaping (BaseItemDto) -> Void
    ) {
        self.action = action
        self.selectedChannelID = selectedChannelID
        self.viewModel = viewModel
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

    // TODO: turn into FormatStyle
    private func programTitle(for program: BaseItemDto) -> String {
        guard let start = program.startDate else { return program.displayTitle }
        return "\(start.formatted(date: .omitted, time: .shortened)) \(String.bullet) \(program.displayTitle)"
    }

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in
            HStack(spacing: 0) {
                EPGChannelColumn(
                    viewModel: viewModel,
                    proxy: proxy,
                    selectedChannelID: selectedChannelID,
                    bottomInset: frame.safeAreaInsets.bottom
                ) { item in
                    action(item)
                }

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        EPGTimeRuler(viewModel: viewModel)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .scrollDisabled(true)
                    .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                        proxy.registerHorizontal(scrollView)
                    }

                    Divider()

                    EPGCollectionView(
                        viewModel: viewModel,
                        proxy: proxy,
                        bottomInset: frame.safeAreaInsets.bottom,
                        onReachedBottom: {
                            viewModel.getNextPage()
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
        .confirmationDialog(
            L10n.programs,
            isPresented: isPresentingGroup,
            titleVisibility: .hidden,
            presenting: selectedGroup
        ) { block in
            ForEach(block.programs) { program in
                Button(programTitle(for: program)) {
                    action(program)
                }
            }
        }
        .onDisappear {
            proxy.disconnect()
        }
    }
}
