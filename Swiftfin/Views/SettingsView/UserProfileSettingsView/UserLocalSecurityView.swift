//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import LocalAuthentication
import SwiftUI

#warning("TODO: finish")

class UserLocalSecurityViewModel: ViewModel, Eventful {

    enum Event: Hashable {
        case promptForOldDeviceAuth
        case promptForOldPin

        case promptForNewDeviceAuth
        case promptForNewPin
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // Will throw and send event if needing to prompt for old auth.
    // TODO: do better.
    func checkForOldPolicy() throws {

        let oldPolicy = userSession.user.signInPolicy

        switch oldPolicy {
        case .requireDeviceAuthentication:
            eventSubject.send(.promptForOldDeviceAuth)

            throw JellyfinAPIError("Prompt for old device auth")
        case .requirePin:
            eventSubject.send(.promptForOldPin)

            throw JellyfinAPIError("Prompt for old pin")
        case .save: ()
        }
    }

    func set(newPolicy: UserAccessPolicy) {
        switch newPolicy {
        case .requireDeviceAuthentication:
            eventSubject.send(.promptForNewDeviceAuth)
        case .requirePin:
            eventSubject.send(.promptForNewPin)
        case .save: ()
        }
    }
}

struct UserLocalSecurityView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var isPresentingOldPinPrompt: Bool = false
    @State
    private var isPresentingNewPinPrompt: Bool = false
    @State
    private var onPinCompletion: (() -> Void)? = nil
    @State
    private var pin: String = ""
    @State
    private var signInPolicy: UserAccessPolicy = .save

    @StateObject
    private var viewModel = UserLocalSecurityViewModel()

    private func checkOldPolicy() {
        do {
            try viewModel.checkForOldPolicy()
        } catch {
            return
        }

        viewModel.set(newPolicy: signInPolicy)
    }

    var body: some View {
        List {

            Section {
                CaseIterablePicker(title: "Access", selection: $signInPolicy)
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(
                        "Additional security access for users signed in to this device. This does not change any Jellyfin server user settings."
                    )

                    BulletedList {

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Device Authentication")
                                .fontWeight(.semibold)

                            Text("Require local device authentication when signing in to the user.")
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pin")
                                .fontWeight(.semibold)

                            #warning("TODO: add unrecoverable message")
                            Text("Require a local pin when signing in to the user.")
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("None")
                                .fontWeight(.semibold)

                            Text("Save the user to this device without any local authentication.")
                        }
                    }
                }
            }
        }
        .animation(.linear, value: signInPolicy)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            signInPolicy = viewModel.userSession.user.signInPolicy
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .promptForOldDeviceAuth: ()
            case .promptForOldPin:
                onPinCompletion = {
                    try? viewModel.set(newPolicy: signInPolicy)
                }

                pin = ""
                isPresentingOldPinPrompt = true
            case .promptForNewDeviceAuth: ()
            case .promptForNewPin:
                onPinCompletion = {
                    router.popLast()
                }

                pin = ""
                isPresentingNewPinPrompt = true
            }
        }
        .topBarTrailing {
            Button {
                checkOldPolicy()
            } label: {
                Text("Save")
                    .foregroundStyle(accentColor.overlayColor)
                    .font(.headline)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        accentColor
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .opacity(signInPolicy == viewModel.userSession.user.signInPolicy ? 0 : 1)
        }
        .alert(
            "Enter Pin",
            isPresented: $isPresentingOldPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField("Pin", text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button("Sign In") {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text("Enter pin for \(viewModel.userSession.user.username)")
        }
        .alert(
            "Enter Pin",
            isPresented: $isPresentingNewPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField("Pin", text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button("Sign In") {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text("Create a pin to sign in to \(viewModel.userSession.user.username) on this device")
        }
    }
}
