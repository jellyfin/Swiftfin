//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoKidsView (tvOS only)

//
// The Kids tab: resolves the owner's kids library/libraries (which may be split into separate
// Movies and Shows libraries) and shows their merged contents, with All / Movies / TV Shows
// filter cards. The filter swaps the item types fed to BrunoCombinedLibrary, so it works whether
// kids content lives in one library or several.
struct BrunoKidsView: View {

    @StateObject
    private var viewModel = BrunoKidsViewModel()

    @State
    private var filter: KidsFilter = .all

    enum KidsFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case movies = "Movies"
        case shows = "TV Shows"

        var id: String {
            rawValue
        }

        var itemTypes: [BaseItemKind] {
            switch self {
            case .all: [.movie, .series]
            case .movies: [.movie]
            case .shows: [.series]
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.parents.isEmpty {
                notFound
            } else {
                PagingLibraryView(
                    library: BrunoCombinedLibrary(
                        parents: viewModel.parents,
                        title: "Kids",
                        id: "bruno-kids-\(filter.id)",
                        itemTypes: filter.itemTypes
                    )
                )
                // Rebuild the grid when the filter changes (new item-type scope).
                .id(filter)
                    // safeAreaInset (not a VStack) so the bar sits above while the grid's content
                    // insets below it — robust even though PagingLibraryView ignores vertical safe area.
                    .safeAreaInset(edge: .top, spacing: 0) {
                        filterBar
                    }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load() }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 16) {
            ForEach(KidsFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    Text(option.rawValue)
                        .font(.brunoBody(24, weight: .semibold))
                        .foregroundStyle(option == filter ? Color.bruno.accent : Color.bruno.fg)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.card)
            }

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .focusSection()
    }

    private var notFound: some View {
        VStack(spacing: 16) {
            Text("Couldn't find “Kids”")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("No Jellyfin kids library for this user.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BrunoKidsViewModel

@MainActor
final class BrunoKidsViewModel: ViewModel {

    @Published
    private(set) var parents: [BaseItemDto] = []
    @Published
    private(set) var isLoading = true

    /// Candidate library names, plus a "kids" keyword fallback (matches "Kids Movies"/"Kids Shows"/…).
    private static let candidates = ["Kids", "Kids Movies", "Kids Shows", "Kids TV", "Kids Movies & Shows"]

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let response = try? await userSession.client.send(Paths.getUserViews(parameters: parameters))

        parents = (response?.value.items ?? []).filter { view in
            let name = view.displayTitle
            if Self.candidates.contains(where: { name.localizedCaseInsensitiveCompare($0) == .orderedSame }) {
                return true
            }
            return name.localizedCaseInsensitiveContains("kids")
        }

        isLoading = false
    }
}
