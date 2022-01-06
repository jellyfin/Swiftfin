//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

struct ContinueWatchingCard: View {
    
    @EnvironmentObject var homeRouter: HomeCoordinator.Router
    let item: BaseItemDto
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                homeRouter.route(to: \.modalItem, item)
            } label: {
                ZStack(alignment: .bottom) {

                    ImageView(src: item.getBackdropImage(maxWidth: 500))
                        .frame(width: 500, height: 281.25)

                    VStack(alignment: .leading, spacing: 0)  {
                        Text(item.getItemProgressString() ?? "")
                            .font(.subheadline)
                            .padding(.vertical, 5)
                            .padding(.leading, 10)
                            .foregroundColor(.white)

                        HStack {
                            Color(UIColor.systemPurple)
                                .frame(width: 500 * (item.userData?.playedPercentage ?? 0) / 100, height: 13)

                            Spacer(minLength: 0)
                        }
                    }
                    .background {
                        LinearGradient(colors: [.clear, .black.opacity(0.5), .black.opacity(0.7)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                            .ignoresSafeArea()
                    }
                }
                .frame(width: 500, height: 281.25)
            }
            .buttonStyle(CardButtonStyle())
            .padding(.top)

            VStack(alignment: .leading) {
                Text("\(item.seriesName ?? item.name ?? "")")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if item.itemType == .episode {
                    Text(item.getEpisodeLocator() ?? "")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
