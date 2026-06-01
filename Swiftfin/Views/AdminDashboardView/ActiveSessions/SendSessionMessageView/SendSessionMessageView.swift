//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SendSessionMessageView: View {

    private enum Field {
        case header
        case text
    }

    @FocusState
    private var focusedField: Field?

    @Router
    private var router

    @State
    private var header = ""
    @State
    private var text = ""
    @State
    private var timeoutSeconds = 5

    @StateObject
    private var viewModel: SendSessionMessageViewModel

    private let session: SessionInfoDto

    private var isSending: Bool {
        viewModel.state == .sending
    }

    private var isValid: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    init(session: SessionInfoDto) {
        self.session = session

        self._viewModel = StateObject(
            wrappedValue: SendSessionMessageViewModel(sessionID: session.id ?? "")
        )
    }

    var body: some View {
        List {
            Section {
                TextField(L10n.title, text: $header)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .header)
                    .disabled(isSending)
            } header: {
                Text(L10n.title)
            }

            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .focused($focusedField, equals: .text)
                    .disabled(isSending)
            } header: {
                Text(L10n.message)
            } footer: {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Label(L10n.messageRequired, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section(L10n.duration) {
                Stepper(
                    value: $timeoutSeconds,
                    in: 1 ... 60,
                    step: 1
                ) {
                    Text(Duration.seconds(timeoutSeconds).formatted(.units(allowed: [.seconds])))
                }
                .disabled(isSending)
            }
        }
        .animation(.linear(duration: 0.1), value: isValid)
        .interactiveDismissDisabled(isSending)
        .navigationTitle(L10n.sendMessage)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: isSending) {
            router.dismiss()
        }
        .onFirstAppear {
            focusedField = .text
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .sent:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .topBarTrailing {
            if isSending {
                ProgressView()
            }

            Button(L10n.send) {
                viewModel.send(
                    header: header,
                    text: text,
                    timeoutSeconds: timeoutSeconds
                )
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid || isSending || session.id == nil)
        }
        .errorMessage($viewModel.error) {
            focusedField = .text
        }
    }
}
