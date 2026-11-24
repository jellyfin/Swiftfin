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

        @AdaptiveLayout
        private var viewLayout

        @Environment(ViewState.self)
        private var viewState

        @ContentBuilder
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
            .onChange(of: viewState.overlayActions.map(\.focusID), initial: true) { oldIDs, _ in
                viewState.updateOverlayActionFocus(previousIDs: oldIDs)
            }
            .onChange(of: viewState.isPresentingCloseConfirmation) {
                if !viewState.isPresentingCloseConfirmation {
                    viewState.updateOverlayActionFocus()
                }
            }
            #endif
        }

        @ContentBuilder
        private func buttons(axis: Axis) -> some View {
            let layout = axis == .horizontal
                ? AnyLayout(HStackLayout(spacing: viewLayout.isLarge ? 24 : 12))
                : AnyLayout(VStackLayout(alignment: .trailing, spacing: 12))

            layout {
                ForEach(viewState.overlayActions) { action in
                    OverlayActionButton(action: action)
                }
            }
        }
    }

    private struct OverlayActionButton: View {

        @Environment(ViewState.self)
        private var viewState

        @GestureState(resetTransaction: Transaction(animation: .spring(duration: 0.3)))
        private var dragOffset: CGFloat = 0

        @State
        private var dismissalOffset: CGFloat?

        let action: VideoPlayerOverlayAction

        @ContentBuilder
        var body: some View {
            let offset = dismissalOffset ?? dragOffset

            Button {
                viewState.performOverlayAction(action.id)
            } label: {
                action.label
            }
            .buttonStyle(OverlayActionButtonStyle())
            .coordinatedFocus(action.focusID)
            .offset(x: offset)
            .opacity(1 - min(abs(offset) / 60, 1))
            #if os(iOS)
            .highPriorityGesture(
                DragGesture(minimumDistance: 10)
                    .updating($dragOffset) { value, offset, _ in
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        let distance = value.predictedEndTranslation.width
                        if abs(distance) > 120 {
                            dismiss(offset: distance < 0 ? -60 : 60)
                        }
                    }
            )
            #else
            .onMoveCommand { direction in
                switch direction {
                case .left: dismiss(offset: -60)
                case .right: dismiss(offset: 60)
                case .up, .down: viewState.showControls()
                default: break
                }
            }
            #endif
        }

        private func dismiss(offset: CGFloat) {
            withAnimation(.easeOut(duration: 0.25)) {
                dismissalOffset = offset
                viewState.dismissOverlayAction(action.id)
            }
        }
    }

    private struct OverlayActionButtonStyle: ButtonStyle {

        @AdaptiveLayout
        private var viewLayout

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.accessibilityReduceMotion)
        private var reduceMotion

        @ContentBuilder
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .symbolRenderingMode(.monochrome)
                .padding(.horizontal, viewLayout.isLarge ? 28 : 20)
                .padding(.vertical, viewLayout.isLarge ? 16 : 10)
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
