//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import SwiftUI
import UIKit

// Observes values that can come from either app defaults or user defaults,
// depending on whether a user is currently signed in.
extension SwiftfinApp {

    class ValueObservation: ObservableObject {

        private var accentColorCancellable: AnyCancellable?
        private var appearanceCancellable: AnyCancellable?
        private var lastSignInUserIDCancellable: AnyCancellable?
        private var splashScreenCancellable: AnyCancellable?

        init() {
            switch Defaults[.lastSignedInUserID] {
            case .signedIn:
                setUserDefaultsObservation()
            case .signedOut:
                setAppDefaultsObservation()
            }

            lastSignInUserIDCancellable = Task {
                for await newValue in Defaults.updates(.lastSignedInUserID) {

                    Container.shared.mediaPlayerManager.reset()

                    if case .signedIn = newValue {
                        setUserDefaultsObservation()
                    } else {
                        setAppDefaultsObservation()
                    }
                }
            }
            .asAnyCancellable()
        }

        // MARK: user observation

        private func setUserDefaultsObservation() {
            accentColorCancellable?.cancel()
            appearanceCancellable?.cancel()
            splashScreenCancellable?.cancel()

            accentColorCancellable = Task {
                await applyAccentColor(Defaults[.userAccentColor])

                for await newValue in Defaults.updates(.userAccentColor) {
                    await applyAccentColor(newValue)
                }
            }
            .asAnyCancellable()

            appearanceCancellable = Task {
                await applyAppearance(Defaults[.userAppearance])

                for await newValue in Defaults.updates(.userAppearance) {
                    await applyAppearance(newValue)
                }
            }
            .asAnyCancellable()
        }

        // MARK: app observation

        private func setAppDefaultsObservation() {
            accentColorCancellable?.cancel()
            appearanceCancellable?.cancel()
            splashScreenCancellable?.cancel()

            accentColorCancellable = Task {
                await applyAccentColor(.jellyfinPurple)
            }
            .asAnyCancellable()

            appearanceCancellable = Task {
                await applyAppAppearance()

                for await newValue in Defaults.updates(.appAppearance) {

                    // Other cancellable will set appearance if enabled and need to avoid races.
                    guard !Defaults[.selectUserUseSplashscreen] else { continue }

                    await applyAppearance(newValue)
                }
            }
            .asAnyCancellable()

            splashScreenCancellable = Task {
                for await _ in Defaults.updates(.selectUserUseSplashscreen) {
                    await applyAppAppearance()
                }
            }
            .asAnyCancellable()
        }

        @MainActor
        private func applyAccentColor(_ color: Color) {
            Defaults[.accentColor] = color
            UIApplication.shared.setAccentColor(color.uiColor)
        }

        @MainActor
        private func applyAppearance(_ appearance: AppAppearance) {
            Defaults[.appearance] = appearance
            UIApplication.shared.setAppearance(appearance.style)
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
}
