//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG
import Factory
import JellyfinAPI
import SwiftUI

// MARK: - BrunoCollectionProbe (DEBUG only)

//
// Headless verification for the collection grid (`CollectionItemContentView`): auto-signs in,
// fetches a real BoxSet, and renders the stock `ItemView` for it so the grid can be screenshotted
// via `simctl` with no UI navigation. Gated by `BRUNO_COLLECTION_PROBE=1` (see `SwiftfinApp`);
// requires the same `BRUNO_AUTOSIGNIN=1` + `JF_*` env as the auto-sign-in path.
struct BrunoCollectionProbe: View {

    @State
    private var viewModel: CollectionItemViewModel?
    @State
    private var status = "signing in…"

    /// `BRUNO_COLLECTION_PROBE=grid` renders the content view alone (grid at the top of the shot);
    /// any other truthy value renders the full `ItemView` (cinematic banner + grid below).
    private var gridOnly: Bool {
        ProcessInfo.processInfo.environment["BRUNO_COLLECTION_PROBE"] == "grid"
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let viewModel {
                if gridOnly {
                    ScrollView {
                        ItemView.CollectionItemContentView(viewModel: viewModel)
                    }
                } else {
                    ItemView(item: viewModel.item)
                }
            } else {
                Text(status)
                    .foregroundStyle(.white)
            }
        }
        .task { await load() }
    }

    private func load() async {
        await BrunoAutoSignIn.runIfRequested()

        var session: UserSession?
        for _ in 0 ..< 40 {
            if let resolved = Container.shared.currentUserSession() {
                session = resolved
                break
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        guard let session else { status = "no session"
            return
        }

        do {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = session.user.id
            parameters.isRecursive = true
            parameters.includeItemTypes = [.boxSet]
            parameters.sortBy = [.name]
            parameters.fields = [.overview, .genres]
            parameters.limit = 20
            let boxSets = try await session.client.send(Paths.getItems(parameters: parameters)).value.items ?? []
            // Prefer a collection with the most children so the multi-line grid is well populated.
            guard let item = boxSets.max(by: { ($0.childCount ?? 0) < ($1.childCount ?? 0) }) ?? boxSets.first else {
                status = "no box sets"
                return
            }
            let model = CollectionItemViewModel(item: item)
            model.send(.refresh)
            viewModel = model
        } catch {
            status = "error: \(error)"
        }
    }
}
#endif
