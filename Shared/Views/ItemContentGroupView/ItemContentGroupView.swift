//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ItemContentGroupView: View {

    @Default(.Customization.itemViewType)
    private var itemViewType

    @Router
    private var router

    @State
    private var scrollViewOffset: CGFloat = 0

    @StateObject
    private var viewModel: ContentGroupViewModel<ItemGroupProvider>

    init(provider: ItemGroupProvider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

//        .modifier(OffsetOpacityModifier())

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ContentGroupContentView(viewModel: viewModel)
            }
            .edgePadding(.bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.scrollViewOffset, $scrollViewOffset)
        }
        .scrollViewOffset($scrollViewOffset)
        .ignoresSafeArea(edges: .horizontal)
        .scrollIndicators(.hidden)
        .trackingFrame(for: .scrollView)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
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
        .navigationTitle(viewModel.provider.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(isLoading: viewModel.background.is(.refreshing)) {}
    }
}
