//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: should use environment refresh instead?
struct ErrorView<ErrorType: Error>: View {

    @Default(.accentColor)
    private var accentColor

    private let error: ErrorType
    private var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 150))
                .foregroundColor(Color.red)

            Text(error.localizedDescription)
                .frame(minWidth: 250, maxWidth: 750)
                .multilineTextAlignment(.center)

            if let onRetry {
                ListRowButton(L10n.retry, action: onRetry)
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .frame(maxWidth: 750)
            }
        }
    }
}

extension ErrorView {

    init(error: ErrorType) {
        self.init(
            error: error,
            onRetry: nil
        )
    }

    func onRetry(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onRetry, with: action)
    }
}
