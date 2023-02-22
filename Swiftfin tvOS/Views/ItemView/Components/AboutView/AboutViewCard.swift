//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.AboutView {

    struct InformationCard: View {

        @State
        private var presentingAlert: Bool = false

        let title: String
        let content: String

        var body: some View {
            Button {
                presentingAlert = true
            } label: {
                VStack(alignment: .leading) {
                    title.text
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Spacer()
                        .frame(maxWidth: .infinity)

                    TruncatedTextView(text: content)
                        .font(.subheadline)
                        .lineLimit(4)
                }
                .padding2()
                .frame(width: 700, height: 405)
            }
            .buttonStyle(.card)
            .alert(title, isPresented: $presentingAlert) {
                Button {
                    presentingAlert = false
                } label: {
                    L10n.close.text
                }
            } message: {
                Text(content)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ItemView.AboutView.InformationCard(
            title: "Subtitles",
            content: "Fre - Default - PGSSUB"
        )
    }
}
