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
    private var contentView: some View {
        OffsetNavigationBar(headerMaxY: carriedUseOffsetNavigationBar ? carriedHeaderFrame.maxY : nil) {
            WithEnvironment(value: \.frameForParentView) { frameForParentView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {

                        // SwiftUI bug causes preference key changes to not propagate any higher
                        ContentGroupContentView(viewModel: viewModel)
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
//                    .edgePadding(.bottom)
                }
                .ignoresSafeArea(edges: .horizontal)
                .scrollIndicators(.hidden)
                .overlay(alignment: .top) {
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
        .backport
        .onChange(of: viewModel.state) { _, newValue in
            print("ContentGroupView: state changed to \(newValue)")
        }
        .backport
        .onChange(of: viewModel.background.states) { oldValue, newValue in
            print("ContentGroupView: background states changed from \(oldValue) to \(newValue)")
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
//        .navigationTitle(viewModel.provider.displayTitle)
        .backport
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
//        .toolbarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(isLoading: viewModel.background.is(.refreshing)) {}
    }
}
