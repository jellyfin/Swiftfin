//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SessionViewModel: LibraryElement {

    nonisolated static func == (lhs: SessionViewModel, rhs: SessionViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    var displayTitle: String {
        session.displayTitle
    }

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        .default
    }

    @ContentBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            SessionGridElement(
                viewModel: self,
                displayType: libraryStyle.posterDisplayType,
                action: action
            )

        case .list:
            ActiveSessionsView.ActiveSessionRow(
                viewModel: self,
                posterDisplayType: libraryStyle.posterDisplayType
            ) {
                action?()
            }
        }
    }
}

private struct SessionGridElement: View {

    @ObservedObject
    var viewModel: SessionViewModel

    let displayType: PosterDisplayType
    let action: (() -> Void)?

    @ContentBuilder
    var body: some View {
        PosterButton(
            item: viewModel.session,
            displayType: displayType
        ) { _ in
            action?()
        }
        .id(viewModel.session.nowPlayingItem?.id)
    }
}
