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

        private var filteredLoginFailurePolicies: [LoginFailurePolicy] {
            LoginFailurePolicy.allCases.filter {
                if policy.isAdministrator ?? false {
                    return $0 != .userDefault
                } else {
                    return $0 != .adminDefault
                }
            }
        }

        var body: some View {
            Section(L10n.sessions) {

                Picker(
                    L10n.maximumFailedLoginPolicy,
                    selection: $policy.loginAttemptsBeforeLockout.map(
                        getter: { LoginFailurePolicy.from(
                            rawValue: $0 ?? 0,
                            isAdministrator: policy.isAdministrator ?? false
                        ) },
                        setter: { $0.rawValue }
                    )
                ) {
                    ForEach(filteredLoginFailurePolicies, id: \.self) { policy in
                        Text(policy.displayTitle).tag(policy)
                    }
                }

                if policy.loginAttemptsBeforeLockout == LoginFailurePolicy.custom.rawValue {
                    MaxFailedLoginsButtonView()
                }

                CaseIterablePicker(
                    L10n.maximumSessionsPolicy,
                    selection: $policy.maxActiveSessions.map(
                        getter: { ActiveSessionsPolicy(rawValue: $0) ?? .custom },
                        setter: { $0.rawValue }
                    )
                )

                if policy.maxActiveSessions == ActiveSessionsPolicy.custom.rawValue {
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
