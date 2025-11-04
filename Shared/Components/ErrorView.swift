//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct ErrorView<ErrorType: Error>: View {

    @Default(.accentColor)
    private var accentColor
    @Injected(\.currentUserSession)
    private var userSession
    @Environment(\.refresh)
    private var refresh

    let error: ErrorType

    #if os(tvOS)
    private let spacing: CGFloat = 40
    private let fontSize: CGFloat = 150
    private let minWidth: CGFloat = 100
    private let maxWidth: CGFloat = 500
    private let height: CGFloat = 75
    #else
    private let spacing: CGFloat = 20
    private let fontSize: CGFloat = 72
    private let minWidth: CGFloat = 50
    private let maxWidth: CGFloat = 300
    private let height: CGFloat = 50
    #endif

    var body: some View {
        VStack(spacing: spacing) {
            Image(systemName: errorImage)
                .font(.system(size: fontSize))
                .foregroundColor(Color.red)

            if let serverName = userSession?.server.name {
                Text(serverName)
                    .frame(minWidth: minWidth, maxWidth: maxWidth)
                    .font(.title)
                    .multilineTextAlignment(.center)
            }

            Text(error.localizedDescription)
                .frame(minWidth: minWidth, maxWidth: maxWidth)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if let networkError = error as? NetworkError,
               let recoverySuggestion = networkError.recoverySuggestion
            {
                Text(recoverySuggestion)
                    .frame(minWidth: minWidth, maxWidth: maxWidth)
                    .font(.body)
                    .multilineTextAlignment(.center)

                if let refresh {
                    ListRowButton(L10n.retry) {
                        Task {
                            await refresh()
                        }
                    }
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .frame(maxWidth: maxWidth)
                    .frame(height: height)
                }
            }
        }
    }

    private var errorImage: String {
        if let networkError = error as? NetworkError {
            return networkError.source.systemImage
        } else {
            return NetworkError.unknown.source.systemImage
        }
    }
}
