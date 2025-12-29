//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: break out, cleanup

typealias ContentGroupBuilder = ArrayBuilder<any _ContentGroup>

@MainActor
protocol _ContentGroup<ViewModel>: Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: WithRefresh

    var id: String { get }
    var viewModel: ViewModel { get }

    @ViewBuilder
    func body(with viewModel: ViewModel) -> Body
}

extension _ContentGroup where ViewModel == Empty {
    var viewModel: Empty { .init() }
}

@MainActor
protocol _ContentGroupProvider: Displayable {

    associatedtype Environment = Empty

    var id: String { get }
    var environment: Environment { get set }

    @ContentGroupBuilder
    func makeGroups(environment: Environment) async throws -> [any _ContentGroup]
}

extension _ContentGroupProvider where Environment == Empty {
    var environment: Empty {
        get { .init() }
        set {}
    }
}

struct PillGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: Displayable {

    let displayTitle: String
    let id: String
    let library: Library
    let viewModel: PagingLibraryViewModel<Library>

    init(
        displayTitle: String,
        id: String,
        library: Library
    ) {
        self.displayTitle = displayTitle
        self.id = id
        self.library = library
        self.viewModel = .init(library: library)
    }

    #if os(tvOS)
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        EmptyView()
    }
    #else
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        WithRouter { router in
            PillHStack(
                title: displayTitle,
                data: viewModel.elements
            ) { element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .musicArtist,
                                .person,
                            ],
                            parent: .init(id: "\(element.id)"),
                            environment: .init(
                                filters: .init(
                                    genres: [.init(
                                        stringLiteral: "\(element.id)"
                                    )]
                                )
                            )
                        )
                    )
                )
            }
        }
    }
    #endif
}

struct PosterGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: LibraryElement {

    var displayTitle: String {
        library.parent.displayTitle
    }

    let id: String
    let library: Library
    let posterDisplayType: PosterDisplayType
    let posterSize: PosterDisplayType.Size
    let viewModel: PagingLibraryViewModel<Library>

    init(
        id: String = UUID().uuidString,
        library: Library,
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .small
    ) {
        self.id = id
        self.library = library
        self.posterDisplayType = posterDisplayType
        self.posterSize = posterSize
        self.viewModel = .init(library: library)
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        PosterHStackLibrarySection(viewModel: viewModel, group: self)
    }
}

struct WithPosterButtonStyle<Content: View>: View {

    @StoredValue
    private var parentPosterStyle: PosterDisplayConfiguration

    private let content: Content
    private let id: String

    init(id: String, @ViewBuilder content: () -> Content) {
        self._parentPosterStyle = StoredValue(.User.posterButtonStyle(parentID: id))

        self.id = id
        self.content = content()
    }

    var body: some View {
        content
    }
}

@MainActor
enum ContentGroupProviderSetting: Equatable, Hashable, Storable {

    case `default`
    case custom(StoredContentGroupProvider)

    var provider: any _ContentGroupProvider {
        switch self {
        case .default:
            DefaultContentGroupProvider()
        case let .custom(provider):
            provider
        }
    }
}

@MainActor
enum ContentGroupSetting: Equatable, Hashable, Storable {

    case continueWatching(
        id: String,
        posterDisplayType: PosterDisplayType = .landscape,
        posterSize: PosterDisplayType.Size = .medium
    )

    case nextUp(
        id: String,
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .medium
    )

    case library(
        id: String,
        displayTitle: String,
        libraryID: String,
        filters: ItemFilterCollection = .init(),
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .medium
    )

    var group: any _ContentGroup {
        switch self {
        case let .continueWatching(
            id: id,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: ContinueWatchingLibrary(),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        case let .nextUp(
            id: id,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: NextUpLibrary(),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        case let .library(
            id: id,
            displayTitle: displayTitle,
            libraryID: libraryID,
            filters: filters,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: ItemLibrary(
                    parent: .init(id: libraryID, name: displayTitle),
                    filters: filters
                ),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        }
    }
}

struct StoredContentGroupProvider: _ContentGroupProvider, Equatable, Hashable, Storable {

    var displayTitle: String
    var id: String
    var systemImage: String
    var groups: [ContentGroupSetting]

    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {
        groups.map(\.group)
    }
}

struct CustomContentGroupSettingsView: View {

    @StoredValue
    private var customContentGroup: ContentGroupProviderSetting

    @State
    private var temporaryCustomContentGroup: StoredContentGroupProvider = .init(
        displayTitle: "Custom",
        id: "custom_\(UUID().uuidString)",
        systemImage: "heart.fill",
        groups: [.nextUp(
            id: UUID().uuidString,
            posterDisplayType: .portrait,
            posterSize: .small
        )]
    )

    @State
    private var displayTitle: String = ""

    init(id: String) {
        self._customContentGroup = StoredValue(
            .User.customContentGroup(id: id)
        )

        if case let .custom(provider) = customContentGroup {
            self._temporaryCustomContentGroup = State(
                initialValue: provider
            )
        }
    }

    var body: some View {
        Form {

            TextField(L10n.title, text: $temporaryCustomContentGroup.displayTitle)

//            ForEach(temporaryCustomContentGroup.groups, id: \.hashValue) { groupSetting in
//                Button(groupSetting.group.displayTitle) {
//                    temporaryCustomContentGroup.groups
//                        .removeAll(where: { $0 == groupSetting })
//                }
//            }
        }
        .navigationTitle("Custom")
        .topBarTrailing {
            Button("Add") {
                temporaryCustomContentGroup.groups.append(
                    .library(
                        id: UUID().uuidString,
                        displayTitle: "Movies",
                        libraryID: "f137a2dd21bbc1b99aa5c0f6bf02a805",
                        filters: .init(),
                        posterDisplayType: PosterDisplayType.allCases.randomElement()!,
                        posterSize: PosterDisplayType.Size.allCases.randomElement()!
                    )
//                    .nextUp(
//                        posterDisplayType: PosterDisplayType.allCases.randomElement()!,
//                        posterSize: PosterDisplayType.Size.allCases.randomElement()!
//                    )
                )
            }

            Button("Save") {
                customContentGroup = .custom(
                    temporaryCustomContentGroup
                )
            }
//            .buttonStyle(.toolbarPill)
        }
    }
}

extension StoredValues.Keys.User {

    static func customContentGroup(id: String) -> StoredValues.Key<ContentGroupProviderSetting> {
        StoredValues.Keys.CurrentUserKey(
            "__customContentGroup_\(id)",
            domain: "__customContentGroup_\(id)",
            default: .custom(
                .init(
                    displayTitle: "Custom \(id)",
                    id: id,
                    systemImage: "heart.fill",
                    groups: [.nextUp(
                        id: UUID().uuidString,
                        posterDisplayType: .portrait,
                        posterSize: .small
                    )]
                )
            )
        )
    }
}
