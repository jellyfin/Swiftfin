//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: should use environment refresh instead?
struct ErrorView<_Error: Error>: View {

    private let error: _Error
    private var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color.red)

            Text(error.localizedDescription)
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)

            PrimaryButton(title: L10n.retry)
                .onSelect(onRetry)
                .frame(maxWidth: 300)
                .frame(height: 50)
        }
    }
}

extension ErrorView {

    init(error: _Error) {
        self.init(
            error: error,
            onRetry: {}
        )
    }

    func onRetry(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onRetry, with: action)
    }
}
