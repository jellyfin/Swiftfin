//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct ImageView: View {
    private let source: URL
    private let blurhash: String
    private let failureInitials: String

    init(src: URL, bh: String = "001fC^", failureInitials: String = "") {
        self.source = src
        self.blurhash = bh
        self.failureInitials = failureInitials
    }

    // TODO: fix placeholder hash image
    @ViewBuilder
    private var placeholderImage: some View {
        Image(uiImage: UIImage(blurHash: blurhash, size: CGSize(width: 8, height: 8)) ?? UIImage(blurHash: "001fC^", size: CGSize(width: 8, height: 8))!)
            .resizable()
    }

    @ViewBuilder
    private var failureImage: some View {
        ZStack {
            Rectangle()
               .foregroundColor(Color(UIColor.darkGray))

            Text(failureInitials)
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
    }

    var body: some View {
        AsyncImage(url: source, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                failureImage
            default:
                // TODO: remove once placeholder hash image fixed

                #if os(tvOS)
                ZStack {
                    Color.black.ignoresSafeArea()

                    ProgressView()
                }
                #else
                ZStack {
                    Color.gray.ignoresSafeArea()

                    ProgressView()
                }
                #endif
            }
        }
    }
}
