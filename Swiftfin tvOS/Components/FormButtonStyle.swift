//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PrimitiveButtonStyle where Self == FormButtonStyle {
    static var form: FormButtonStyle {
        FormButtonStyle()
    }
}

struct FormButtonStyle: PrimitiveButtonStyle {

    @FocusState
    private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            configuration.label
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.card)
        .focused($isFocused)
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }
}
