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

struct BasicLibraryGrouping: Displayable, Hashable, Identifiable, Storable {
    let displayTitle: String
    let id: String
}

struct _TitledLibraryParent: _LibraryParent {

    let displayTitle: String
    let libraryID: String
}

// protocol WithGroupingLibrary {
//
//    associatedtype Grouping: Displayable & Identifiable
//
//    var groupings: (defaultSelection: Grouping, elements: [Grouping])? { get }
// }

struct BaseItemLibraryEnvironment: WithDefaultValue {

    let grouping: BasicLibraryGrouping?
    let filters: ItemFilterCollection

    static var `default`: Self {
        .init(
            grouping: nil,
            filters: .init()
        )
    }
}

extension BaseItemDto: _LibraryParent {

    var libraryID: String {
        id ?? "unknown"
    }

    var _groupings: (defaultSelection: BasicLibraryGrouping, elements: [BasicLibraryGrouping])? {
        switch collectionType {
        case .tvshows:
            let episodes = BasicLibraryGrouping(displayTitle: L10n.episodes, id: "episodes")
            let series = BasicLibraryGrouping(displayTitle: L10n.series, id: "series")
            return (series, [episodes, series])
        default:
            return nil
        }
    }

    func _supportedItemTypes(for grouping: BasicLibraryGrouping?) -> [BaseItemKind] {
        if self.collectionType == .folders {
            return BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        }

        if collectionType == .tvshows {
            if let grouping, grouping.id == "episodes" {
                return [.episode]
            } else {
                return [.series]
            }
        }

        return BaseItemKind.supportedCases
    }

    func _isRecursiveCollection(for grouping: BasicLibraryGrouping?) -> Bool {
        guard let collectionType, type != .userView else { return true }

        if let grouping, grouping.id == "episodes" {
            return true
        }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

@MainActor
protocol _ContentGroup<ViewModel>: Displayable, Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: _ContentGroupViewModel

    var id: String { get }

    func makeViewModel() -> ViewModel

    @ViewBuilder
    func body(with viewModel: ViewModel) -> Body
}

protocol _ContentGroupViewModel: WithRefresh {}

struct VoidContentGroupViewModel: _ContentGroupViewModel {
    func refresh() {}
    func refresh() async throws {}
}

@MainActor
protocol _ContentGroupProvider: Displayable, SystemImageable {

    associatedtype Environment = Void

    var id: String { get }
    var environment: Environment { get }

    func makeGroups(environment: Environment) async throws -> [any _ContentGroup]
}

extension _ContentGroupProvider where Environment == Void {
    var environment: Void { () }
}

extension _ContentGroupProvider where Environment: WithDefaultValue {
    var environment: Environment { .default }
}

extension _ContentGroupProvider where Environment == Void {
    func makeGroups() async throws -> [any _ContentGroup] {
        try await makeGroups(environment: ())
    }
}

struct EmptyContentGroup: _ContentGroup {

    let displayTitle: String = "Empty"
    let id: String = UUID().uuidString

    func makeViewModel() -> VoidContentGroupViewModel {
        .init()
    }

    func body(with viewModel: VoidContentGroupViewModel) -> some View {
        EmptyView()
    }
}

struct PosterGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: Poster {

    var displayTitle: String {
        library.parent.displayTitle
    }

    let id: String
    let library: Library
    let posterDisplayType: PosterDisplayType
    let posterSize: PosterDisplayType.Size

    init(
        id: String,
        library: Library,
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .small
    ) {
        self.id = id
        self.library = library
        self.posterDisplayType = posterDisplayType
        self.posterSize = posterSize
    }

//    init(library: Library) {
//        self.id = library.parent.libraryID
//        self.library = library
//    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
//        WithPosterButtonStyle(id: id) {
        _PosterSection(viewModel: viewModel, group: self)
            .posterStyle(for: BaseItemDto.self) { environment, _ in
                var environment = environment
                environment.displayType = posterDisplayType
                environment.size = posterSize
                return environment
            }
//        }
    }

    func makeViewModel() -> PagingLibraryViewModel<Library> {
        .init(library: library)
    }
}

struct WithPosterButtonStyle<Content: View>: View {

    @StoredValue
    private var parentPosterStyle: PosterStyleEnvironment

    private let content: Content
    private let id: String

    init(id: String, @ViewBuilder content: () -> Content) {
        self._parentPosterStyle = StoredValue(.User.posterButtonStyle(parentID: id))

        self.id = id
        self.content = content()
    }

    var body: some View {
        content
            .posterStyle(for: BaseItemDto.self) { environment, _ in
                var environment = environment
                environment.displayType = parentPosterStyle.displayType
                environment.size = parentPosterStyle.size
                return environment
            }
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
                library: PagingItemLibrary(
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

    func makeGroups(environment: ()) async throws -> [any _ContentGroup] {
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

            ForEach(temporaryCustomContentGroup.groups, id: \.hashValue) { groupSetting in
                Button(groupSetting.group.displayTitle) {
                    temporaryCustomContentGroup.groups
                        .removeAll(where: { $0 == groupSetting })
                }
            }
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
            .buttonStyle(.toolbarPill)
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
