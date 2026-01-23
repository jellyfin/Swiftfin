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

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        @FocusState
        private var focusedSupplementID: AnyMediaPlayerSupplement.ID?

        // MARK: - Convenience Variables

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        // MARK: - Supplement Container

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
            }
            .background {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)
            }
        }

        // MARK: - Body

        var body: some View {
            VStack(spacing: 0) {
                // TODO: scroll if larger than horizontal
                HStack(spacing: 10) {
                    if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                        Button(supplement.displayTitle) {
                            containerState.select(supplement: nil)
                        }
                        .isSelected(true)
                        .focused($focusedSupplementID, equals: supplement.id)
                    } else {
                        ForEach(currentSupplements) { supplement in
                            let isSelected = containerState.selectedSupplement?.id == supplement.id

                            Button(supplement.displayTitle) {
                                containerState.selectedSupplement = supplement.supplement
                                containerState.containerView?.presentSupplementContainer(true)
                            }
                            .isSelected(isSelected)
                            .focused($focusedSupplementID, equals: supplement.id)
                        }
                    }
                }
                .buttonStyle(SupplementTitleButtonStyle())
                .padding(.leading, safeAreaInsets.leading)
                .padding(.trailing, safeAreaInsets.trailing)
                .edgePadding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSection()
                .isVisible(isPresentingOverlay)

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
                .isVisible(containerState.isPresentingSupplement)
                .disabled(!containerState.isPresentingSupplement)
                .animation(.linear(duration: 0.2), value: containerState.selectedSupplement?.id)
            }
            .edgePadding(.top)
            .isVisible(isPresentingOverlay)
            .isVisible(!isScrubbing)
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
            .onChange(of: isPresentingSupplement) { _, newValue in
                if newValue {
                    focusedSupplementID = containerState.selectedSupplement?.id
                }
            }
            .onChange(of: focusedSupplementID) { oldValue, newValue in
                if let supplementID = newValue, oldValue != newValue {
                    if let supplement = currentSupplements[id: supplementID] {
                        containerState.selectedSupplement = supplement.supplement

                        if !isPresentingSupplement {
                            containerState.containerView?.presentSupplementContainer(true)
                        }
                    }
                } else if newValue == nil, oldValue != nil {
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false)
                }
            }
        }
    }

    struct SupplementTitleButtonStyle: PrimitiveButtonStyle {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @FocusState
        private var isFocused

        @State
        private var isPressed: Bool = false

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(isFocused ? .black : .white)
                .padding(10)
                .padding(.horizontal, 10)
                .background {
                    if isFocused {
                        Rectangle()
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    if !isFocused {
                        RoundedRectangle(cornerRadius: 27)
                            .stroke(Color.white, lineWidth: 4)
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: 27)
                }
                .scaleEffect(
                    x: isFocused ? 1.1 : 1,
                    y: isFocused ? 1.1 : 1,
                    anchor: .init(x: 0.5, y: 0.5)
                )
                .animation(.bouncy(duration: 0.4), value: isFocused)
                .opacity(isPressed ? 0.6 : 1)
                .animation(.linear(duration: 0.05), value: isFocused)
                .focusable()
                .focused($isFocused)
                .onTapGesture {
                    // TODO: Remove in favor of just focusing IMO?
                    configuration.trigger()
                }
        }
    }
}
