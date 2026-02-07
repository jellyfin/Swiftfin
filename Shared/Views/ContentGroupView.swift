//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import SwiftUI

struct ContentGroupView<Provider: ContentGroupProvider>: View {

    @Router
    private var router

    @State
    private var contentGroupOptions: ContentGroupParentOption = .init()

    @StateObject
    private var viewModel: ContentGroupViewModel<Provider>

    @TabItemSelected
    private var tabItemSelected

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    init(viewModel: ContentGroupViewModel<Provider>) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @ViewBuilder
    private func makeGroupBody(_ group: some ContentGroup) -> some View {
        group.body(with: group.viewModel)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id("top")

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { _, group in
                        makeGroupBody(group)
                            .eraseToAnyView()
                    }
                    .onPreferenceChange(ContentGroupCustomizationKey.self) { value in
                        contentGroupOptions = value
                    }
                }
                .edgePadding(
                    .bottom.inserting(
                        .top,
                        if: contentGroupOptions.contains(.ignoreTopSafeArea)
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(
                edges: .horizontal.inserting(
                    .top,
                    if: contentGroupOptions.contains(.ignoreTopSafeArea)
                )
            )
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.background.refresh()
            }
            .onReceive(tabItemSelected) { event in
                if event.isRepeat, event.isRoot {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        .trackingFrame(for: .scrollView)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.groups.isEmpty {
                    // TODO: non-error like empty view
                    ErrorView(error: ErrorMessage(L10n.noResults))
                        .refreshable {
                            viewModel.refresh()
                        }
                } else {
                    contentView
                }
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .navigationTitle(viewModel.provider.displayTitle)
        .backport
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {

            if viewModel.background.is(.refreshing) {
                ProgressView()
            }
        }
//        .sinceLastDisappear { interval in
//            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
//                viewModel.send(.backgroundRefresh)
//                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
//            }
//        }
    }
}
