//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NumericBadge: View {

    let content: String

    private var size: CGFloat {
        let font = UIFont.systemFont(ofSize: 11, weight: .bold)
        let textSize = content.size(withAttributes: [.font: font])
        return max(textSize.width + 8, textSize.height + 4)
    }

    var body: some View {
        Text(content)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.black.opacity(0.8))
            .clipShape(.circle)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 2)
            .padding(.leading, 2)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .safeAreaInset(edge: .top) {
                Text("Top text")
            }
        NumericBadge(content: "12")
    }
}
