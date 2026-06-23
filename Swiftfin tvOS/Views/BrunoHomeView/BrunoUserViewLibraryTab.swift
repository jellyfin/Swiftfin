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
// Resolves a Jellyfin user view (library) by its display name at runtime, then shows that
// library's contents via the stock PagingLibraryView. Used for the Collections and Kids tabs,
// which target existing server libraries rather than item-type filters.
struct BrunoUserViewLibraryTab: View {

    /// Display name of the user view to open, e.g. "Collections" or "Kids".
    let viewName: String

    @State
    private var matchedView: BaseItemDto?
    @State
    private var didLoad = false

    var body: some View {
        Group {
            if let matchedView {
                PagingLibraryView(library: ItemLibrary(parent: matchedView))
                    .toolbar(.hidden, for: .navigationBar)
            } else if didLoad {
                notFound
            } else {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onFirstAppear(perform: resolve)
    }

    private var notFound: some View {
        VStack(spacing: 16) {
            Text("Couldn't find “\(viewName)”")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("No Jellyfin library named “\(viewName)” for this user.")
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

            matchedView = (response?.value.items ?? [])
                .first { $0.displayTitle.localizedCaseInsensitiveCompare(viewName) == .orderedSame }
        }
    }
}
