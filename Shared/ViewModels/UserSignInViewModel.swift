//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import Get
import JellyfinAPI
import KeychainSwift
import OrderedCollections
import SwiftUI

// TODO: instead of just signing in duplicate user, send event for alert
//       to override existing user access token?
//       - won't require deleting and re-signing in user for password changes
//       - account for local device auth required
// TODO: ignore NSURLErrorDomain Code=-999 cancelled error on sign in
//       - need to make NSError wrappres anyways

// Note: UserDto in StoredValues so that it doesn't need to be passed
//       around along with the user UserState. Was just easy

@MainActor
@Stateful
final class UserSignInViewModel: ViewModel {

    typealias AccessPolicyPair = (policy: UserAccessPolicy, evaluated: any EvaluatedLocalUserAccessPolicy)
    typealias UserStateDataPair = (state: (state: UserState, accessToken: String), data: UserDto)

    struct EvaluatedPolicyMap {
        let action: (any EvaluatedLocalUserAccessPolicy) -> any EvaluatedLocalUserAccessPolicy

        func callAsFunction(evaluatedPolicy: any EvaluatedLocalUserAccessPolicy) -> any EvaluatedLocalUserAccessPolicy {
            action(evaluatedPolicy)
        }
    }

    @CasePathable
    enum Action {
        case cancel
        case error
        case getPublicData
        case signIn(username: String, password: String)
        case signInQuickConnect(secret: String)

        case save(
            user: UserStateDataPair,
            authenticationAction: (action: LocalUserAuthenticationAction, accessPolicy: UserAccessPolicy, reason: String?),
            evaluatedPolicyMap: EvaluatedPolicyMap
        )
        case saveExisting(
            user: UserStateDataPair,
            replaceForAccessToken: Bool,
            authenticationAction: (action: LocalUserAuthenticationAction, accessPolicy: UserAccessPolicy, reason: String?),
            evaluatedPolicyMap: EvaluatedPolicyMap
        )

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .error, .save, .saveExisting:
                .none
            case .getPublicData:
                .background(.gettingPublicData)
            case .signIn, .signInQuickConnect:
                .loop(.signingIn)
            }
        }
    }

    enum BackgroundState {
        case gettingPublicData
    }

    enum Event {
        case connected(UserStateDataPair)
        case existingUser(UserStateDataPair)
        case saved(UserState)
    }

    enum State {
        case initial
        case signingIn
    }

    @Published
    private(set) var isQuickConnectEnabled = false
    @Published
    private(set) var publicUsers: [UserDto] = []
    @Published
    private(set) var serverDisclaimer: String? = nil

    let server: ServerState

    init(server: ServerState) {
        self.server = server
        super.init()
    }

    @Function(\Action.Cases.getPublicData)
    private func _getPublicData() async throws {
        async let isQuickConnectEnabled = try retrieveIsQuickConnectEnabled()
        async let publicUsers = try retrievePublicUsers()
        async let serverDisclaimer = try retrieveServerDisclaimer()

        self.isQuickConnectEnabled = try await isQuickConnectEnabled
        self.publicUsers = try await publicUsers
        self.serverDisclaimer = try await serverDisclaimer
    }

    @Function(\Action.Cases.signIn)
    private func _signIn(
        _ username: String,
        _ password: String
    ) async throws {
        let username = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let password = password
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let response = try await server.client.signIn(username: username, password: password)

        guard let accessToken = response.accessToken,
              let userData = response.user,
              let id = userData.id,
              let username = userData.name
        else {
            logger.critical("Missing user data from network call")
            throw ErrorMessage(L10n.unknownError)
        }

        if let existingUser = existingUser(id: id) {
            events.send(.existingUser(((existingUser, accessToken), userData)))
        } else {
            let newUserState = UserState(
                id: id,
                serverID: server.id,
                username: username
            )

            events.send(.connected(((newUserState, accessToken), userData)))
        }
    }

    @Function(\Action.Cases.signInQuickConnect)
    private func _signInQuickConnect(
        _ secret: String
    ) async throws {
        let response = try await server.client.signIn(quickConnectSecret: secret)

        guard let accessToken = response.accessToken,
              let userData = response.user,
              let id = userData.id,
              let username = userData.name
        else {
            logger.error("Missing user data from network call")
            throw ErrorMessage(L10n.unknownError)
        }

        if let existingUser = existingUser(id: id) {
            events.send(.existingUser(((existingUser, accessToken), userData)))
        } else {
            let newUserState = UserState(
                id: id,
                serverID: server.id,
                username: username
            )

            events.send(.connected(((newUserState, accessToken), userData)))
        }
    }

    private func existingUser(id: String) -> UserState? {
        try? SwiftfinStore
            .dataStack
            .fetchOne(From<UserModel>().where(\.$id == id))?
            .state
    }

    @Function(\Action.Cases.save)
    private func _save(
        _ user: UserStateDataPair,
        _ authenticationAction: (action: LocalUserAuthenticationAction, accessPolicy: UserAccessPolicy, reason: String?),
        _ evaluatedPolicyMap: EvaluatedPolicyMap
    ) async throws {

        let accessPolicy = authenticationAction.accessPolicy

        let evaluatedPolicy = try await evaluatedPolicyMap(
            evaluatedPolicy: authenticationAction.action(
                policy: accessPolicy,
                reason: authenticationAction.reason
            )
        )

        let userState = user.state.state

        guard let serverModel = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            logger.critical("Unable to find server to save user")
            throw ErrorMessage(L10n.unknownError)
        }

        let savedUserState = try dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

            newUser.id = userState.id
            newUser.username = userState.username

            let editServer = transaction.edit(serverModel)!
            editServer.users.insert(newUser)

            return newUser.state
        }

        savedUserState.accessPolicy = accessPolicy
        savedUserState.accessToken = user.state.accessToken
        savedUserState.data = user.data

        if let evaluatedPinPolicy = evaluatedPolicy as? PinEvaluatedUserAccessPolicy {
            if let pinHint = evaluatedPinPolicy.pinHint {
                savedUserState.pinHint = pinHint
            }

            savedUserState.pin = evaluatedPinPolicy.pin
        }

        events.send(.saved(savedUserState))
    }

    @Function(\Action.Cases.saveExisting)
    private func _saveExisting(
        _ user: UserStateDataPair,
        _ replaceForAccessToken: Bool,
        _ authenticationAction: (action: LocalUserAuthenticationAction, accessPolicy: UserAccessPolicy, reason: String?),
        _ evaluatedPolicyMap: EvaluatedPolicyMap
    ) async throws {

        let accessPolicy = authenticationAction.accessPolicy

        let evaluatedPolicy = try await evaluatedPolicyMap(
            evaluatedPolicy: authenticationAction.action(
                policy: accessPolicy,
                reason: authenticationAction.reason
            )
        )

        if let evaluatedPinPolicy = evaluatedPolicy as? PinEvaluatedUserAccessPolicy {
            guard user.state.state.pin == evaluatedPinPolicy.pin else {
                throw ErrorMessage(L10n.incorrectPinForUser(user.state.state.username))
            }
        }

        if replaceForAccessToken {
            user.state.state.accessToken = user.state.accessToken
        }

        events.send(.saved(user.state.state))
    }

    private func retrievePublicUsers() async throws -> [UserDto] {
        let request = Paths.getPublicUsers
        let response = try await server.client.send(request)

        return response.value
    }

    private func retrieveServerDisclaimer() async throws -> String? {
        let request = Paths.getBrandingOptions
        let response = try await server.client.send(request)

        guard let disclaimer = response.value.loginDisclaimer, disclaimer.isNotEmpty else { return nil }

        return disclaimer
    }

    private func retrieveIsQuickConnectEnabled() async throws -> Bool {
        let request = Paths.getEnabled
        let response = try await server.client.send(request)

        let isEnabled = try? JSONDecoder().decode(Bool.self, from: response.value)
        return isEnabled ?? false
    }
}
