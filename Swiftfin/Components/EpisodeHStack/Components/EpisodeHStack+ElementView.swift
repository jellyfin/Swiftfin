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

    struct ElementView<Content: View>: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEnabled)
        private var isEnabled

        private let content: Content
        private let title: String
        private let subtitle: String
        private let description: String
        private let action: () -> Void

        init(
            title: String,
            subtitle: String,
            description: String,
            action: @escaping () -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.subtitle = subtitle
            self.description = description
            self.action = action
            self.content = content()
        }

        @ViewBuilder
        private var subtitleView: some View {
            Text(subtitle)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        @ViewBuilder
        private var titleView: some View {
            Text(title)
                .font(.callout)
                .lineLimit(1)
        }

        @ViewBuilder
        private var descriptionView: some View {
            Text(description)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3, reservesSpace: true)
        }

        var body: some View {
            VStack(alignment: .leading) {
                content

                Button(action: action) {
                    VStack(alignment: .leading) {
                        subtitleView

                        titleView

                        descriptionView

                        Text(L10n.seeMore)
                            .fontWeight(.light)
                            .foregroundStyle(accentColor)
                            .hidden(!isEnabled)
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(.primary, .secondary)
            }
        }
    }
}

extension EpisodeHStack.ElementView where Content == AnyView {

    init(
        title: String,
        subtitle: String,
        description: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            description: description,
            action: action,
            content: {
                Rectangle()
                    .fill(.complexSecondary)
                    .posterStyle(.landscape)
                    .overlay {
                        if let systemImage {
                            RelativeSystemImageView(systemName: systemImage)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .eraseToAnyView()
            }
        )
    }
}
