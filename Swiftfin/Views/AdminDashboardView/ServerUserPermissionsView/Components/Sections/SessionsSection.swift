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

        @State
        private var tempLoginAttempts: Int?
        @State
        private var tempMaxSessions: Int?

        private var filteredLoginFailurePolicies: [LoginFailurePolicy] {
            LoginFailurePolicy.allCases.filter {
                if policy.isAdministrator ?? false {
                    return $0 != .userDefault
                } else {
                    return $0 != .adminDefault
                }
            }
        }

        private var isCustomLoginFailurePolicy: Bool {
            ![
                LoginFailurePolicy.unlimited.rawValue,
                LoginFailurePolicy.adminDefault.rawValue,
                LoginFailurePolicy.userDefault.rawValue
            ]
                .contains(policy.loginAttemptsBeforeLockout)
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

                if isCustomLoginFailurePolicy {
                    MaxFailedLoginsButtonView()
                }

                CaseIterablePicker(
                    L10n.maximumSessionsPolicy,
                    selection: $policy.maxActiveSessions.map(
                        getter: { ActiveSessionsPolicy(rawValue: $0) ?? .custom },
                        setter: { $0.rawValue }
                    )
                )

                if policy.maxActiveSessions != ActiveSessionsPolicy.unlimited.rawValue {
                    MaxSessionsButtonView()
                }
            }
        }

        @ViewBuilder
        private func MaxFailedLoginsButtonView() -> some View {
            ChevronAlertButton(
                L10n.customFailedLogins,
                subtitle: Text(tempLoginAttempts ?? policy.loginAttemptsBeforeLockout ?? 0, format: .number),
                description: L10n.enterCustomFailedLogins
            ) {
                let loginAttemptsBinding = Binding<Int>(
                    get: { tempLoginAttempts ?? policy.loginAttemptsBeforeLockout ?? 0 },
                    set: { newValue in tempLoginAttempts = newValue }
                )

                TextField(L10n.failedLogins, value: loginAttemptsBinding, format: .number)
                    .keyboardType(.numberPad)
            } onSave: {
                if let tempValue = tempLoginAttempts {
                    policy.loginAttemptsBeforeLockout = tempValue
                }
            } onCancel: {
                tempLoginAttempts = policy.loginAttemptsBeforeLockout
            }
        }

        @ViewBuilder
        private func MaxSessionsButtonView() -> some View {
            ChevronAlertButton(
                L10n.customSessions,
                subtitle: Text(tempMaxSessions ?? policy.maxActiveSessions ?? 0, format: .number),
                description: L10n.enterCustomMaxSessions
            ) {
                let maxSessionsBinding = Binding<Int>(
                    get: { tempMaxSessions ?? policy.maxActiveSessions ?? 0 },
                    set: { newValue in tempMaxSessions = newValue }
                )

                TextField(L10n.maximumSessions, value: maxSessionsBinding, format: .number)
                    .keyboardType(.numberPad)
            } onSave: {
                if let tempValue = tempMaxSessions {
                    policy.maxActiveSessions = tempValue
                }
            } onCancel: {
                tempMaxSessions = policy.maxActiveSessions
            }
        }
    }
}
