//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct InputSheet<SheetContent: View, Buttons: View>: ViewModifier {

    @Binding
    private var isPresented: Bool

    private let title: String
    private let subtitle: String?
    private let sheetContent: () -> SheetContent
    private let buttons: () -> Buttons

    init(
        _ title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent,
        @ViewBuilder buttons: @escaping () -> Buttons
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isPresented = isPresented
        self.sheetContent = content
        self.buttons = buttons
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                GeometryReader { geometry in
                    let spacing = geometry.size.height * 0.04
                    let padding = geometry.size.width * 0.04

                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea(edges: .all)

                        VStack(spacing: 0) {
                            VStack(spacing: spacing) {
                                VStack(spacing: 8) {
                                    Text(title)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.primary)

                                    if let subtitle {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }

                                sheetContent()
                            }
                            .padding(padding)

                            buttons()
                                .padding(spacing)
                        }
                        .frame(width: geometry.size.width * 0.3)
                        .background {
                            RoundedRectangle(cornerRadius: 40)
                                .fill(.thickMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 40)
                                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}
