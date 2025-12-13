//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.CinematicScrollView {

    struct MetadataView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            DotHStack {
                if let firstGenre = viewModel.item.genres?.first {
                    Text(firstGenre)
                }

                if let premiereYear = viewModel.item.premiereDateYear {
                    Text(premiereYear)
                }

                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundStyle(Color(UIColor.lightGray))
        }
    }
}
