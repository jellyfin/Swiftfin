//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct QueueErrorView: PlatformView {

    @Environment(VideoPlayer.ViewState.self)
    private var viewState

    let retry: () -> Void

    private var retryButton: some View {
        AlternateLayoutView {
            Label(L10n.retry, systemImage: "arrow.clockwise")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding()
                .edgePadding(.horizontal)
                .frame(height: UIDevice.isTV ? 80 : 40)
        } content: {
            Button(action: retry) {
                Label(L10n.retry, systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding()
                    .edgePadding(.horizontal)
            }
            .buttonStyle(.supplementAction)
            .frame(height: UIDevice.isTV ? 80 : 50)
        }
    }

    private var errorCard: some View {
        VStack(alignment: .leading, spacing: EdgeInsets.edgePadding / 2) {
            Text(L10n.unknownError)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            retryButton
        }
        .edgePadding(.horizontal)
        .padding(.vertical, EdgeInsets.edgePadding / 2)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(Material.thin)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .edgePadding()
        .focusSection()
    }

    var iOSView: some View {
        CompactOrRegularView(isCompact: viewState.isCompact) {
            ErrorView(error: ErrorMessage(L10n.unknownError))
                .refreshable { retry() }
        } regularView: {
            errorCard
        }
    }

    var tvOSView: some View {
        errorCard
    }
}
