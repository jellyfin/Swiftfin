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

    @Published
    private(set) var focusedIDs: Set<String> = []
    @Published
    private(set) var lastFocusedIDs: Set<String> = []
    @Published
    fileprivate var request: String?

    init(initial: String? = nil) {
        self.request = initial
    }

    func focus(_ id: String) {
        request = id
    }

    fileprivate func update(_ id: String, isFocused: Bool) {
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

    private func apply(_ request: String?) {
        guard let request else { return }

        if request == id {
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
            .backport
            .onChange(of: isFocused) { _, isFocused in
                coordinator.update(id, isFocused: isFocused)
            }
            .backport
            .onChange(of: coordinator.request) { _, request in
                apply(request)
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

    private func apply(_ request: String?) {
        guard let request else { return }

        if request == id {
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
            .backport
            .onChange(of: selection.wrappedValue) { _, selection in
                coordinator.update(id, isFocused: selection == id)
            }
            .backport
            .onChange(of: coordinator.request) { _, request in
                apply(request)
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
