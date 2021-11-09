//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct EpisodeCardVStackView: View {

    let items: [BaseItemDto]
    let selectedAction: (BaseItemDto) -> Void

    private func buildCardOverlayView(item: BaseItemDto) -> some View {
        HStack {
            ZStack {
                if item.userData?.isFavorite ?? false {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.white)
                        .opacity(0.6)
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color(.systemRed))
                        .font(.system(size: 10))
                }
            }
            .padding(.leading, 2)
            .padding(.bottom, item.userData?.playedPercentage == nil ? 2 : 9)
            .opacity(1)

            ZStack {
                if item.userData?.played ?? false {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.jellyfinPurple)
                }
            }.padding(2)
            .opacity(1)
        }
    }

    var body: some View {
        VStack {
            ForEach(items, id: \.id) { item in
                Button {
                    selectedAction(item)
                } label: {
                    HStack {

                        // MARK: Image
                        ImageView(src: item.getPrimaryImage(maxWidth: 150),
                                  bh: item.getPrimaryImageBlurHash(),
                                  failureInitials: item.failureInitials)
                            .frame(width: 150, height: 100)
                            .cornerRadius(10)
                            .overlay(
                                Rectangle()
                                    .fill(Color.jellyfinPurple)
                                    .mask(ProgressBar())
                                    .frame(width: CGFloat(item.userData?.playedPercentage ?? 0 * 1.5), height: 7)
                                    .padding(0), alignment: .bottomLeading
                            )
                            .overlay(buildCardOverlayView(item: item), alignment: .topTrailing)

                        VStack(alignment: .leading) {

                            // MARK: Title
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            HStack {
                                Text(item.getEpisodeLocator() ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Text(item.getItemRuntime())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Spacer()
                            }

                            // MARK: Overview
                            Text(item.overview ?? "")
                                .font(.footnote)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(4)

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
