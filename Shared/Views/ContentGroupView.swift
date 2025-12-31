//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import SwiftUI

struct ContentGroupView<Provider: _ContentGroupProvider>: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ContentGroupViewModel<Provider>

    @TabItemSelected
    private var tabItemSelected

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
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
                    ForEach(viewModel.groups, id: \.id) { group in
                        makeGroupBody(group)
                            .eraseToAnyView()
                    }
                }
                .edgePadding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(edges: .horizontal)
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
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {

            if viewModel.background.is(.refreshing) {
                ProgressView()
            }

//            Button("Refresh", systemImage: "arrow.clockwise.circle") {
//                viewModel.background.refresh()
//            }
//
//            Button("Content") {
//                router.route(
//                    to: .init(
//                        id: "test-content",
//                        style: .sheet,
//                        content: {
//                            CustomContentGroupSettingsView(id: "asdf")
//                        }
//                    )
//                )
//            }
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
