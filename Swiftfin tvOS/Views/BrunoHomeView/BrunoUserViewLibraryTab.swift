//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoUserViewLibraryTab (tvOS only)

//
// Resolves Jellyfin user view(s) (libraries) at runtime, then shows their contents via the
// stock PagingLibraryView. Used for the Collections and Kids tabs, which target existing server
// libraries rather than item-type filters.
//
// Matching is flexible because the owner's server layout isn't fixed:
//   • Collections is one library named exactly "Collections" -> single ItemLibrary.
//   • Kids is split across separate libraries (e.g. "Kids Movies" + "Kids Shows") with no single
//     "Kids" user view, so we match several candidate names / a "kids" keyword and merge the
//     matches into one grid via BrunoCombinedLibrary.
struct BrunoUserViewLibraryTab: View {

    /// Title shown in the not-found message and used as the combined library's parent title.
    private let title: String
    /// Item types fetched when merging multiple libraries.
    private let itemTypes: [BaseItemKind]
    /// Filters applied on the single-library path, so a lone match is scoped identically to the
    /// merged case. `nil` keeps the library's own default (used by Collections).
    private let singleFilters: ItemFilterCollection?
    /// Predicate deciding whether a given user view belongs to this tab.
    private let matches: (BaseItemDto) -> Bool

    @State
    private var resolved: Resolved?
    @State
    private var didLoad = false

    private enum Resolved {
        case single(BaseItemDto)
        case combined([BaseItemDto])
    }

    /// Single library matched by exact (case-insensitive) display name — e.g. "Collections".
    init(viewName: String) {
        self.title = viewName
        self.itemTypes = [.movie, .series, .boxSet]
        self.singleFilters = nil
        self.matches = { $0.displayTitle.localizedCaseInsensitiveCompare(viewName) == .orderedSame }
    }

    /// One-or-more libraries matched by any exact name, or a keyword substring — e.g. Kids.
    init(
        title: String,
        anyOf names: [String],
        keyword: String?,
        itemTypes: [BaseItemKind]
    ) {
        self.title = title
        self.itemTypes = itemTypes
        self.singleFilters = ItemFilterCollection(itemTypes: itemTypes)
        self.matches = { view in
            let name = view.displayTitle
            if names.contains(where: { name.localizedCaseInsensitiveCompare($0) == .orderedSame }) {
                return true
            }
            if let keyword, name.localizedCaseInsensitiveContains(keyword) {
                return true
            }
            return false
        }
    }

    var body: some View {
        Group {
            switch resolved {
            case let .single(view):
                PagingLibraryView(library: ItemLibrary(parent: view, filters: singleFilters))
                    .toolbar(.hidden, for: .navigationBar)
            case let .combined(views):
                PagingLibraryView(
                    library: BrunoCombinedLibrary(
                        parents: views,
                        title: title,
                        id: "bruno-combined-\(title.lowercased())",
                        itemTypes: itemTypes
                    )
                )
                .toolbar(.hidden, for: .navigationBar)
            case nil:
                if didLoad {
                    notFound
                } else {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(Color.bruno.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onFirstAppear(perform: resolve)
    }

    private var notFound: some View {
        VStack(spacing: 16) {
            Text("Couldn't find “\(title)”")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("No Jellyfin library named “\(title)” for this user.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resolve() {
        Task { @MainActor in
            defer { didLoad = true }
            guard let session = Container.shared.currentUserSession() else { return }

            let parameters = Paths.GetUserViewsParameters(userID: session.user.id)
            let request = Paths.getUserViews(parameters: parameters)
            let response = try? await session.client.send(request)

            let matched = (response?.value.items ?? []).filter(matches)

            if matched.count == 1 {
                resolved = .single(matched[0])
            } else if matched.count > 1 {
                resolved = .combined(matched)
            }
        }
    }
}
