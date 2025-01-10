//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import SwiftUI

// Following class is necessary to observe values that can either
// be a user *or* an app setting and only one should apply at a time.
//
// Also just to separate out value observation

// TODO: could clean up?

extension SwiftfinApp {

    class ValueObservation: ObservableObject {

        private var accentColorCancellable: AnyCancellable?
        private var appearanceCancellable: AnyCancellable?
        private var lastSignInUserIDCancellable: AnyCancellable?
        private var splashScreenCancellable: AnyCancellable?

        init() {

            // MARK: signed in observation

            lastSignInUserIDCancellable = Task {
                for await newValue in Defaults.updates(.lastSignedInUserID) {
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
                for await newValue in Defaults.updates(.userAccentColor) {
                    await MainActor.run {
                        Defaults[.accentColor] = newValue
                        UIApplication.shared.setAccentColor(newValue.uiColor)
                    }
                }
            }
            .asAnyCancellable()

            appearanceCancellable = Task {
                for await newValue in Defaults.updates(.userAppearance) {
                    await MainActor.run {
                        Defaults[.appearance] = newValue
                        UIApplication.shared.setAppearance(newValue.style)
                    }
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
                for await newValue in Defaults.updates(.appAccentColor) {
                    await MainActor.run {
                        Defaults[.accentColor] = newValue
                        UIApplication.shared.setAccentColor(newValue.uiColor)
                    }
                }
            }
            .asAnyCancellable()

            appearanceCancellable = Task {
                for await newValue in Defaults.updates(.appAppearance) {

                    // other cancellable will set appearance if enabled
                    // and need to avoid races
                    guard !Defaults[.selectUserUseSplashscreen] else { continue }

                    await MainActor.run {
                        Defaults[.appearance] = newValue
                        UIApplication.shared.setAppearance(newValue.style)
                    }
                }
            }
            .asAnyCancellable()

            splashScreenCancellable = Task {
                for await newValue in Defaults.updates(.selectUserUseSplashscreen) {
                    await MainActor.run {
                        if newValue {
                            Defaults[.appearance] = .dark
                            UIApplication.shared.setAppearance(.dark)
                        } else {
                            Defaults[.appearance] = Defaults[.appAppearance]
                            UIApplication.shared.setAppearance(Defaults[.appAppearance].style)
                        }
                    }
                }
            }
            .asAnyCancellable()
        }
    }
}
