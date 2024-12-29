//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CancellableLoadingButton: View {

    // MARK: - Button Variables

    private let description: String?
    private let onCancel: () -> Void

    // MARK: - Initializer

    init(_ description: String?, onCancel: @escaping () -> Void) {
        self.description = description
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            if let description {
                Text(description)
                    .foregroundColor(.primary)
            }

            ProgressView()
                .padding()

            Button(role: .cancel, action: onCancel) {
                Text(L10n.cancel)
                    .foregroundColor(.red)
                    .padding()
                    .overlay {
                        Capsule()
                            .stroke(Color.red, lineWidth: 1)
                    }
            }
        }
    }
}
