//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct SessionsSection: View {

        @Binding
        var policy: UserPolicy

        // MARK: - Body

        var body: some View {
            FailedLoginsView
            MaxSessionsView
        }

        // MARK: - Failed Login Selection View

        @ViewBuilder
        private var FailedLoginsView: some View {
            Section(
                L10n.sessions,
                footer: L10n.maximumFailedLoginPolicyDescription
            ) {
                Picker(
                    L10n.maximumFailedLoginPolicy,
                    selection: $policy.loginAttemptsBeforeLockout
                        .coalesce(0)
                        .map(
                            getter: { LoginFailurePolicy(rawValue: $0) ?? .custom },
                            setter: { $0.rawValue }
                        )
                )

                if let loginAttempts = policy.loginAttemptsBeforeLockout, loginAttempts > 0 {
                    MaxFailedLoginsButton()
                }
            } learnMore: {
                LabeledContent(
                    L10n.lockedUsers,
                    value: L10n.maximumFailedLoginPolicyReenable
                )
                LabeledContent(
                    L10n.unlimited,
                    value: L10n.unlimitedFailedLoginDescription
                )
                LabeledContent(
                    L10n.default,
                    value: L10n.defaultFailedLoginDescription
                )
                LabeledContent(
                    L10n.custom,
                    value: L10n.customFailedLoginDescription
                )
            }
        }

        // MARK: - Failed Login Selection Button

        @ViewBuilder
        private func MaxFailedLoginsButton() -> some View {
            StateAdapter(initialValue: false) { isPresented in
                ChevronButton(
                    L10n.customFailedLogins,
                    content: Text(policy.loginAttemptsBeforeLockout ?? 1, format: .number)
                ) {
                    isPresented.wrappedValue = true
                }
                .alert(L10n.customFailedLogins, isPresented: isPresented) {
                    TextField(
                        L10n.failedLogins,
                        value: $policy.loginAttemptsBeforeLockout
                            .coalesce(1)
                            .clamp(min: 1, max: 1000),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } message: {
                    Text(L10n.enterCustomFailedLogins)
                }
            }
        }

        // MARK: - Failed Login Validation

        @ViewBuilder
        private var MaxSessionsView: some View {
            Section(
                L10n.maximumSessionsPolicy,
                footer: L10n.maximumConnectionsDescription
            ) {
                Picker(
                    L10n.maximumSessionsPolicy,
                    selection: $policy.maxActiveSessions.map(
                        getter: { ActiveSessionsPolicy(rawValue: $0) ?? .custom },
                        setter: { $0.rawValue }
                    )
                )

                if policy.maxActiveSessions != ActiveSessionsPolicy.unlimited.rawValue {
                    MaxSessionsButton()
                }
            } learnMore: {
                LabeledContent(
                    L10n.unlimited,
                    value: L10n.unlimitedConnectionsDescription
                )
                LabeledContent(
                    L10n.custom,
                    value: L10n.customConnectionsDescription
                )
            }
        }

        @ViewBuilder
        private func MaxSessionsButton() -> some View {
            StateAdapter(initialValue: false) { isPresented in
                ChevronButton(
                    L10n.customSessions,
                    content: Text(policy.maxActiveSessions ?? 1, format: .number)
                ) {
                    isPresented.wrappedValue = true
                }
                .alert(L10n.customSessions, isPresented: isPresented) {
                    TextField(
                        L10n.maximumSessions,
                        value: $policy.maxActiveSessions
                            .coalesce(1)
                            .clamp(min: 1, max: 1000),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } message: {
                    Text(L10n.enterCustomMaxSessions)
                }
            }
        }
    }
}
