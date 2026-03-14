//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

#if os(iOS)
private let buttonHeight: CGFloat = 44
private let buttonMaxSize: CGFloat = 300
private let iconSize: CGFloat = 72
#else
private let buttonHeight: CGFloat = 75
private let buttonMaxSize: CGFloat = 600
private let iconSize: CGFloat = 144
#endif

struct ErrorView<ErrorType: Error>: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.refresh)
    private var refresh

    let error: ErrorType

    private var systemImage: String {
        if let error = error as? SystemImageable {
            error.systemImage
        } else {
            "xmark.circle"
        }
    }

    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(Color.red)
                .symbolRenderingMode(.monochrome)

            Text(error.localizedDescription)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let refresh {
                Button(L10n.retry) {
                    Task {
                        await refresh()
                    }
                }
                .buttonStyle(.primary)
                .frame(height: buttonHeight)
                .frame(maxWidth: buttonMaxSize)
                .foregroundStyle(accentColor.overlayColor, accentColor)
            }

            if let localizedError = error as? LocalizedError,
               let recoverySuggestion = localizedError.recoverySuggestion
            {
                Text(recoverySuggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 600, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .focusSection()
        .edgePadding()
    }
}
