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

    enum InitialFocusRole {
        /// Holds focus while waiting for the initial content without requesting it.
        case placeholder
        /// Becomes available after the initial target receives focus.
        case secondary
        /// Releases secondary controls when there is no initial target, such as an empty or error view.
        case fallback
    }

    @Published
    private(set) var focusedIDs: Set<String> = []
    @Published
    private(set) var lastFocusedIDs: Set<String> = []
    @Published
    fileprivate var request: String?

    @Published
    private var pendingInitialFocusID: String?

    var isInitialFocusPending: Bool {
        pendingInitialFocusID != nil
    }

    init(initial: String? = nil) {
        self.request = initial
    }

    /// Defers secondary controls until the target receives focus naturally.
    /// This does not request focus when the target appears or steal focus from another view.
    init(waitingFor id: String) {
        self.pendingInitialFocusID = id
    }

    func focus(_ id: String) {
        resolveInitialFocus()
        request = id
    }

    /// Completes initial focus once, including when loading ends without a target.
    func resolveInitialFocus() {
        guard pendingInitialFocusID != nil else { return }
        pendingInitialFocusID = nil
    }

    fileprivate func update(_ id: String, isFocused: Bool) {
        if isFocused {
            focusedIDs.insert(id)

            if pendingInitialFocusID == id {
                resolveInitialFocus()
            }
        } else {
            focusedIDs.remove(id)
        }

        if focusedIDs.isNotEmpty {
            lastFocusedIDs = focusedIDs
        }
    }
}

#if os(tvOS)
private struct CoordinatedFocusScopeModifier<Value: Hashable>: ViewModifier {

    @State
    private var lastSelection: Value?

    let selection: FocusState<Value?>.Binding
    let values: [Value]

    private var preferredSelection: Value? {
        lastSelection.flatMap { values.contains($0) ? $0 : nil } ?? values.first
    }

    func body(content: Content) -> some View {
        content
            .focusSection()
            .defaultFocus(
                selection,
                preferredSelection,
                priority: selection.wrappedValue == nil ? .userInitiated : .automatic
            )
            .onChange(of: selection.wrappedValue) { _, newValue in
                guard let newValue else { return }
                lastSelection = newValue
            }
    }
}
#endif

private struct CoordinatedInitialFocusModifier: ViewModifier {

    @EnvironmentObject
    private var coordinator: FocusCoordinator

    let role: FocusCoordinator.InitialFocusRole

    @ViewBuilder
    func body(content: Content) -> some View {
        switch role {
        case .placeholder:
            content
                .focusable(coordinator.isInitialFocusPending)
                .focusEffectDisabled()
        case .secondary:
            content
                .disabled(coordinator.isInitialFocusPending)
        case .fallback:
            content
                .onAppear {
                    coordinator.resolveInitialFocus()
                }
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

    #if os(tvOS)
    /// Remembers focus within a container, using the first value when no remembered target remains.
    /// Apply this to the stack or scroll view containing the coordinated controls.
    func coordinatedFocusScope<Value: Hashable>(
        _ selection: FocusState<Value?>.Binding,
        values: [Value]
    ) -> some View {
        modifier(CoordinatedFocusScopeModifier(selection: selection, values: values))
    }
    #endif

    func coordinatedFocus(_ role: FocusCoordinator.InitialFocusRole) -> some View {
        modifier(CoordinatedInitialFocusModifier(role: role))
    }

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
