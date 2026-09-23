//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
final class FocusCoordinator: ObservableObject {

    fileprivate struct Request: Equatable {
        let id: String
        let token = UUID()
    }

    @Published
    private(set) var focusedIDs: Set<String> = []
    @Published
    private(set) var lastFocusedIDs: Set<String> = []
    @Published
    fileprivate var request: Request?

    init(initial: String? = nil) {
        self.request = initial.map { Request(id: $0) }
    }

    func focus(_ id: String) {
        request = Request(id: id)
    }

    fileprivate func update(_ id: String, isFocused: Bool) {
        guard focusedIDs.contains(id) != isFocused else { return }

        if isFocused {
            focusedIDs.insert(id)
        } else {
            focusedIDs.remove(id)
        }

        if focusedIDs.isNotEmpty {
            lastFocusedIDs = focusedIDs
        }
    }
}

private struct CoordinatedFocusModifier: ViewModifier {

    @EnvironmentObject
    private var coordinator: FocusCoordinator

    @FocusState
    private var isFocused: Bool

    let id: String

    private func apply(_ request: FocusCoordinator.Request?) {
        guard let request else { return }

        if request.id == id {
            isFocused = true
        }
    }

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onAppear {
                apply(coordinator.request)
                coordinator.update(id, isFocused: isFocused)
            }
            .onChange(of: isFocused) {
                coordinator.update(id, isFocused: isFocused)
            }
            .onChange(of: coordinator.request) {
                apply(coordinator.request)
            }
            .onDisappear {
                coordinator.update(id, isFocused: false)
            }
    }
}

private struct CoordinatedFocusSelectionModifier: ViewModifier {

    @EnvironmentObject
    private var coordinator: FocusCoordinator

    let id: String
    let selection: FocusState<String?>.Binding

    private func apply(_ request: FocusCoordinator.Request?) {
        guard let request else { return }

        if request.id == id {
            selection.wrappedValue = id
        }
    }

    func body(content: Content) -> some View {
        content
            .focused(selection, equals: id)
            .onAppear {
                apply(coordinator.request)
                coordinator.update(id, isFocused: selection.wrappedValue == id)
            }
            .onChange(of: selection.wrappedValue) {
                coordinator.update(id, isFocused: selection.wrappedValue == id)
            }
            .onChange(of: coordinator.request) {
                apply(coordinator.request)
            }
            .onDisappear {
                coordinator.update(id, isFocused: false)
            }
    }
}

extension View {

    func coordinatedFocus(_ id: String) -> some View {
        modifier(CoordinatedFocusModifier(id: id))
    }

    func coordinatedFocus(
        _ id: String,
        selection: FocusState<String?>.Binding
    ) -> some View {
        modifier(CoordinatedFocusSelectionModifier(id: id, selection: selection))
    }
}
