//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BorderlessFocus: ButtonStyle {
    var isFocused: FocusState<Bool>.Binding
    let scaling: CGFloat = 1.1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.borderless)
            .background(
                GeometryReader { geometry in
                    if isFocused.wrappedValue {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(.primary)
                            .frame(
                                width: geometry.size.width * scaling * 1.5,
                                height: geometry.size.height * scaling * 1.5
                            )
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .animation(.easeInOut(duration: 0.1), value: isFocused.wrappedValue)
                    }
                }
            )
            .scaleEffect(isFocused.wrappedValue ? scaling : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isFocused.wrappedValue)
    }
}
