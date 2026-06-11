//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController {

    struct SupplementContainerView: View {

        enum SupplementElement: Hashable {
            case focusBoundary
            case supplementTab(AnyMediaPlayerSupplement.ID)
        }

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedElement: SupplementElement?

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        private var defaultTabFocus: SupplementElement? {
            if let id = containerState.selectedSupplement?.id {
                return .supplementTab(id)
            }
            return currentSupplements.first.map { .supplementTab($0.id) }
        }

        private var isTitleBarFocused: Bool {
            if case .supplementTab = focusedElement {
                return true
            }

            return false
        }

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
            }
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
            } content: {
                HStack(spacing: UIDevice.isTV ? 20 : 10) {
                    if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                        Button(supplement.displayTitle) {
                            containerState.select(supplement: nil)
                        }
                        .isSelected(true)
                        .focused($focusedElement, equals: .supplementTab(supplement.id))
                    } else {
                        ForEach(currentSupplements) { supplement in
                            let isSelected = containerState.selectedSupplement?.id == supplement.id

                            Button(supplement.displayTitle) {
                                if !UIDevice.isTV {
                                    containerState.select(supplement: supplement.supplement)
                                }
                            }
                            .isSelected(isSelected)
                            .focused($focusedElement, equals: .supplementTab(supplement.id))
                        }
                    }
                }
                .scrollIfLargerThanContainer(axes: .horizontal, alignment: .leading)
            }
            .edgePadding(.horizontal)
            .focusSection()
            .backport
            .defaultFocus(
                $focusedElement,
                defaultTabFocus,
                priority: .userInitiated
            )
            .if(!UIDevice.isTV) { view in
                view
                    .padding(.leading, safeAreaInsets.leading)
                    .padding(.trailing, safeAreaInsets.trailing)
                    .padding(.bottom, 8)
            }
            .buttonStyle(SupplementTitleButtonStyle())
        }

        @ViewBuilder
        private var supplementContent: some View {
            ZStack {
                if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                    supplementContainer(for: AnyMediaPlayerSupplement(supplement))
                } else {
                    #if os(iOS)
                    SupplementTabView(
                        items: Array(currentSupplements),
                        selection: $containerState.selectedSupplement.map(
                            getter: { $0?.id },
                            setter: { id -> (any MediaPlayerSupplement)? in
                                id.map { currentSupplements[id: $0]?.supplement } ?? nil
                            }
                        )
                    ) { supplement in
                        supplementContainer(for: supplement.supplement)
                            .eraseToAnyView()
                    }
                    #else
                    SupplementTabView(
                        items: Array(currentSupplements),
                        selection: containerState.selectedSupplement?.id
                    ) { supplement in
                        supplementContainer(for: supplement.supplement)
                            .eraseToAnyView()
                    }
                    #endif
                }
            }
        }

        var body: some View {
            ZStack {
                #if os(iOS)
                GestureView()
                    .environment(\.panGestureDirection, containerState.presentationControllerShouldDismiss ? .up : .vertical)
                #endif

                VStack(alignment: .leading, spacing: 0) {

                    // Exists to catch focus between supplement & controls.
                    // - The progress bar isn't visible while the supplements are up.
                    // - Focus is only needed from Supplement -> ProgressBar.
                    Color.clear
                        .frame(height: 1)
                        .backport
                        .focusable(containerState.isPresentingSupplement)
                        .focused($focusedElement, equals: .focusBoundary)

                    tabButtons

                    supplementContent
                        .isVisible(containerState.isPresentingSupplement)
                        .disabled(!containerState.isPresentingSupplement)
                        .animation(.linear(duration: 0.25), value: containerState.selectedSupplement?.id)
                }
                .isVisible(isPresentingOverlay && !isScrubbing)
                .padding(.top, EdgeInsets.edgeInsets.bottom / (UIDevice.isTV ? 2 : 1))
                .animation(.linear(duration: 0.25), value: isPresentingOverlay)
                .animation(.linear(duration: 0.1), value: isScrubbing)
                .animation(.bouncy(duration: 0.25, extraBounce: 0.1), value: currentSupplements)
            }
            .environment(\.isOverComplexContent, true)
            .onReceive(manager.$supplements) { newValue in
                let newSupplements = IdentifiedArray(
                    uniqueElements: newValue.map(AnyMediaPlayerSupplement.init)
                )
                currentSupplements = newSupplements
            }
            .backport
            .onChange(of: focusedElement) { _, newValue in
                switch newValue {
                case let .supplementTab(id):
                    if containerState.selectedSupplement?.id != id,
                       let supplement = currentSupplements[id: id]
                    {
                        containerState.select(supplement: supplement)
                    }
                    containerState.isPresentingOverlay = true
                case .focusBoundary:
                    containerState.select(supplement: nil)
                    containerState.isProgressBarFocused = true
                case .none:
                    break
                }
            }
            .backport
            .onChange(of: containerState.isProgressBarFocused) { _, focused in
                if focused, containerState.isPresentingSupplement {
                    containerState.select(supplement: nil)
                }
            }
            #if os(iOS)
            .environment(
                \.panAction,
                .init(
                    action: {
                        containerState.containerView?.handlePanGesture(
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
                        containerState.containerView?.handleTapGesture(
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
