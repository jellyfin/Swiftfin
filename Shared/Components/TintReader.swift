//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TintReader<Content: View>: View {

    @State
    private var resolvedColor: Color = .accentColor

    private let content: (Color) -> Content

    init(@ViewBuilder content: @escaping (Color) -> Content) {
        self.content = content
    }

    var body: some View {
        content(resolvedColor)
            .background(
                TintColorExtractor(color: $resolvedColor)
            )
    }
}

private struct TintColorExtractor: UIViewRepresentable {

    @Binding
    var color: Color

    func makeUIView(context: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            let newColor = Color(uiView.tintColor)
            if color != newColor {
                color = newColor
            }
        }
    }
}
