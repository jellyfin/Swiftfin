//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Logging
import SwiftUI

@MainActor
@Observable
final class FocusScope {

    fileprivate let logger = Logger.swiftfin()

    private(set) var placed: AnyHashable?
    private(set) var targets: Set<AnyHashable> = []

    func isRegistered(_ target: some Hashable) -> Bool {
        targets.contains(AnyHashable(target))
    }

    fileprivate func place(_ target: AnyHashable) {
        placed = target

        logger.debug("place \(target)")
    }

    fileprivate func register(_ target: AnyHashable) {
        targets.insert(target)

        logger.debug("register \(target) [\(targets.count)]")
    }

    fileprivate func unregister(_ target: AnyHashable) {
        targets.remove(target)
    }
}

extension EnvironmentValues {

    @Entry
    var focusScope: FocusScope?
}

struct InitialFocusModifier<Destination: FocusTarget>: ViewModifier {

    @FocusState
    private var isHoldingFocus: Bool

    @State
    private var hasPlacedFocus: Bool = false
    @State
    private var internalScope = FocusScope()

    let target: InitialFocus<Destination>
    let holdsFocus: Bool
    let binding: FocusState<Destination?>.Binding
    let scope: FocusScope?

    private var focusScope: FocusScope {
        scope ?? internalScope
    }

    private var isReady: Bool {
        switch target {
        case .waiting:
            false
        case .automatic:
            true
        case let .destination(destination):
            focusScope.isRegistered(destination)
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.focusScope, focusScope)
            .overlay {
                if holdsFocus, !hasPlacedFocus {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                        .focusable()
                        .focusEffectDisabled()
                        .hoverEffectDisabled()
                        .focused($isHoldingFocus)
                        .onAppear {
                            isHoldingFocus = true

                            focusScope.logger.debug("holding \(Destination.self)")
                        }
                }
            }
            .task(id: isReady) {
                guard isReady, !hasPlacedFocus else { return }

                if case let .destination(destination) = target {
                    focusScope.place(AnyHashable(destination))
                    binding.wrappedValue = destination
                } else {
                    hasPlacedFocus = true
                }
            }
            .onChange(of: isHoldingFocus) {
                guard !isHoldingFocus, !hasPlacedFocus else { return }

                focusScope.logger.debug("released \(Destination.self)")

                hasPlacedFocus = true
            }
            .onChange(of: focusScope.placed) {
                guard focusScope.placed != nil, !isHoldingFocus, !hasPlacedFocus else { return }

                hasPlacedFocus = true
            }
    }
}

struct InitialFocusTargetModifier<ID: FocusTarget>: ViewModifier {

    @Environment(\.focusScope)
    private var focusScope

    @FocusState
    private var isFocused: Bool

    let id: ID
    let binding: FocusState<ID?>.Binding?

    @ViewBuilder
    private func focused(_ content: Content) -> some View {
        if let binding {
            content.focused(binding, equals: id)
        } else {
            content.focused($isFocused)
        }
    }

    func body(content: Content) -> some View {
        focused(content)
            .onAppear {
                focusScope?.register(AnyHashable(id))
            }
            .onChange(of: isFocused) {
                focusScope?.logger.debug("target \(id) engine focus: \(isFocused)")
            }
            .onChange(of: focusScope?.placed) {
                guard binding == nil, focusScope?.placed == AnyHashable(id) else { return }

                focusScope?.logger.debug("self-focusing \(id)")

                isFocused = true
            }
            .onDisappear {
                focusScope?.unregister(AnyHashable(id))
            }
    }
}
