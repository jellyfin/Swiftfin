//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ErrorMessageModifier: ViewModifier {

    @Binding
    var error: Error?

    let dismissActions: (() -> Void)?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .alert(
                L10n.error.text,
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {
                    error = nil
                    dismissActions?()
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}
