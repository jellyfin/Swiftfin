//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay {

    struct DrawerOverlay: View {

        var body: some View {
            Text("")
        }
    }
}

struct CustomDrawerButton: View {

    @State
    private var isPressed: Bool = false

    let title: String
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Text(title)
            .fontWeight(.semibold)
            .foregroundStyle(isActive ? .black : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background {
                if isActive {
                    Rectangle()
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                if !isActive {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white, lineWidth: 4)
                }
            }
            .mask {
                RoundedRectangle(cornerRadius: 7)
            }
            .onTapGesture {
                onSelect()

                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onLongPressGesture(minimumDuration: 0.1) {} onPressingChanged: { isPressing in
                isPressed = isPressing
            }
            .scaleEffect(
                x: isPressed ? 0.9 : 1,
                y: isPressed ? 0.9 : 1,
                anchor: .init(x: 0.5, y: 0.5)
            )
            .animation(.bouncy(duration: 0.4), value: isActive)
            .animation(.bouncy(duration: 0.4), value: isPressed)
            .opacity(isPressed ? 0.6 : 1)
    }
}

struct DrawerSectionView: View {

    @Environment(\.isPresentingDrawer)
    @Binding
    private var isPresentingDrawer: Bool

    @Binding
    var selectedDrawerSection: Int

    var body: some View {
        HStack(spacing: 10) {
            CustomDrawerButton(
                title: "Info",
                isActive: selectedDrawerSection == 0
            ) {
                switch selectedDrawerSection {
                case -1:
                    selectedDrawerSection = 0
                    isPresentingDrawer = true
                case 0:
                    isPresentingDrawer = false
                default:
                    selectedDrawerSection = 0
                }
            }

            CustomDrawerButton(
                title: "Chapters",
                isActive: selectedDrawerSection == 1
            ) {
                switch selectedDrawerSection {
                case -1:
                    selectedDrawerSection = 1
                    isPresentingDrawer = true
                case 1:
                    isPresentingDrawer = false
                default:
                    selectedDrawerSection = 1
                }
            }

            CustomDrawerButton(
                title: "Up Next",
                isActive: selectedDrawerSection == 2
            ) {
                switch selectedDrawerSection {
                case -1:
                    selectedDrawerSection = 2
                    isPresentingDrawer = true
                case 2:
                    isPresentingDrawer = false
                default:
                    selectedDrawerSection = 2
                }
            }

            Spacer()
        }
        .onChange(of: isPresentingDrawer) { newValue in
            guard !newValue else { return }
            selectedDrawerSection = -1
        }
    }
}
