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

    @State
    private var showServerInfo = false

    let error: ErrorType

    #if os(tvOS)
    private let spacing: CGFloat = 20
    private let iconSize: CGFloat = 144
    private let contentMaxWidth: CGFloat = 600
    private let buttonHeight: CGFloat = 75
    #else
    private let spacing: CGFloat = 10
    private let iconSize: CGFloat = 72
    private let contentMaxWidth: CGFloat = 300
    private let buttonHeight: CGFloat = 50
    #endif

    var body: some View {
        VStack(spacing: spacing) {
            Spacer()
            iconView
            bodyView
            Spacer()
        }
        .frame(maxWidth: contentMaxWidth)
        .padding(.horizontal)
        #if os(tvOS)
            .sheet(isPresented: $showServerInfo) {
                serverInfoView
                    .frame(maxWidth: contentMaxWidth)
                    .padding(spacing)
                    .background(.ultraThickMaterial)
            }
        #endif
    }

    // MARK: - Icon View

    private var iconView: some View {
        VStack {
            ZStack {
                iconBackground

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

    // MARK: - Icon Background

    private var iconBackground: some View {
        #if os(tvOS)
        Circle()
            .fill(Color.red.opacity(0.2))
            .frame(width: iconSize * 1.5, height: iconSize * 1.5)
        #else
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.red.opacity(0.2))
            .frame(width: iconSize * 1.5, height: iconSize * 1.5)
        #endif
    }

    // MARK: - Body View

    private var bodyView: some View {
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

    // MARK: - Server Info View

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

    // MARK: - Error Image

    private var errorImage: String {
        "xmark.circle"
    }
}
