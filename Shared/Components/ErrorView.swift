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

struct ErrorView<ErrorType: Error>: PlatformView {
    @Default(.accentColor)
    private var accentColor
    @Injected(\.currentUserSession)
    private var userSession
    @Environment(\.refresh)
    private var refresh

    @State
    private var showServerInfo = false

    let error: ErrorType

    // MARK: iOS View

    var iOSView: some View {
        VStack(spacing: 10) {
            Spacer()

            iconView(iconSize: 72)
            bodyView(buttonHeight: 50)

            Spacer()
        }
        .frame(maxWidth: 300)
        .padding(.horizontal)
    }

    // MARK: tvOS View

    var tvOSView: some View {
        VStack(spacing: 20) {
            Spacer()

            iconView(iconSize: 144)
            bodyView(buttonHeight: 75)

            Spacer()
        }
        .frame(maxWidth: 600)
        .padding(.horizontal)
        .sheet(isPresented: $showServerInfo) {
            serverInfoView
                .frame(maxWidth: 600)
                .padding(20)
                .background(.ultraThickMaterial)
        }
    }

    private func iconView(iconSize: CGFloat) -> some View {
        VStack {
            ZStack {
                iconBackground(iconSize: iconSize)
                    .frame(width: iconSize * 1.5, height: iconSize * 1.5)

                Image(systemName: errorImage)
                    .font(.system(size: iconSize, weight: .regular))
                    .foregroundStyle(Color.red)
                    .symbolRenderingMode(.monochrome)
            }

            if let userSession {
                Button(userSession.server.name, systemImage: "info.circle") {
                    showServerInfo = true
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityLabel(userSession.server.name)
                #if os(tvOS)
                    .focusSection()
                #else
                    .popover(isPresented: $showServerInfo) {
                        serverInfoView
                            .presentationCompactAdaptation(.popover)
                    }
                #endif
            }
        }
    }

    @ViewBuilder
    private func iconBackground(iconSize: CGFloat) -> some View {
        if UIDevice.isTV {
            Circle()
                .fill(Color.red.opacity(0.2))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.2))
        }
    }

    private func bodyView(buttonHeight: CGFloat) -> some View {
        VStack(spacing: 10) {
            Text(error.localizedDescription)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let refresh {
                ListRowButton(L10n.retry) {
                    Task {
                        await refresh()
                    }
                }
                .foregroundStyle(accentColor.overlayColor, accentColor)
                .frame(height: buttonHeight)
                #if os(tvOS)
                    .focusSection()
                #endif
            }

            if let localizedError = error as? LocalizedError,
               let recoverySuggestion = localizedError.recoverySuggestion
            {
                Text(recoverySuggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var serverInfoView: some View {
        VStack(alignment: .center) {
            Text(L10n.server)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Divider()

            if let userSession {
                LabeledContent(
                    L10n.name,
                    value: userSession.server.name
                )

                LabeledContent(
                    L10n.url,
                    value: userSession.server.currentURL.absoluteString
                )

                LabeledContent(
                    L10n.version,
                    value: userSession.server.isVersionCompatible ? L10n.upToDate : L10n.outOfDate
                )
            }
        }
        .padding()
    }

    // TODO: Different SystemImages based on Error Types
    private var errorImage: String {
        "xmark.circle"
    }
}
