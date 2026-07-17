//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// - Important: On iOS, this is a `BorderlessButtonStyle` instead.
/// This is only used to allow platform shared views.
extension PrimitiveButtonStyle where Self == BorderlessButtonStyle {
    static var card: BorderlessButtonStyle {
        .init()
    }
}

extension ButtonStyle where Self == IsPressedButtonStyle {

    static func isPressed(_ isPressed: @escaping (Bool) -> Void) -> IsPressedButtonStyle {
        IsPressedButtonStyle(isPressed: isPressed)
    }
}

struct IsPressedButtonStyle: ButtonStyle {

    let isPressed: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed, perform: isPressed)
    }
}
