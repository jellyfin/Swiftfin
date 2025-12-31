//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ItemContentGroupView<Provider: _ContentGroupProvider>: View {

    @Router
    private var router

    @State
    private var carriedHeaderFrame: CGRect = .zero
    @State
    private var carriedUseOffsetNavigationBar: Bool = false

    @StateObject
    private var viewModel: ContentGroupViewModel<Provider>

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    @ViewBuilder
    private func makeGroupBody<G: _ContentGroup>(_ group: G) -> some View {
        group.body(with: group.viewModel)
    }

    @ViewBuilder
    private var contentView: some View {
        OffsetNavigationBar(headerMaxY: carriedUseOffsetNavigationBar ? carriedHeaderFrame.maxY : nil) {
            WithEnvironment(value: \.frameForParentView) { frameForParentView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {

                        // SwiftUI bug causes preference key changes to not propagate any higher
                        ForEach(viewModel.groups, id: \.id) { group in
                            makeGroupBody(group)
                                .eraseToAnyView()
                        }
                        .onPreferenceChange(_UseOffsetNavigationBarKey.self) { value in
                            carriedUseOffsetNavigationBar = value
                        }
                        .onPreferenceChange(ScrollViewHeaderFrameKey.self) { value in
                            carriedHeaderFrame = value
                        }
                    }
                    .edgePadding(
                        .bottom.inserting(
                            .top,
                            if: !carriedUseOffsetNavigationBar
                        )
                    )
                }
                .ignoresSafeArea(edges: .horizontal)
                .scrollIndicators(.hidden)
                .overlay(alignment: .top) {
                    if carriedUseOffsetNavigationBar, UIDevice.isPhone {
                        Rectangle()
                            .fill(Material.ultraThin)
                            .maskLinearGradient()
                            .frame(height: frameForParentView[.navigationStack, default: .zero].safeAreaInsets.top)
                            .offset(y: -frameForParentView[.scrollView, default: .zero].safeAreaInsets.top)
                            .colorScheme(.dark)
                            .hidden(!carriedUseOffsetNavigationBar)
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
                contentView
                    .navigationTitle(viewModel.provider.displayTitle)
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .backport
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(isLoading: viewModel.background.is(.refreshing)) {}
    }
}
