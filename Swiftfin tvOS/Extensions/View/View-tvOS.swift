//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import SwiftUIIntrospect

extension View {

    /// Full Screen Menu Overlay
    func fullScreenMenu<Contents: View>(
        isPresented: Binding<Bool>,
        _ title: String? = nil,
        subtitle: String? = nil,
        orientation: Alignment = .trailing,
        @ViewBuilder content: @escaping () -> Contents,
        dismissActions: (() -> Void)? = nil
    ) -> some View {
        modifier(FullScreenMenuModifier(
            isPresented: isPresented,
            title: title,
            subtitle: subtitle,
            orientation: orientation,
            contents: content,
            dismissActions: dismissActions
        ))
    }
}
