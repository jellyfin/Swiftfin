//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.UIContainerViewController {

    struct SupplementContainerView: View {

        private static let buttonSpacing: CGFloat = UIDevice.isTV ? 20 : 10

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Environment(ViewState.self)
        private var viewState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedElement: String?

        #if os(iOS)
        @ViewBuilder
        private func closeButton(size: CGFloat) -> some View {
            Button {
                viewState.selectedSupplementID = nil
                UIDevice.impact(.light)
            } label: {
                Label(L10n.close, systemImage: "chevron.down")
                    .contentShape(Rectangle())
            }
            .frame(width: size, height: size)
            .modifier(
                VideoPlayer.PlaybackControls.OverlayBarButtonStyleModifier()
            )
        }
        #endif

        private var defaultTabFocus: String? {
            viewState.selectedSupplementID ?? viewState.supplements.first?.id
        }

        private var focusedSupplementID: String? {
            guard viewState.visibleElements.contains(.supplements) else { return nil }

            return viewState.supplements.first {
                $0.id == focusedElement
            }?.id
        }

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
                    .coordinatedFocus(ViewState.Focus.supplementContent(supplement.id))
            }
            .environment(viewState)
            .environmentObject(viewState.focusCoordinator)
            .environmentObject(manager)
            #if os(iOS)
            .background {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)
            }
            #endif
        }

        @ViewBuilder
        private var tabButtons: some View {
            AlternateLayoutView {
                // swiftlint:disable:next hard_coded_display_string
                Button("Hidden") {}
                    .frame(maxWidth: .infinity)
                    .disabled(true)
            } content: { (size: CGSize) in
                HStack(spacing: Self.buttonSpacing) {
                    #if os(iOS)
                    if viewState.isPresentingFullScreenSupplement {
                        closeButton(size: size.height)
                    }
                    #endif

                    SelectionTrack(
                        viewState.supplements,
                        id: \.id,
                        title: \.displayTitle,
                        selection: viewState.selectedSupplementID,
                        focus: $focusedElement,
                        spacing: Self.buttonSpacing
                    ) { supplement in
                        if UIDevice.isTV {
                            viewState.selectedSupplementID = supplement.id
                        } else {
                            viewState.selectedSupplementID = viewState.selectedSupplementID == supplement.id ? nil : supplement.id
                            UIDevice.impact(.light)
                        }
                    }
                    .coordinatedFocus(ViewState.Focus.supplementTabs)
                }
                .scrollIfLargerThanContainer(axes: .horizontal, alignment: .leading)
            }
            .edgePadding(.horizontal)
            #if os(tvOS)
            // Menu dismissal can restore an old tab before the guest content finishes appearing.
            // Keep tabs out of the focus engine until the requested control receives focus.
            .disabled(viewState.isGuestSupplementFocusPending)
            .defaultFocus(
                $focusedElement,
                defaultTabFocus,
                priority: .userInitiated
            )
            .focusSection()
            .onMoveCommand { direction in
                if direction == .up, viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = nil
                }
            }
            #endif
            .padding(
                .init(
                    top: 0,
                    leading: UIDevice.isTV ? 0 : safeAreaInsets.leading,
                    bottom: UIDevice.isTV ? 0 : 8,
                    trailing: UIDevice.isTV ? 0 : safeAreaInsets.trailing
                )
            )
            .buttonStyle(.capsule)
            .controlSize(.large)
            .foregroundStyle(.white)
        }

        var body: some View {
            ZStack {
                #if os(iOS)
                GestureView()
                    .environment(
                        \.panGestureDirection,
                        viewState.supplements.isEmpty ? [] : (viewState.presentationControllerShouldDismiss ? .up : .vertical)
                    )
                #endif

                VStack(alignment: .leading, spacing: 0) {

                    tabButtons

                    SupplementTabView(
                        data: viewState.supplements,
                        // UIKit callbacks must read the latest selection, even before SwiftUI renders again.
                        selection: Binding(
                            get: { viewState.selectedSupplementID },
                            set: { viewState.selectedSupplementID = $0 }
                        )
                    ) { supplement in
                        supplementContainer(for: supplement)
                            .eraseToAnyView()
                    }
                    #if os(tvOS)
                    .onSelectionPresented { id in
                            viewState.focusGuestSupplementIfNeeded(id)
                        }
                    #endif
                        .isVisible(viewState.isPresentingSupplement)
                    .enabled(viewState.isPresentingSupplement)
                    .animation(.linear(duration: 0.25), value: viewState.selectedSupplementID)
                }
                .isVisible(viewState.visibleElements.contains(.supplements))
                .enabled(viewState.visibleElements.contains(.supplements))
                .padding(.top, EdgeInsets.edgeInsets.bottom / (UIDevice.isTV ? 2 : 1))
                .animation(.linear(duration: 0.25), value: viewState.presentation)
                .animation(.linear(duration: 0.1), value: viewState.isScrubbing)
                .animation(.bouncy(duration: 0.25, extraBounce: 0.1), value: viewState.supplements.map(\.id))
            }
            .withViewContext(.isOverComplexContent)
            #if os(tvOS)
            .task(id: focusedSupplementID) {
                let previousSelection = viewState.selectedSupplementID
                guard !viewState.isGuestSupplementFocusPending,
                      let id = focusedSupplementID, id != previousSelection
                else { return }

                if previousSelection != nil {
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                    } catch {
                        return
                    }
                }

                guard !Task.isCancelled,
                      !viewState.isGuestSupplementFocusPending,
                      focusedSupplementID == id,
                      viewState.selectedSupplementID == previousSelection
                else { return }
                viewState.selectedSupplementID = id
            }
            #endif
            #if os(iOS)
            .environment(
                \.panAction,
                .init(
                    action: {
                        viewState.containerView?.handlePanGesture(
                            translation: $0,
                            velocity: $1,
                            location: $2,
                            unitPoint: $3,
                            state: $4
                        )
                    }
                )
            )
            .environment(
                \.tapGestureAction,
                .init(
                    action: {
                        viewState.containerView?.handleTapGesture(
                            location: $0,
                            unitPoint: $1,
                            count: $2
                        )
                    }
                )
            )
            #endif
        }
    }
}
