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

    let action: (LocalUserAccessPolicy, String?) async throws -> EvaluatedLocalUserAccessPolicy

    func callAsFunction(
        policy: LocalUserAccessPolicy,
        reason: String?
    ) async throws -> EvaluatedLocalUserAccessPolicy {
        try await action(policy, reason)
    }
}

extension EnvironmentValues {

    @Entry
    var localUserAuthenticationAction: LocalUserAuthenticationAction? = nil
}

struct WithLocalUserAuthentication<Content: View>: View {

    private struct PinRequest: Identifiable {
        let id: UUID
        let reason: String?
        let continuation: CheckedContinuation<String, Error>
    }

    @State
    private var pinRequest: PinRequest?

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private func handlePinAuthentication(reason: String?) async throws -> String {
        try Task.checkCancellation()
        let requestID = UUID()
        let pin: String = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled, pinRequest == nil else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                pinRequest = PinRequest(id: requestID, reason: reason, continuation: continuation)
            }
        } onCancel: {
            Task { @MainActor in
                completePinAuthentication(.failure(CancellationError()), requestID: requestID)
            }
        }

        try Task.checkCancellation()
        return pin
    }

    private func completePinAuthentication(_ result: Result<String, Error>, requestID: UUID?) {
        guard let request = pinRequest, request.id == requestID else { return }
        pinRequest = nil
        request.continuation.resume(with: result)
    }

    private func handleDeviceAuthentication(reason: String?) async throws {
        #if os(iOS)
        let context = LAContext()
        try context.canEvaluatePolicy(.deviceOwnerAuthentication)
        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ?? "")
        #else
        throw ErrorMessage(L10n.deviceAuthFailed)
        #endif
    }

    private func handleAuthentication(
        policy: LocalUserAccessPolicy,
        reason: String?
    ) async throws -> EvaluatedLocalUserAccessPolicy {
        switch policy {
        case .none:
            return Empty()
        case .requireDeviceAuthentication:
            try await handleDeviceAuthentication(reason: reason)
            return Empty()
        case .requirePin:
            let pin = try await handlePinAuthentication(reason: reason)
            guard (4 ... 30).contains(pin.count) else {
                throw ErrorMessage(L10n.invalidPin)
            }
            return PinEvaluatedUserAccessPolicy(pin: pin, pinHint: nil)
        }
    }

    var body: some View {
        content
            .environment(
                \.localUserAuthenticationAction,
                .init(action: handleAuthentication)
            )
            .pinEntry(
                isPresented: .constant(pinRequest != nil),
                requestID: pinRequest?.id,
                reason: pinRequest?.reason,
                completion: { [requestID = pinRequest?.id] result in
                    completePinAuthentication(result, requestID: requestID)
                }
            )
            .onDisappear {
                completePinAuthentication(.failure(CancellationError()), requestID: pinRequest?.id)
            }
    }
}
