//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMore<Content: View>: View {
    @State
    private var isPresented: Bool = false

    let title: String
    let content: () -> Content

    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Text(L10n.learnMoreEllipsis)
                .foregroundColor(.accentColor)
                .font(.subheadline)
        }
        .sheet(isPresented: $isPresented) {
            NavigationView {
                content()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarCloseButton {
                        isPresented = false
                    }
            }
        }
    }
}

extension LearnMore where Content == Text {
    init(_ title: String, text: String) {
        self.title = title
        self.content = { Text(text) }
    }
}
