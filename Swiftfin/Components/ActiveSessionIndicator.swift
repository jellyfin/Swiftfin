//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: When selected, this crams together in a weird way

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

    var activeSessions: Bool {
        !viewModel.activeSessions.isEmpty
    }

    var activeSessionsCount: Int {
        viewModel.activeSessions.count
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

    var contentView: some View {
        switch viewModel.state {
        case .content, .initial:
            AnyView(sessionsView)
        default:
            AnyView(errorView)
        }
    }

    // MARK: - Sessions View

    var sessionsView: some View {
        HStack(alignment: .bottom) {
            if activeSessions {
                counterView
                    .offset(x: 5)
            }
            ZStack {
                imageView
                loadingSpinner
            }
            .onChange(of: viewModel.backgroundStates) { newState in
                if newState.contains(.gettingSessions) {
                    showSpinner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if !viewModel.backgroundStates.contains(.gettingSessions) {
                            showSpinner = false
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
            .frame(width: 25, height: 25)
            // TODO: Should this be a foregroundStyle? If so, which one? Potential
            // issue if the AccentColor is too Light/Dark clashing with .primary
            .foregroundColor(.primary)
            .background(
                Circle()
                    .fill(activeSessions ? Color.accentColor : .secondary)
            )
    }

    // MARK: - Error View

    var errorView: some View {
        Image(systemName: "exclamationmark.triangle")
            .resizable()
            .scaledToFit()
            .padding(4)
            .frame(width: 25, height: 25)
            // TODO: Should this be a foregroundStyle? If so, which one? Potential
            // issue if the AccentColor is too Light/Dark clashing with .primary
            .foregroundColor(.primary)
            .background(
                Circle()
                    .fill(activeSessions ? Color.accentColor : .secondary)
            )
    }

    // MARK: - Loading Spinner View

    var loadingSpinner: some View {
        Circle()
            .trim(from: 0.25, to: 0.75)
            .stroke(showSpinner ? Color.accentColor : Color.clear, lineWidth: 3)
            .frame(width: 35, height: 35)
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

    // MARK: - Counter View

    var counterView: some View {
        Text("\(activeSessionsCount)")
            .padding(0)
            .foregroundStyle(activeSessions ? Color.accentColor : .secondary)
    }
}
