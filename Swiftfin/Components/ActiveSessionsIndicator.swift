//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ActiveSessionIndicator: View {
    @ObservedObject
    var viewModel = ActiveSessionsViewModel()

    let action: () -> Void

    // MARK: - View Model Update Timer

    private let timer = Timer.publish(every: 60, on: .main, in: .common)
        .autoconnect()

    // MARK: - Session States

    var activeSessions: [SessionInfo] {
        viewModel.sessions.compactMap(\.value.value).filter {
            $0.nowPlayingItem != nil
        }
    }

    // MARK: - Initializer

    init(action: @escaping () -> Void) {
        self.action = action
        self.viewModel.send(.getSessions)
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            contentView
                .onReceive(timer) { _ in
                    viewModel.send(.getSessions)
                }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        switch viewModel.state {
        case .content, .initial:
            sessionsView
        default:
            errorView
        }
    }

    // MARK: - Sessions View

    var sessionsView: some View {
        HStack(alignment: .bottom) {
            imageView
                .overlay {
                    if activeSessions.isNotEmpty {
                        ActivityBadge(value: activeSessions.count)
                            .foregroundStyle(.primary)
                    }
                }
        }
    }

    // MARK: - Image View

    var imageView: some View {
        Image(systemName: "waveform.path.ecg")
            .resizable()
            .scaledToFit()
            .padding(4)
            .frame(width: 25, height: 25)
            .foregroundColor(.primary)
            .background(
                Circle()
                    .fill(
                        activeSessions.isNotEmpty
                            ? Color.accentColor.opacity(0.5)
                            : Color.secondary
                    )
            )
    }

    // MARK: - Error View

    var errorView: some View {
        Image(systemName: "exclamationmark.triangle")
            .resizable()
            .scaledToFit()
            .padding(4)
            .frame(width: 25, height: 25)
            .foregroundColor(.black)
            .background(
                Circle()
                    .fill(.yellow)
            )
    }
}
