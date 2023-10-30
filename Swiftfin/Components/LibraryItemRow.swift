//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LibraryItemRow: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router

    private let item: BaseItemDto
    private var onSelect: () -> Void

    private let posterWidth: CGFloat = 60

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: .bottom) {
                ImageView(item.portraitPosterImageSource(maxWidth: posterWidth))
                    .posterStyle(type: .portrait, width: posterWidth)
                    .posterShadow()

                VStack(alignment: .leading) {
                    Text(item.displayTitle)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    DotHStack {
                        if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLocator {
                            Text(seasonEpisodeLocator)
                        } else if let premiereYear = item.premiereDateYear {
                            Text(premiereYear)
                        }

                        if let runtime = item.getItemRuntime() {
                            Text(runtime)
                        }

                        if let officialRating = item.officialRating {
                            Text(officialRating)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
                }
                .padding(.vertical)

                Spacer()
            }
        }
    }
}

extension LibraryItemRow {

    init(item: BaseItemDto) {
        self.init(
            item: item,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
