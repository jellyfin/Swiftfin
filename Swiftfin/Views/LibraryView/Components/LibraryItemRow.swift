//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LibraryItemRow: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router

    let item: BaseItemDto

    var body: some View {
        Button {
            router.route(to: \.item, item)
        } label: {
            HStack(alignment: .bottom) {
                ImageView(item.portraitPosterImageSource(maxWidth: 60))
                    .posterStyle(type: .portrait, width: 60)

                VStack(alignment: .leading) {
                    Text(item.displayName)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    DotHStack {
                        if let premiereYear = item.premiereDateYear {
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
