//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension EpisodeHStack {

    struct ElementView<Content: View, Subtitle: View, MenuContent: View>: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEnabled)
        private var isEnabled

        private let action: () -> Void
        private let content: Content
        private let description: String
        private let menuContent: MenuContent
        private let subtitle: Subtitle
        private let title: String

        init(
            title: String,
            subtitle: Subtitle,
            description: String,
            action: @escaping () -> Void,
            @ViewBuilder content: () -> Content,
            @ViewBuilder menuContent: () -> MenuContent
        ) {
            self.action = action
            self.content = content()
            self.description = description
            self.menuContent = menuContent()
            self.subtitle = subtitle
            self.title = title
        }

        var body: some View {
            VStack(alignment: .leading) {
                content

                Button(action: action) {
                    VStack(alignment: .leading) {
                        subtitle
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(title)
                            .font(.callout)
                            .lineLimit(1)

                        Text(description)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3, reservesSpace: true)

                        Text(L10n.seeMore)
                            .fontWeight(.light)
                            .foregroundStyle(accentColor)
                            .hidden(!isEnabled)
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(.primary, .secondary)
                .buttonStyle(.card)
                #if os(iOS)
                    .overlay(alignment: .topTrailing) {
                        if MenuContent.self != EmptyView.self {
                            AlternateLayoutView(alignment: .trailing) {
                                Text(" ")
                            } content: { layoutSize in
                                Menu {
                                    menuContent
                                } label: {
                                    Label(L10n.options, systemImage: "ellipsis")
                                        .labelStyle(.iconOnly)
                                        .frame(width: layoutSize.height, height: layoutSize.height)
                                }
                                .contentShape(Rectangle())
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        }
                    }
                #endif
            }
        }
    }
}

extension EpisodeHStack.ElementView where Subtitle == Text {

    init(
        title: String,
        subtitle: String,
        description: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.action = action
        self.content = content()
        self.description = description
        self.menuContent = menuContent()
        self.subtitle = Text(subtitle)
        self.title = title
    }
}

extension EpisodeHStack.ElementView where Content == AnyView, Subtitle == Text, MenuContent == EmptyView {

    init(
        title: String,
        subtitle: String,
        description: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.action = action
        self.content = Rectangle()
            .fill(.complexSecondary)
            .posterStyle(.landscape)
            .overlay {
                if let systemImage {
                    RelativeSystemImageView(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
            }
            .eraseToAnyView()
        self.description = description
        self.menuContent = EmptyView()
        self.subtitle = Text(subtitle)
        self.title = title
    }
}
