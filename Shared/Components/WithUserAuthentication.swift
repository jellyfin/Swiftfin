//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
import SwiftUI

struct LocalUserAuthenticationAction {

    let action: (UserAccessPolicy, String?) async throws -> EvaluatedLocalUserAccessPolicy

    func callAsFunction(
        policy: UserAccessPolicy,
        reason: String?
    ) async throws -> EvaluatedLocalUserAccessPolicy {
        try await action(policy, reason)
    }
}

extension EnvironmentValues {

    @Entry
    var localUserAuthenticationAction: LocalUserAuthenticationAction? = nil
}

struct WithUserAuthentication<Content: View>: View {

    @State
    private var isPresentingLocalPin: Bool = false
    @State
    private var pin: String = ""
    @State
    private var pinContinuation: CheckedContinuation<Void, Error>? = nil
    @State
    private var reason: String? = nil

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private func handleDeviceAuthentication(reason: String?) async throws {
        #if os(iOS)
        let context = LAContext()
        try context.canEvaluatePolicy(.deviceOwnerAuthentication)
        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ?? "")
        #endif
    }

    private func handlePinAuthentication() async throws {
        isPresentingLocalPin = true

        return try await withCheckedThrowingContinuation { continuation in
            pinContinuation = continuation
        }
    }

    private func handleAuthentication(
        policy: UserAccessPolicy,
        reason: String?
    ) async throws -> EvaluatedLocalUserAccessPolicy {
        self.reason = reason

        switch policy {
        case .none:
            return EmptyEvaluatedUserAccessPolicy()
        case .requireDeviceAuthentication:
            try await handleDeviceAuthentication(reason: reason)
            return EmptyEvaluatedUserAccessPolicy()
        case .requirePin:
            try await handlePinAuthentication()
            return PinEvaluatedUserAccessPolicy(pin: pin, pinHint: nil)
        }
    }

    var body: some View {
        content
            .environment(
                \.localUserAuthenticationAction,
                .init(action: handleAuthentication)
            )
            .alert(
                L10n.pin,
                isPresented: $isPresentingLocalPin,
                presenting: pinContinuation
            ) { continuation in

                TextField(L10n.pin, text: $pin)
                    .keyboardType(.numberPad)

                // bug in SwiftUI: having .disabled will dismiss
                // alert but not call the closure (for length)
                Button(L10n.signIn) {
                    continuation.resume(returning: ())
                }
                .disabled((4 ... 30 ~= pin.count) == false)

                Button(L10n.cancel, role: .cancel) {
                    continuation.resume(throwing: CancellationError())
                }
                .tint(.red)
            } message: { _ in
                if let reason {
                    Text(reason)
                }
            }
            .backport
            .onChange(of: isPresentingLocalPin) { _, newValue in
                guard !newValue else { return }
                pinContinuation = nil
                pin = ""
            }
    }
}
