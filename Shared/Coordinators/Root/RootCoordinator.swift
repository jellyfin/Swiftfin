//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import Foundation
import SwiftUI
import UIKit

enum AppStartupError: Error {

    case dataStack(Error)
}

@MainActor
@Stateful
final class RootCoordinator: ObservableObject {

    @CasePathable
    enum Action {
        case start

        var transition: Transition {
            switch self {
            case .start:
                .to(.ready)
            }
        }
    }

    enum State {
        case initial
        case error
        case ready
    }

    private var started = false
    private var selectedAccentColor: Color = .jellyfinPurple
    private var accentColorCancellable: AnyCancellable?
    private var appearanceCancellable: AnyCancellable?
    private var currentSessionCancellable: AnyCancellable?
    private var increasedContrastCancellable: AnyCancellable?
    private var splashScreenCancellable: AnyCancellable?

    @Injected(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    deinit {
        accentColorCancellable?.cancel()
        appearanceCancellable?.cancel()
        currentSessionCancellable?.cancel()
        increasedContrastCancellable?.cancel()
        splashScreenCancellable?.cancel()
    }

    @Function(\Action.Cases.start)
    private func _start() async throws {
        guard !started else { return }
        started = true

        do {
            try await SwiftfinStore.setupDataStack()
            startPreferenceObservation()
        } catch {
            throw AppStartupError.dataStack(error)
        }
    }

    private func startPreferenceObservation() {
        increasedContrastCancellable = Notifications[.darkerSystemColorsStatusDidChange]
            .publisher
            .sink { [weak self] isIncreasedContrastEnabled in
                guard let self else { return }
                Task { @MainActor in
                    self.applyAccentColor(
                        self.selectedAccentColor,
                        isIncreasedContrastEnabled
                    )
                }
            }

        setPreferenceObservation(for: userSessionManager.currentSession)

        currentSessionCancellable = userSessionManager.$currentSession
            .dropFirst()
            .sink { [weak self] session in
                Task { @MainActor in
                    self?.setPreferenceObservation(for: session)
                }
            }
    }

    private func setPreferenceObservation(for session: UserSession?) {
        if session == nil {
            setAppDefaultsObservation()
        } else {
            setUserDefaultsObservation()
        }
    }

    private func setUserDefaultsObservation() {
        accentColorCancellable?.cancel()
        appearanceCancellable?.cancel()
        splashScreenCancellable?.cancel()

        accentColorCancellable = Task {
            applyAccentColor(Defaults[.userAccentColor])

            for await newValue in Defaults.updates(.userAccentColor) {
                applyAccentColor(newValue)
            }
        }
        .asAnyCancellable()

        appearanceCancellable = Task {
            applyAppearance(Defaults[.userAppearance])

            for await newValue in Defaults.updates(.userAppearance) {
                applyAppearance(newValue)
            }
        }
        .asAnyCancellable()
    }

    private func setAppDefaultsObservation() {
        accentColorCancellable?.cancel()
        appearanceCancellable?.cancel()
        splashScreenCancellable?.cancel()

        accentColorCancellable = Task {
            applyAccentColor(.jellyfinPurple)
        }
        .asAnyCancellable()

        appearanceCancellable = Task {
            applyAppAppearance()

            for await newValue in Defaults.updates(.appAppearance) {
                guard !Defaults[.selectUserUseSplashscreen] else { continue }

                applyAppearance(newValue)
            }
        }
        .asAnyCancellable()

        splashScreenCancellable = Task {
            for await _ in Defaults.updates(.selectUserUseSplashscreen) {
                applyAppAppearance()
            }
        }
        .asAnyCancellable()
    }

    @MainActor
    private func applyAccentColor(_ color: Color, _ isIncreasedContrastEnabled: Bool = false) {
        selectedAccentColor = color

        let appearance = Defaults[.appearance]
        let isDark = appearance == .dark || (
            appearance == .system && UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle == .dark
        )
        let resolvedColor = isIncreasedContrastEnabled ? color.mix(
            with: isDark ? .white : .black,
            by: 0.25
        ) : color

        Defaults[.accentColor] = resolvedColor

        #if os(iOS)
        UIApplication.shared.setAccentColor(resolvedColor.uiColor)
        #endif
    }

    @MainActor
    private func applyAppearance(_ appearance: AppAppearance) {
        Defaults[.appearance] = appearance
        UIApplication.shared.setAppearance(appearance.style)
        applyAccentColor(selectedAccentColor)
    }

    @MainActor
    private func applyAppAppearance() {
        if Defaults[.selectUserUseSplashscreen] {
            applyAppearance(.dark)
        } else {
            applyAppearance(Defaults[.appAppearance])
        }
    }
}
