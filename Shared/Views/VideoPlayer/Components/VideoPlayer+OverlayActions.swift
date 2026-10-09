//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct OverlayActions: View {

        @Environment(ViewState.self)
        private var viewState

        @FocusState
        private var focusedAction: String?

        private var actions: [ViewState.OverlayAction] {
            viewState.visibleElements.contains(.overlayActions) ? viewState.overlayActions : []
        }

        var body: some View {
            ViewThatFits(in: .horizontal) {
                buttons(axis: .horizontal)
                #if os(tvOS)
                ScrollView(.horizontal) {
                    buttons(axis: .horizontal)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .fixedSize(horizontal: false, vertical: true)
                #else
                buttons(axis: .vertical)
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            #if os(tvOS)
            .focusSection()
            .onMoveCommand { direction in
                if viewState.presentation == .hidden, direction == .up || direction == .down {
                    viewState.showControls()
                }
            }
            .onChange(of: actions.map(\.id), initial: true) { oldIDs, _ in
                viewState.updateOverlayActionFocus(previousIDs: oldIDs)
            }
            .onChange(of: viewState.presentation) {
                viewState.updateOverlayActionFocus()
            }
            .onChange(of: viewState.isPresentingCloseConfirmation) {
                if !viewState.isPresentingCloseConfirmation {
                    viewState.updateOverlayActionFocus()
                }
            }
            #endif
        }

        private func buttons(axis: Axis) -> some View {
            let layout = axis == .horizontal
                ? AnyLayout(HStackLayout(spacing: UIDevice.isTV ? 24 : 12))
                : AnyLayout(VStackLayout(alignment: .trailing, spacing: 12))

            return layout {
                ForEach(actions) { action in
                    Button {
                        viewState.performOverlayAction(action.id)
                    } label: {
                        if let systemImage = action.button.systemImage {
                            Label(action.button.title, systemImage: systemImage)
                        } else {
                            Text(action.button.title)
                        }
                    }
                    .buttonStyle(OverlayActionButtonStyle())
                    .coordinatedFocus(action.id.focusID, selection: $focusedAction)
                }
            }
        }
    }

    private struct OverlayActionButtonStyle: ButtonStyle {

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.accessibilityReduceMotion)
        private var reduceMotion

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .symbolRenderingMode(.monochrome)
                .padding(.horizontal, UIDevice.isTV ? 28 : 20)
                .padding(.vertical, UIDevice.isTV ? 16 : 10)
                .frame(minHeight: 44)
                .background(.white, in: Capsule())
                .contentShape(Capsule())
                .scaleEffect(isFocused && !reduceMotion ? 1.08 : 1)
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0.2), radius: isFocused ? 12 : 4)
                .opacity(isEnabled ? (configuration.isPressed ? 0.65 : 1) : 0.5)
                .animation(.easeOut(duration: 0.15), value: isFocused)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
