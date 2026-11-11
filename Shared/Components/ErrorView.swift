//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Get
import SwiftUI

struct ErrorView<ErrorType: Error>: View {

    @AdaptiveLayout
    private var viewLayout

    @AppTheme
    private var theme

    @Environment(\.refresh)
    private var refresh

    @Injected(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    let error: ErrorType

    private var canSignIn: Bool {
        guard let apiError = error as? APIError,
              case .unacceptableStatusCode(401) = apiError
        else { return false }

        return userSessionManager.currentSession != nil
    }

    private var systemImage: String {
        if let error = error as? SystemImageable {
            error.systemImage
        } else {
            "xmark.circle"
        }
    }

    @ContentBuilder
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.system(size: viewLayout.value(standard: 72, large: 144), weight: .regular))
                .foregroundStyle(Color.red)
                .symbolRenderingMode(.monochrome)

            Text(error.localizedDescription)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if canSignIn || refresh != nil {
                Button {
                    Task { @MainActor in
                        if canSignIn {
                            await userSessionManager.signOut(reason: .authenticationExpired)
                        } else if let refresh {
                            await refresh()
                        }
                    }
                } label: {
                    Text(canSignIn ? L10n.signIn : L10n.retry)
                        .frame(maxWidth: .infinity)
                }
                .fontWeight(.semibold)
                .backport
                .buttonStyle(.glassProminent.shadow(false))
                .tint(theme.accentColor)
                #if os(iOS)
                .controlSize(.large)
                #endif
                .frame(minHeight: viewLayout.controlHeight)
                .frame(maxWidth: viewLayout.value(standard: 300, large: 600))
            }

            if let localizedError = error as? LocalizedError,
               let recoverySuggestion = localizedError.recoverySuggestion {
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
