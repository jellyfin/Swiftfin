//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct SimpleItemContentView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(spacing: 0) {
                if let castAndCrew = viewModel.item.people, castAndCrew.isNotEmpty {
                    ItemView.CastAndCrewHStack(people: castAndCrew)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
