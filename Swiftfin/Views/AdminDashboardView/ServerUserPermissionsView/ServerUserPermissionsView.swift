//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserPermissionsView: View {

    // MARK: - Environment

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    var viewModel: ServerUserAdminViewModel

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy

    @Default(.accentColor)
    private var accentColor

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    @State
    private var tempUsername: String
    @State
    private var tempMaxSessionsPolicy: ActiveSessionsPolicy
    @State
    private var tempLoginFailurePolicy: LoginFailurePolicy
    @State
    private var tempMaxBitratePolicy: MaxBitratePolicy
    @State
    private var isEditing: Bool = false

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
        self.tempUsername = viewModel.user.name ?? ""
        self.tempMaxSessionsPolicy = ActiveSessionsPolicy.from(rawValue: viewModel.user.policy?.maxActiveSessions ?? 0)
        self.tempLoginFailurePolicy = LoginFailurePolicy.from(
            rawValue: viewModel.user.policy?.loginAttemptsBeforeLockout ?? 0,
            isAdministrator: viewModel.user.policy?.isAdministrator ?? false
        )
        self.tempMaxBitratePolicy = MaxBitratePolicy.from(rawValue: viewModel.user.policy?.remoteClientBitrateLimit ?? 0)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .interactiveDismissDisabled(!isEditing)
            .navigationBarBackButtonHidden(!isEditing)
            .navigationTitle("Permissions") // L10n.profile
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    navigationBarEditView
                }
                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        toolBarSaveView
                    }
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                case .updated:
                    UIDevice.feedback(.success)
                    isPresentingSuccess = true
                    isEditing = false
                }
            }
            .alert(
                L10n.error.text,
                isPresented: $isPresentingError,
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert(
                L10n.success.text,
                isPresented: $isPresentingSuccess
            ) {
                Button(L10n.dismiss, role: .cancel) {}
            } message: {
                Text("User Profile Updated") // L10n.profileUpdated
            }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        switch viewModel.state {
        case let .error(error):
            ErrorView(error: error)
        case .initial:
            ErrorView(error: JellyfinAPIError("Loading user failed"))
        default:
            permissionsListView
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var permissionsListView: some View {
        List {
            UsernameSection(
                username: $tempUsername,
                policy: $tempPolicy
            )
            .environment(\.isEditing, isEditing)

            ManagementSection(policy: $tempPolicy)
                .environment(\.isEditing, isEditing)

            FeatureAccessSection(policy: $tempPolicy)
                .environment(\.isEditing, isEditing)

            MediaPlaybackSection(policy: $tempPolicy)
                .environment(\.isEditing, isEditing)

            ExternalAccessSection(
                maxBitratePolicy: $tempMaxBitratePolicy,
                policy: $tempPolicy
            )
            .environment(\.isEditing, isEditing)

            SyncPlaySection(policy: $tempPolicy)
                .environment(\.isEditing, isEditing)

            MediaDeletionSection()
            RemoteControlSection()
            PermissionsSection()
            SessionConfigurationSection()
        }
    }

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.state == .updating {
            ProgressView()
        } else {
            Button(isEditing ? L10n.cancel : L10n.edit) {
                isEditing.toggle()
                UIDevice.impact(.light)
                if !isEditing {
                    tempPolicy = viewModel.user.policy ?? UserPolicy()
                    tempUsername = viewModel.user.name ?? ""
                }
            }
            .buttonStyle(.toolbarPill)
        }
    }

    // MARK: - Toolbar Save Content

    @ViewBuilder
    private var toolBarSaveView: some View {
        Button(L10n.save) {
            if tempPolicy != viewModel.user.policy {
                viewModel.send(.updatePolicy(tempPolicy))
            }
            if tempUsername != viewModel.user.name {
                viewModel.send(.updateUsername(tempUsername))
            }
        }
        .buttonStyle(.toolbarPill)
        .disabled(viewModel.user.policy == tempPolicy && viewModel.user.name == tempUsername)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func MediaDeletionSection() -> some View {
        Section("Allow media deletion") {
            Toggle("All libaries", isOn: Binding(
                get: { tempPolicy.enableContentDeletion ?? false },
                set: { tempPolicy.enableContentDeletion = $0 }
            ))
            .disabled(!isEditing)

            // TODO: Get all of the folders for tempPolicy.enableContentDeletionFromFolders
        }
    }

    @ViewBuilder
    private func RemoteControlSection() -> some View {
        Section("Remote control") {
            Toggle("Control other users", isOn: Binding(
                get: { tempPolicy.enableRemoteControlOfOtherUsers ?? false },
                set: { tempPolicy.enableRemoteControlOfOtherUsers = $0 }
            ))
            .disabled(!isEditing)

            Toggle("Control shared devices", isOn: Binding(
                get: { tempPolicy.enableSharedDeviceControl ?? false },
                set: { tempPolicy.enableSharedDeviceControl = $0 }
            ))
            .disabled(!isEditing)
        }
    }

    @ViewBuilder
    private func PermissionsSection() -> some View {
        Section("Permissions") {
            Toggle("Allow media downloads", isOn: Binding(
                get: { tempPolicy.enableContentDownloading ?? false },
                set: { tempPolicy.enableContentDownloading = $0 }
            ))
            .disabled(!isEditing)

            Toggle("Hide user from login screen", isOn: Binding(
                get: { tempPolicy.isHidden ?? false },
                set: { tempPolicy.isHidden = $0 }
            ))
            .disabled(!isEditing)
        }
    }

    @ViewBuilder
    private func SessionConfigurationSection() -> some View {
        Section(L10n.session) {
            Picker("Maximum failed login policy", selection: $tempLoginFailurePolicy) {
                ForEach(
                    LoginFailurePolicy.allCases.filter {
                        if tempPolicy.isAdministrator ?? false {
                            return $0 != .userDefault
                        } else {
                            return $0 != .adminDefault
                        }
                    }, id: \.self
                ) { policy in
                    Text(policy.displayTitle).tag(policy)
                }
            }
            .onChange(of: tempLoginFailurePolicy) { newPolicy in
                tempPolicy.loginAttemptsBeforeLockout = newPolicy.rawValue
            }
            .disabled(!isEditing)

            if tempLoginFailurePolicy == .custom {
                MaxFailedLoginsButtonView()
                    .disabled(!isEditing)
            }

            Picker("Maximum sessions policy", selection: $tempMaxSessionsPolicy) {
                ForEach(ActiveSessionsPolicy.allCases, id: \.self) { policy in
                    Text(policy.displayTitle).tag(policy)
                }
            }
            .onChange(of: tempMaxSessionsPolicy) { newPolicy in
                tempPolicy.maxActiveSessions = newPolicy.rawValue
            }
            .disabled(!isEditing)

            if tempMaxSessionsPolicy == .custom {
                MaxSessionsButtonView()
                    .disabled(!isEditing)
            }
        }
    }

    @ViewBuilder
    private func MaxFailedLoginsButtonView() -> some View {
        ChevronAlertButton(
            "Custom failed logins",
            subtitle: (tempPolicy.loginAttemptsBeforeLockout ?? 0).description,
            description: "Enter custom failed logins limit"
        ) {
            TextField("Failed logins", value: $tempPolicy.loginAttemptsBeforeLockout, format: .number)
                .keyboardType(.numberPad)
        }
    }

    @ViewBuilder
    private func MaxSessionsButtonView() -> some View {
        ChevronAlertButton(
            "Custom sessions",
            subtitle: (tempPolicy.maxActiveSessions ?? 0).description,
            description: "Enter custom max sessions"
        ) {
            TextField("Maximum sessions", value: $tempPolicy.maxActiveSessions, format: .number)
                .keyboardType(.numberPad)
        }
    }

    // MARK: - Helper Methods

    private func resetTempValues() {
        tempMaxSessionsPolicy = ActiveSessionsPolicy.from(rawValue: tempPolicy.maxActiveSessions ?? 0)
        tempLoginFailurePolicy = LoginFailurePolicy.from(
            rawValue: tempPolicy.loginAttemptsBeforeLockout ?? -1,
            isAdministrator: tempPolicy.isAdministrator ?? false
        )
        tempMaxBitratePolicy = MaxBitratePolicy.from(rawValue: tempPolicy.remoteClientBitrateLimit ?? 0)
    }
}

enum LoginFailurePolicy: Int, Displayable, CaseIterable {
    case unlimited = -1
    case userDefault = 3
    case adminDefault = 5
    case custom = 0 // Default to 0

    // MARK: - Display Title

    var displayTitle: String {
        switch self {
        case .unlimited:
            return "Unlimited"
        case .userDefault, .adminDefault:
            return "Default"
        case .custom:
            return L10n.custom
        }
    }

    // MARK: - Get Policy from a Bitrate (Int)

    static func from(rawValue: Int, isAdministrator: Bool) -> LoginFailurePolicy {
        var policy = LoginFailurePolicy(rawValue: rawValue)

        if isAdministrator && policy == .userDefault {
            return .custom
        } else if !isAdministrator && policy == .adminDefault {
            return .custom
        } else {
            return policy ?? .custom
        }
    }
}

enum ActiveSessionsPolicy: Int, Displayable, CaseIterable {
    case unlimited = 0
    case custom = 1 // Default to 1 Active Session

    // MARK: - Display Title

    var displayTitle: String {
        switch self {
        case .unlimited:
            return "Unlimited"
        case .custom:
            return L10n.custom
        }
    }

    // MARK: - Get Policy from a Bitrate (Int)

    static func from(rawValue: Int) -> ActiveSessionsPolicy {
        ActiveSessionsPolicy(rawValue: rawValue) ?? .custom
    }
}

enum MaxBitratePolicy: Int, Displayable, CaseIterable {
    case unlimited = 0
    case custom = 10_000_000 // Default to 10mbps

    // MARK: - Display Title

    var displayTitle: String {
        switch self {
        case .unlimited:
            return "Unlimited"
        case .custom:
            return L10n.custom
        }
    }

    // MARK: - Get Policy from a Bitrate (Int)

    static func from(rawValue: Int) -> MaxBitratePolicy {
        MaxBitratePolicy(rawValue: rawValue) ?? .custom
    }
}
