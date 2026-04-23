//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

extension ServerLogDetailsView {

    struct RawServerLogView: UIViewRepresentable {

        let text: String

        func makeUIView(context: Context) -> UITextView {
            let view = UITextView()
            view.isEditable = false
            view.isSelectable = true
            view.alwaysBounceVertical = true
            view.font = .monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
            view.backgroundColor = .clear
            view.textContainerInset = .init(top: 12, left: 12, bottom: 12, right: 12)
            view.textContainer.lineBreakMode = .byCharWrapping
            return view
        }

        func updateUIView(_ uiView: UITextView, context: Context) {
            if uiView.text != text {
                uiView.text = text
            }
        }
    }
}
