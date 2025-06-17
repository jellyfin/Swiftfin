//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Backport<Content> {

    let content: Content
}

extension Backport where Content: View {

    @ViewBuilder
    func scrollClipDisabled(_ disabled: Bool = true) -> some View {
        if #available(iOS 17, *) {
            content.scrollClipDisabled(disabled)
        } else {
            content.introspect(.scrollView, on: .iOS(.v15), .tvOS(.v15)) { scrollView in
                scrollView.clipsToBounds = !disabled
            }
        }
    }
}

// MARK: ButtonBorderShape

extension ButtonBorderShape {

    static let circleBackport: ButtonBorderShape = {
        if #available(iOS 17, *) {
            return ButtonBorderShape.circle
        } else {
            return ButtonBorderShape.roundedRectangle
        }
    }()
}
