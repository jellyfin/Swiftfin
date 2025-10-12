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
protocol _ContentGroup: Displayable, Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: __PagingLibaryViewModel

    var id: String { get }

    func body(with viewModel: ViewModel) -> Body

    func makeViewModel() -> ViewModel
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

struct PosterGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: Poster {

    var displayTitle: String {
        library.parent.displayTitle
    }

    let id: String

    let library: Library

    init(id: String, library: Library) {
        self.id = id
        self.library = library
    }

    init(library: Library) {
        self.id = library.parent.libraryID
        self.library = library
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        WithPosterButtonStyle(id: id) {
            _PosterSection(viewModel: viewModel, group: self)
        }
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

// @MainActor
// struct PosterGroup: Identifiable, Storable {
//
//    @MainActor
//    enum Library: Storable {
//
//        case continueWatching(ContinueWatchingPosterGroup)
//        case latestInLibrary(LatestInLibraryPosterGroup)
//        case nextUp(NextUpPosterGroup)
//        case recentlyAdded
//        case library(id: String, name: String, filters: ItemFilterCollection)
//        case `static`(id: String, name: String, elements: [any Poster])
//    }
//
//    enum RowStyle: Storable {
//        case carousel
//        case scroll
//    }

//    let library: Library
//    let rowStyle: RowStyle
//
//    let posterDisplayType: PosterDisplayType
//    let posterSize: PosterDisplayType.Size
//
//    let id = UUID().uuidString
// }

// struct GenresContentGroup: _ContentGroup {
//
//    let id = "genres"
//    let displayTitle: String = L10n.genres
//
//    let genres: [BaseItemDto]
//
//    func makeViewModel() -> PagingLibraryViewModel<StaticLibrary<BaseItemDto>> {
//        .init(library: .init(title: displayTitle, id: id, elements: genres))
//    }
//
//    func body(with viewModel: PagingLibraryViewModel<StaticLibrary<BaseItemDto>>) -> some View {
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(genres, id: \.displayTitle) { genre in
//                    Text(genre.displayTitle)
//                        .padding()
//                        .background {
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(Color.accentColor.opacity(0.2))
//                        }
//                }
//            }
//        }
//        .frame(height: 100)
//    }
// }
