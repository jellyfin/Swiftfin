//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct SessionsSection: View {

        @Binding
        var policy: UserPolicy
        @Binding
        var loginFailurePolicy: LoginFailurePolicy
        @Binding
        var maxSessionsPolicy: ActiveSessionsPolicy

        var body: some View {
            Section(L10n.sessions) {
                Picker(L10n.maximumFailedLoginPolicy, selection: $loginFailurePolicy) {
                    ForEach(
                        LoginFailurePolicy.allCases.filter {
                            if policy.isAdministrator ?? false {
                                return $0 != .userDefault
                            } else {
                                return $0 != .adminDefault
                            }
                        }, id: \.self
                    ) { policy in
                        Text(policy.displayTitle).tag(policy)
                    }
                }
                .onChange(of: loginFailurePolicy) { newPolicy in
                    policy.loginAttemptsBeforeLockout = newPolicy.rawValue
                }

                if loginFailurePolicy == .custom {
                    MaxFailedLoginsButtonView()
                }

                Picker(L10n.maximumSessionsPolicy, selection: $maxSessionsPolicy) {
                    ForEach(ActiveSessionsPolicy.allCases, id: \.self) { policies in
                        Text(policies.displayTitle).tag(policies)
                    }
                }
                .onChange(of: maxSessionsPolicy) { newPolicy in
                    policy.maxActiveSessions = newPolicy.rawValue
                }

                if maxSessionsPolicy == .custom {
                    MaxSessionsButtonView()
                }
            }
        }

        @ViewBuilder
        private func MaxFailedLoginsButtonView() -> some View {
            ChevronAlertButton(
                L10n.customFailedLogins,
                subtitle: (policy.loginAttemptsBeforeLockout ?? 0).description,
                description: L10n.enterCustomFailedLogins
            ) {
                TextField(L10n.failedLogins, value: $policy.loginAttemptsBeforeLockout, format: .number)
                    .keyboardType(.numberPad)
            }
        }

        @ViewBuilder
        private func MaxSessionsButtonView() -> some View {
            ChevronAlertButton(
                L10n.customSessions,
                subtitle: (policy.maxActiveSessions ?? 0).description,
                description: L10n.enterCustomMaxSessions
            ) {
                TextField(L10n.maximumSessions, value: $policy.maxActiveSessions, format: .number)
                    .keyboardType(.numberPad)
            }
        }
    }
}
