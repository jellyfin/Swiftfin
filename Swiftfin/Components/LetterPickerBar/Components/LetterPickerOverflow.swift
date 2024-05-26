//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct LetterPickerOverflow: ViewModifier {
    @State
    private var contentOverflow: Bool = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.onAppear {
                            contentOverflow = contentGeometry.size.height > geometry.size.height
                        }
                    }
                )
                .wrappedInScrollView(when: contentOverflow)
        }
    }
}

extension View {
    @ViewBuilder
    func wrappedInScrollView(when condition: Bool) -> some View {
        if condition {
            ScrollView(showsIndicators: false) {
                self
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            self
                .frame(width: 30, alignment: .center)
        }
    }
}

extension View {
    func scrollOnOverflow() -> some View {
        modifier(LetterPickerOverflow())
    }
}
