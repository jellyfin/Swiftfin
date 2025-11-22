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

struct PosterHStackLibrarySection<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    @Router
    private var router

    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    private let group: PosterGroup<Library>

    init(viewModel: PagingLibraryViewModel<Library>, group: PosterGroup<Library>) {
        self.group = group
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            PosterHStack(
                elements: viewModel.elements,
                type: .portrait
            ) {
                element,
                    namespace in
                //                router.route(to: .posterGroupPosterButtonStyle(id: viewModel.library.parent.libraryID))

                switch element {
                case let element as BaseItemDto:
                    switch element.type {
                    case .program, .liveTvChannel, .tvProgram, .tvChannel:
                        router.route(
                            to: .videoPlayer(
                                provider: element.getPlaybackItemProvider(userSession: viewModel.userSession)
                            )
                        )
                    default:
                        router.route(to: .item(item: element), in: namespace)
                    }
                default: ()
                }
            } header: {
                Header(title: viewModel.library.parent.displayTitle) {
                    router.route(to: .library(library: viewModel.library))
                }
            }
            .animation(.linear(duration: 0.2), value: viewModel.elements)
            //                .posterStyle(for: BaseItemDto.self) { environment, _ in
            //                    var environment = environment
            //                    environment.displayType = group.posterDisplayType
            //                    environment.size = group.posterSize
            //                    if let progress = item.progress, let startSeconds = item.startSeconds {
            //                        environment.overlay = PosterProgressBar(
            //                            title: startSeconds.formatted(.runtime),
            //                            progress: progress,
            //                            posterDisplayType: environment.displayType
            //                        )
            //                        .eraseToAnyView()
            //                    }
            //                    return environment
            //                }
        }
    }
}

extension PosterHStackLibrarySection {

    struct Header: View {

        let title: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 3) {
                    Text(title)
                        .foregroundStyle(.primary)
                        .font(.title2)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .fontWeight(.semibold)
            }
            .foregroundStyle(.primary, .secondary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: Text("Open library"), action)
            .edgePadding(.horizontal)
        }
    }
}

struct ContentGroupContentView<Provider: _ContentGroupProvider>: View {

    @ObservedObject
    var viewModel: ContentGroupViewModel<Provider>

    private func makeGroupBody(
        with libraryViewModel: any WithRefresh,
        group: any _ContentGroup
    ) -> some View {

        @ViewBuilder
        func _makeSection<Group: _ContentGroup>(_ group: Group) -> some View {
            if let castedLibrary = libraryViewModel as? Group.ViewModel {
                group.body(with: castedLibrary)
            } else {
                AssertionFailureView("Mismatched library casting")
            }
        }

        return _makeSection(group)
            .eraseToAnyView()
    }

    var body: some View {
        ForEach(viewModel.sections, id: \.group.id) { section in
            makeGroupBody(with: section.viewModel, group: section.group)
        }
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

struct ContentGroupView<Provider: _ContentGroupProvider>: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ContentGroupViewModel<Provider>

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ContentGroupContentView(viewModel: viewModel)
            }
            .edgePadding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea(.container, edges: [.horizontal])
        .scrollIndicators(.hidden)
        .refreshable {
//            try? await viewModel.refresh()
            try? await viewModel.background.refresh()
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
        .navigationBarTitleDisplayMode(router.isRootOfPath ? .automatic : .inline)
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

            #if os(iOS)
//            SettingsBarButton(
//                server: viewModel.userSession.server,
//                user: viewModel.userSession.user
//            ) {
//                router.route(to: .settings)
//            }
            #endif
        }
//        .sinceLastDisappear { interval in
//            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
//                viewModel.send(.backgroundRefresh)
//                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
//            }
//        }
    }
}

struct CustomizePosterGroupSettings: View {

    @StoredValue
    private var parentPosterStyle: PosterStyleEnvironment

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
                CaseIterablePicker(
                    L10n.posters,
                    selection: $parentPosterStyle.displayType
                )

                CaseIterablePicker(
                    "Size",
                    selection: $parentPosterStyle.size
                )
            }
        }
    }
}
