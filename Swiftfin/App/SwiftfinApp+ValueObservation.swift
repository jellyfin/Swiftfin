//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import SwiftUI

#warning("TODO: appearance")

// Following class is necessary to observe values that can either
// be a user *or* an app setting and only one should apply at a time.
//
// Also just to separate out value observation

extension SwiftfinApp {

    class ValueObservation: ObservableObject {

        private var accentColorCancellable: AnyCancellable?
        private var appearanceCancellable: AnyCancellable?
        private var lastSignInUserIDCancellable: AnyCancellable?

        init() {

            // MARK: signed in observation

            lastSignInUserIDCancellable = Task {
                for await newValue in Defaults.updates(.lastSignedInUserID) {
                    if let _ = newValue {
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
                    await MainActor.run {
                        Defaults[.appearance] = newValue
                        UIApplication.shared.setAppearance(newValue.style)
                    }
                }
            }
            .asAnyCancellable()
        }
    }
}
