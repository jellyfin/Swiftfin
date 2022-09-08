//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.AboutView {

    struct AboutViewCard: View {

        @Binding
        var isShowingAlert: Bool

        let title: String
        let text: String

        var body: some View {
            Button {
                isShowingAlert = true
            } label: {
                VStack(alignment: .leading) {
                    title.text
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Spacer()

                    TruncatedTextView(text: text, seeMoreAction: {})
                        .font(.subheadline)
                        .lineLimit(4)
                }
                .padding2()
                .frame(width: 700, height: 405)
            }
            .buttonStyle(.card)
        }
    }
}
