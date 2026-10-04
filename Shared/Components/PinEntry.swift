//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    func pinEntry(
        isPresented: Binding<Bool>,
        requestID: UUID? = nil,
        reason: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) -> some View {
        modifier(
            PinEntryModifier(
                isPresented: isPresented,
                requestID: requestID,
                reason: reason,
                completion: completion
            )
        )
    }
}

private struct PinEntryModifier: ViewModifier {

    @Binding
    var isPresented: Bool

    let requestID: UUID?
    let reason: String?
    let completion: (Result<String, Error>) -> Void

    @State
    private var pin = ""

    private func finish(_ result: Result<String, Error>) {
        pin = ""
        isPresented = false
        completion(result)
    }

    func body(content: Content) -> some View {
        content
            #if os(tvOS)
                .background {
                    if isPresented {
                        PinTextField(
                            isPresented: isPresented,
                            reason: reason,
                            completion: finish
                        )
                        .id(requestID)
                    }
                }
            #else
                .alert(L10n.pin, isPresented: $isPresented) {
                    SecureField(L10n.pin, text: $pin)

                    Button(L10n.done) {
                        finish(.success(pin))
                    }
                    Button(L10n.cancel, role: .cancel) {
                        finish(.failure(CancellationError()))
                    }
                    .tint(.red)
                } message: {
                    if let reason {
                        Text(reason)
                    }
                }
            #endif
                .onChange(of: isPresented) {
                    if !isPresented {
                        finish(.failure(CancellationError()))
                    }
            }
            .onDisappear {
                finish(.failure(CancellationError()))
            }
    }
}

#if os(tvOS)
private struct PinTextField: UIViewRepresentable {

    let isPresented: Bool
    let reason: String?
    let completion: (Result<String, Error>) -> Void

    func makeUIView(context: Context) -> TextField {
        TextField()
    }

    func updateUIView(_ uiView: TextField, context: Context) {
        uiView.completion = completion
        uiView.placeholder = reason ?? L10n.pin
        uiView.isPresented = isPresented
        uiView.presentIfNeeded()
    }

    static func dismantleUIView(_ uiView: TextField, coordinator: ()) {
        uiView.isPresented = false
        uiView.completion = nil
        uiView.resignFirstResponder()
        uiView.text = nil
    }

    final class TextField: UITextField, UITextFieldDelegate {

        var isPresented = false
        var completion: ((Result<String, Error>) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            delegate = self
            isSecureTextEntry = true
            returnKeyType = .done
            textContentType = nil
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            presentIfNeeded()
        }

        func presentIfNeeded() {
            textContentType = nil
            guard window != nil else { return }

            // Wait until SwiftUI has finished updating the presentation state.
            DispatchQueue.main.async { [weak self] in
                guard let self, window != nil else { return }
                if isPresented, !isFirstResponder {
                    // A second PIN request must wait for the previous text entry controller to dismiss.
                    var controller = window?.rootViewController
                    while let presented = controller?.presentedViewController {
                        controller = presented
                    }
                    if let transition = controller?.transitionCoordinator,
                       transition.animate(alongsideTransition: nil, completion: { [weak self] _ in
                           self?.presentIfNeeded()
                       })
                    {
                        return
                    }
                    becomeFirstResponder()
                } else if !isPresented {
                    resignFirstResponder()
                    text = nil
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            guard isPresented else { return }

            let result: Result<String, Error> = if reason == .committed {
                .success(textField.text ?? "")
            } else {
                .failure(CancellationError())
            }

            isPresented = false
            text = nil
            completion?(result)
        }
    }
}
#endif
