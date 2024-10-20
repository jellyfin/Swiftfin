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

    // MARK: - Spinner States

    @State
    private var isSpinning = false
    @State
    private var showSpinner = false

    // MARK: - Session States

    var activeSessions: [SessionInfo] {
        viewModel.sessions.compactMap(\.value.value).filter {
            $0.nowPlayingItem != nil
        }
    }

    // MARK: - Do Active Sessions Exist

    var isEnabled: Bool {
        activeSessions.isNotEmpty
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
            if isEnabled {
                counterView
                    .offset(x: 5)
            }
            ZStack {
                imageView
                if showSpinner {
                    loadingSpinner
                } else {
                    idleCircle
                }
            }
            .onChange(of: viewModel.backgroundStates) { newState in
                if newState.contains(.gettingSessions) {
                    showSpinner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if !viewModel.backgroundStates.contains(.gettingSessions) {
                            showSpinner = false
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSpinner = false
                    }
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
            .frame(width: 25, height: 23)
            .foregroundColor(.primary)
            .background(
                Circle()
                    .fill(isEnabled ? Color.accentColor : .secondary)
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

    // MARK: - Loading Spinner View

    var loadingSpinner: some View {
        Circle()
            .trim(from: 0.25, to: 0.75)
            .stroke(showSpinner ? (isEnabled ? Color.accentColor : .secondary) : Color.clear, lineWidth: 2)
            .frame(width: 30, height: 30)
            .rotationEffect(
                Angle(degrees: isSpinning ? 360 : 0)
            )
            .animation(
                .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isSpinning
            )
            .onAppear {
                isSpinning = true
            }
            .onDisappear {
                isSpinning = false
            }
    }

    // MARK: - Spacer Spinner View

    var idleCircle: some View {
        // This exists to ensure spacing so the image doesn't move when loading happens
        Circle()
            .stroke(Color.clear, lineWidth: 2)
            .frame(width: 30, height: 30)
    }

    // MARK: - Counter View

    var counterView: some View {
        Text("\(activeSessions.count)")
            .font(.headline)
            .padding(0)
            .foregroundStyle(isEnabled ? Color.accentColor : .secondary)
    }
}
