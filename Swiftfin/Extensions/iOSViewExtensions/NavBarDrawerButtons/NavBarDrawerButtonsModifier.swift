//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavBarDrawerButtonsModifier<Buttons: View>: ViewModifier {

    let buttons: () -> Buttons

    init(@ViewBuilder buttons: @escaping () -> Buttons) {
        self.buttons = buttons
    }

    func body(content: Content) -> some View {
        NavBarDrawerButtonsView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    buttons()
                }
                .padding(.horizontal)
            }
            .ignoresSafeArea()
        } content: {
            content
        }
        .ignoresSafeArea()
    }
}
