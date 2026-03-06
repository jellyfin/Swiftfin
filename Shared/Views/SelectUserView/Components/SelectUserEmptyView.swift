//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct UserEmptyView<AddUserButton: View>: PlatformView {

        private let addUserButton: () -> AddUserButton

        private var columns: Int {
            UIDevice.isPhone ? 2 : 5
        }

        init(
            @ViewBuilder addUserButton: @escaping () -> AddUserButton
        ) {
            self.addUserButton = addUserButton
        }

        var iOSView: some View {
            GeometryReader { geometry in
                addUserButton()
                    .frame(maxWidth: (geometry.size.width - EdgeInsets.edgePadding * (CGFloat(columns) + 1)) / CGFloat(columns))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }

        var tvOSView: some View {
            addUserButton()
                .frame(width: 300)
                .focusSection()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
