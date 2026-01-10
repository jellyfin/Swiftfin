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

struct ContentGroupView<Provider: _ContentGroupProvider>: View {

    @Router
    private var router

    @State
    private var _contentGroupOptions: _ContentGroupParentOption = .init()

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
    private func makeGroupBody<G: _ContentGroup>(_ group: G) -> some View {
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
                    ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { offset, group in
                        makeGroupBody(group)
                            .environment(\._contentGroupIndex, offset)
                            .eraseToAnyView()
                    }
                    .onPreferenceChange(_ContentGroupCustomizationKey.self) { value in
                        _contentGroupOptions = value
                    }
                }
//                .scrollTargetLayout()
                .edgePadding(
                    .bottom.inserting(
                        .top,
                        if: _contentGroupOptions.contains(.ignoreTopSafeArea)
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
//            .scrollTargetBehavior(.viewAligned)
            .ignoresSafeArea(
                edges: .horizontal.inserting(
                    .top,
                    if: _contentGroupOptions.contains(.ignoreTopSafeArea)
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

struct ContentGroupShimView: View {

    @StoredValue
    private var customContentGroup: ContentGroupProviderSetting

    init(id: String) {
        self._customContentGroup = StoredValue(
            .User.customContentGroup(id: id)
        )
    }

    @ViewBuilder
    private func unpack(_ provider: some _ContentGroupProvider) -> some View {
        ContentGroupView(provider: provider)
    }

    var body: some View {
        unpack(customContentGroup.provider)
            .eraseToAnyView()
            .id(customContentGroup.hashValue)
            .backport
            .onChange(of: customContentGroup) { oldValue, newValue in
                print("ContentGroupShimView: customContentGroup changed from \(oldValue) to \(newValue)")
            }
    }
}

struct CustomizePosterGroupSettings: View {

    @StoredValue
    private var parentPosterStyle: PosterDisplayConfiguration

    private let id: String

    init(id: String) {
        self._parentPosterStyle = StoredValue(.User.posterButtonStyle(parentID: id))

        self.id = id
    }

    var body: some View {
        Form {

            Section("ID") {
                Text(id)
            }

            Section {
                Picker(
                    L10n.posters,
                    selection: $parentPosterStyle.displayType
                )

                Picker(
                    "Size",
                    selection: $parentPosterStyle.size
                )
            }
        }
    }
}
