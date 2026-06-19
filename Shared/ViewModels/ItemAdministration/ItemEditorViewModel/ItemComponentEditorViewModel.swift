//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

@MainActor
@Stateful
class ItemComponentEditorViewModel<Editor: ItemComponentEditor>: ViewModel {

    typealias Element = Editor.Element

    @CasePathable
    enum Action {
        case actuallySearch(String)
        case add([Element])
        case remove([Element])
        case reorder([Element])
        case search(String)

        var transition: Transition {
            switch self {
            case .add, .remove, .reorder:
                .background(.updating)
            case .search:
                .to(.initial)
            case .actuallySearch:
                .background(.searching)
            }
        }
    }

    enum BackgroundState {
        case updating
        case searching
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case error
    }

    @Published
    private(set) var item: BaseItemDto
    @Published
    private(set) var matches: [Element] = []

    let editor: Editor
    private var searchQuery: CurrentValueSubject<String, Never> = .init("")

    init(editor: Editor, item: BaseItemDto) {
        self.editor = editor
        self.item = item

        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                if query.isNotEmpty {
                    actuallySearch(query)
                } else {
                    matches = []
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ searchTerm: String) async throws {
        searchQuery.value = searchTerm

        await cancel()
    }

    @Function(\Action.Cases.actuallySearch)
    private func _actuallySearch(_ searchTerm: String) async throws {
        matches = try await editor.search(searchTerm, userSession: requireUserSession())
    }

    @Function(\Action.Cases.add)
    private func _add(_ elements: [Element]) async throws {
        try await updateItem(editor.adding(elements, to: item))
        editor.didAdd(elements)
    }

    @Function(\Action.Cases.remove)
    private func _remove(_ elements: [Element]) async throws {
        try await updateItem(editor.removing(elements, from: item))
    }

    @Function(\Action.Cases.reorder)
    private func _reorder(_ elements: [Element]) async throws {
        try await updateItem(editor.reordering(elements, in: item))
    }

    private func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemID = item.id else { return }

        var updateItem = newItem
        updateItem.trickplay = nil

        let request = Paths.updateItem(itemID: itemID, updateItem)
        _ = try await send(request)

        item = try await item.getFullItem(userSession: requireUserSession(), sendNotification: true)
        events.send(.updated)
    }
}
