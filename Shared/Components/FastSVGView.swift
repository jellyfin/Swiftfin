//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SVGKit
import SwiftUI

// Note: SVGKit does not support the simulator and will appear blank.

// This seemed necessary because using SwiftUI `Image(uiImage:)` would cause severe lag.
struct FastSVGView: UIViewRepresentable {

    let data: Data

    func makeUIView(context: Context) -> some UIView {
        let imageView = SVGKFastImageView(svgkImage: SVGKImage(data: data))!
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return imageView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
