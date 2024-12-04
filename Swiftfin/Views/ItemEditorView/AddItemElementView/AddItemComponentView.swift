//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct AddItemComponentView<Element: Hashable>: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    var viewModel: ItemEditorViewModel<Element>

    @State
    private var id: String?
    @State
    private var name: String = ""

    private let title: String

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Initializer

    init(viewModel: ItemEditorViewModel<Element>, title: String) {
        self.viewModel = viewModel
        self.title = title
    }

    // MARK: - Name is Valid

    private var isValid: Bool {
        name.isNotEmpty
    }

    // MARK: - Body

    var body: some View {
        contentView
            .animation(.linear(duration: 0.2), value: isValid)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }

                Button(L10n.save) {
                    switch Element.self {
                    case is String.Type:
                        viewModel.send(.add([name as! Element]))
                    case is NameGuidPair.Type:
                        viewModel.send(.add([NameGuidPair(id: id, name: name) as! Element]))
                    case is String.Type:
                        viewModel.send(.add([BaseItemPerson(id: id, name: name) as! Element]))
                    default:
                        break
                    }
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
            .onFirstAppear {
                viewModel.send(.refresh)
            }
            .onChange(of: name) { _ in
                viewModel.send(.getMatches(name))
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                }
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingError,
                presenting: error
            ) { error in
                Text(error.localizedDescription)
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            NameInput(
                name: $name,
                matches: viewModel.matches
            )
            MatchesSection(
                id: $id,
                name: $name,
                matches: viewModel.matches
            )
        }
    }
}
