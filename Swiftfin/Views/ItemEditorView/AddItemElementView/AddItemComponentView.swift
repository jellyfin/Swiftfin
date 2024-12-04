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

    private let type: ItemElementType

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Initializer

    init(viewModel: ItemEditorViewModel<Element>, type: ItemElementType) {
        self.viewModel = viewModel
        self.type = type
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
                    case is BaseItemPerson.Type:
                        viewModel.send(.add([BaseItemPerson(name: name) as! Element]))
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
                validation: validation
            )
            MatchesSection(
                id: $id,
                name: $name,
                matches: viewModel.matches
            )
        }
    }

    // MARK: - Item Validation

    private var validation: (String) -> Bool {
        switch type {
        case .genres, .tags:
            { (viewModel.matches as! [String]).contains($0) }
        case .people:
            { (viewModel.matches as! [BaseItemPerson]).compactMap(\.name).contains($0) }
        case .studios:
            { (viewModel.matches as! [NameGuidPair]).compactMap(\.name).contains($0) }
        }
    }

    // MARK: - Item Navigation Title

    private var title: String {
        switch type {
        case .genres:
            L10n.genres
        case .people:
            L10n.people
        case .studios:
            L10n.studios
        case .tags:
            L10n.tags
        }
    }
}
