//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

final class ResetUserPasswordViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case success
    }

    // MARK: Action

    enum Action: Equatable {
        case reset(current: String, new: String)
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case resetting
    }

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var resetTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    func respond(to action: Action) -> State {
        switch action {
        case let .reset(current, new):
            resetTask = Task {
                do {
                    try await reset(current: current, new: new)

                    await MainActor.run {
                        self.eventSubject.send(.success)
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .resetting
        }
    }

    private func reset(current: String, new: String) async throws {
        let body = UpdateUserPassword(currentPw: current, newPw: new)
        let request = Paths.updateUserPassword(userID: userSession.user.id, body)

        try await userSession.client.send(request)
    }
}

// Note: can't do focus manipulation with `onSubmit` because `UmmaskSecureField`
//       is a manually wrapped `UITextField`. Could implement an `onSubmit`
//       equivalent modifier but isn't a big deal.

struct ResetUserPasswordView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @FocusState
    private var isCurrentFocused: Bool

    @State
    private var currentPassword: String = ""
    @State
    private var newPassword: String = ""
    @State
    private var confirmNewPassword: String = ""

    @State
    private var errorMessage: String = ""
    @State
    private var success: Bool = false
    @State
    private var isPresentingError: Bool = false

    @StateObject
    private var viewModel = ResetUserPasswordViewModel()

    var body: some View {
        List {

            UnmaskSecureField("Current Password", text: $currentPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($isCurrentFocused)

            Section {
                UnmaskSecureField("New Password", text: $newPassword)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)

                UnmaskSecureField("Confirm New Password", text: $confirmNewPassword)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)

                Button("Reset") {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .disabled(newPassword != confirmNewPassword || viewModel.state == .resetting)
            } footer: {
                if newPassword != confirmNewPassword {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)

                        Text("New passwords do not match")
                    }
                }
            }
        }
        .navigationTitle(L10n.password)
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(error):
                UIDevice.feedback(.error)
                self.errorMessage = error.localizedDescription
                self.isPresentingError = true
            case .success:
                UIDevice.feedback(.success)
                self.success = true
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingError
        ) {
            Button(L10n.dismiss, role: .cancel)
        }
        .alert(
            "Success",
            isPresented: $success
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.pop()
            }
        }
        .onFirstAppear {
            isCurrentFocused = true
        }
        .topBarTrailing {
            if viewModel.state == .resetting {
                ProgressView()
            }
        }
    }
}
