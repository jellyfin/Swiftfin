//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct ImageButtonStyle: ButtonStyle {

    let focused: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(6)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(100)
            .shadow(color: .black, radius: self.focused ? 20 : 0, x: 0, y: 0) //  0
    }
}
