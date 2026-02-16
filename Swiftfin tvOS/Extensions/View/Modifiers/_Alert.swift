//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI

// TODO: tvOS 26: `.background(ultraThinMaterial)` to `.glassEffect`

extension View {

    func _alert(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(
            _Alert(
                title: title,
                isPresented: isPresented,
                content: content,
                message: { EmptyView() }
            )
        )
    }

    func _alert(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View,
        @ViewBuilder message: @escaping () -> some View
    ) -> some View {
        modifier(
            _Alert(
                title: title,
                isPresented: isPresented,
                content: content,
                message: message
            )
        )
    }
}

struct _Alert<_Content: View, Message: View>: ViewModifier {

    private let _content: _Content
    private let isPresented: Binding<Bool>
    private let message: Message
    private let title: String

    init(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> _Content,
        @ViewBuilder message: () -> Message,
    ) {
        self._content = content()
        self.isPresented = isPresented
        self.message = message()
        self.title = title
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: isPresented) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack {
                        Text(title)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        message
                            .font(.caption)
                            .lineSpacing(3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)

                        _content
                    }
                    .padding(.horizontal, 54)
                    .padding(.vertical, 46)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 28, y: 16)
                    .padding(.horizontal, 180)
                }
            }
    }
}
