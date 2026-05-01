//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import SwiftUI

// TODO: possibly make custom tab view to have observe
//       vertical scroll content and transfer to dismissal
// TODO: fix improper supplement selected
//       - maybe a race issue

extension VideoPlayer.UIVideoPlayerContainerViewController {

    struct SupplementContainerView: View {

        enum SupplementElement: Hashable {
            case focusBoundary
            case supplementTab(AnyMediaPlayerSupplement.ID)
            case supplementContents(AnyMediaPlayerSupplement.ID)
        }

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        #if os(tvOS)
        @Environment(\.resetFocus)
        private var resetFocus
        #endif

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @Namespace
        private var videoPlayer

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

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
            }
            #if os(tvOS)
            .edgePadding(.horizontal)
            #endif
            .background {
                #if os(iOS)
                GestureView()
                    .environment(\.panGestureDirection, .vertical)
                #endif
            }
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
                    } else {
                        ForEach(currentSupplements) { supplement in
                            let isSelected = containerState.selectedSupplement?.id == supplement.id

                            Button(supplement.displayTitle) {
                                containerState.select(supplement: supplement.supplement)
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
            #if os(tvOS)
                .defaultFocus($focusedElement, defaultTabFocus)
            #endif
                .if(!UIDevice.isTV) { view in
                    view
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                }
                .buttonStyle(SupplementTitleButtonStyle())
        }

        @ViewBuilder
        private var supplementContent: some View {
            ZStack {
                if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                    supplementContainer(for: supplement)
                        .eraseToAnyView()
                } else {
                    TabView(
                        selection: $containerState.selectedSupplement.map(
                            getter: { $0?.id },
                            setter: { id -> (any MediaPlayerSupplement)? in
                                id.map { currentSupplements[id: $0]?.supplement } ?? nil
                            }
                        )
                    ) {
                        ForEach(currentSupplements) { supplement in
                            supplementContainer(for: supplement.supplement)
                                .eraseToAnyView()
                                .tag(supplement.id as String?)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
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

                    #if os(tvOS)
                    Color.clear
                        .frame(height: 1)
                        .focusable(true)
                        .focused($focusedElement, equals: .focusBoundary)
                        .fixedSize(horizontal: false, vertical: true)
                    #endif

                    tabButtons

                    supplementContent
                        .padding(.top, EdgeInsets.edgePadding)
                        .scrollClipDisabled()
                        .isVisible(containerState.isPresentingSupplement)
                        .disabled(!containerState.isPresentingSupplement)
                        .animation(.linear(duration: 0.2), value: containerState.selectedSupplement?.id)
                }
                .isVisible(isPresentingOverlay && !isScrubbing)
                .padding(.top, EdgeInsets.edgeInsets.bottom / (UIDevice.isTV ? 2 : 1))
            }
            .animation(.linear(duration: 0.2), value: isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.1), value: currentSupplements)
            .environment(\.isOverComplexContent, true)
            .onReceive(manager.$supplements) { newValue in
                let newSupplements = IdentifiedArray(
                    uniqueElements: newValue.map(AnyMediaPlayerSupplement.init)
                )
                currentSupplements = newSupplements
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
            #else
            .onReceive(manager.$playbackItem) { newItem in
                    guard newItem != nil else { return }
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false)
                    resetFocus(in: videoPlayer)
                }
                .onChange(of: focusedElement) { _, newValue in
                    switch newValue {
                    case let .supplementTab(id):
                        if containerState.selectedSupplement?.id != id,
                           let supplement = currentSupplements[id: id]?.supplement
                        {
                            containerState.select(supplement: supplement)
                        }
                        containerState.isPresentingOverlay = true
                    case .focusBoundary:
                        if containerState.isPresentingSupplement {
                            // Came from a supplement tab going up → close + focus progress bar
                            containerState.select(supplement: nil)
                            containerState.isProgressBarFocused = true
                        } else {
                            // Came from progress bar going down → open + focus first tab
                            if let first = currentSupplements.first {
                                containerState.select(supplement: first.supplement)
                                DispatchQueue.main.async {
                                    focusedElement = .supplementTab(first.id)
                                }
                            }
                        }
                    case .supplementContents, .none:
                        break
                    }
                }
                .onChange(of: containerState.isProgressBarFocused) { _, focused in
                    if focused, containerState.isPresentingSupplement {
                        containerState.select(supplement: nil)
                    }
                }
            #endif
        }
    }
}
