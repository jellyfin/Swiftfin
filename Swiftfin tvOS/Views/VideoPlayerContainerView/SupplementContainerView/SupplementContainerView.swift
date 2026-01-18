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
        private var focusGuide: FocusGuide
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        @FocusState
        private var focusedSupplementID: AnyMediaPlayerSupplement.ID?

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
            }
        }

        var body: some View {
            VStack(spacing: EdgeInsets.edgePadding) {

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
                                containerState.select(supplement: supplement.supplement)
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
                .focusGuide(
                    focusGuide,
                    tag: "supplementButtons",
                    top: "playbackProgress"
                )
                .focusSection()

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
            .onReceive(containerState.$selectedSupplement) { output in
                if focusedSupplementID != output?.id {
                    focusedSupplementID = output?.id
                }
            }
        }
    }

    struct SupplementTitleButtonStyle: PrimitiveButtonStyle {

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
                .onChange(of: isFocused) { _, newValue in
                    if newValue {
                        configuration.trigger()
                    }
                }
        }
    }
}
