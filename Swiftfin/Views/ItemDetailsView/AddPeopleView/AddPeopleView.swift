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

struct AddPeopleView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @FocusState
    private var focusedField: Bool

    @ObservedObject
    var viewModel: ItemDetailsViewModel

    @State
    private var name: String = ""
    @State
    private var selectedType: PersonKind = .actor
    @State
    private var role: String = ""

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    private var isValid: Bool {
        !name.isEmpty
    }

    // MARK: - Body

    var body: some View {
        contentView
            .animation(.linear(duration: 0.2), value: isValid)
            .interactiveDismissDisabled(viewModel.state == .refreshing)
            .navigationTitle(L10n.people)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .onFirstAppear {
                focusedField = true
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .added:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                default:
                    break
                }
            }
            .topBarTrailing {
                if viewModel.state == .refreshing {
                    ProgressView()
                }

                Button(L10n.save) {
                    createPerson()
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingError,
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {
                    focusedField = true
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {

            // MARK: Name Section

            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($focusedField)
                    .disabled(viewModel.state == .refreshing)
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            // MARK: Type Picker Section

            Section(header: Text(L10n.role)) {
                Picker(L10n.type, selection: $selectedType) {
                    ForEach(PersonKind.allCases, id: \.self) { type in
                        Text(type.displayTitle).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .focused($focusedField)
                .disabled(viewModel.state == .refreshing)
            }

            // MARK: Role TextField (Visible only for Actors)

            if selectedType == .actor {
                Section(L10n.role) {
                    TextField(L10n.role, text: $role)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .focused($focusedField)
                        .disabled(viewModel.state == .refreshing)
                }
            }
        }
    }

    // MARK: - Create Person Action

    private func createPerson() {
        let newPerson = BaseItemPerson(
            name: name,
            role: selectedType == .actor ? role : nil,
            type: selectedType.rawValue
        )

        viewModel.send(.addPeople([newPerson]))
    }
}
