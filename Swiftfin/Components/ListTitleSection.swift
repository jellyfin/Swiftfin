//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: image
// TODO: rename

struct ListTitleSection: View {

    private let title: String
    private let description: String?
    private let onLearnMore: (() -> Void)?

    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 10) {

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                if let description {
                    Text(description)
                        .multilineTextAlignment(.center)
                }

                if let onLearnMore {
                    Button("Learn More\u{2026}", action: onLearnMore)
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
    }
}

extension ListTitleSection {

    init(
        _ title: String,
        description: String? = nil
    ) {
        self.init(
            title: title,
            description: description,
            onLearnMore: nil
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        onLearnMore: @escaping () -> Void
    ) {
        self.init(
            title: title,
            description: description,
            onLearnMore: onLearnMore
        )
    }
}

/// A view that mimics an inset grouped section, meant to be
/// used as a header for a `List` with `listStyle(.plain)`.
struct InsetGroupedListHeader<Content: View>: View {

    @Default(.accentColor)
    private var accentColor

    private let content: () -> Content
    private let title: Text?
    private let description: Text?
    private let onLearnMore: (() -> Void)?

    @ViewBuilder
    private var header: some View {
        Button {
            onLearnMore?()
        } label: {
            VStack(alignment: .center, spacing: 10) {

                if let title {
                    title
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let description {
                    description
                        .multilineTextAlignment(.center)
                }

                if onLearnMore != nil {
                    Text("Learn More\u{2026}")
                        .foregroundStyle(accentColor)
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .foregroundStyle(.primary, .secondary)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondarySystemBackground)

            SeparatorVStack {
                RowDivider()
            } content: {
                if title != nil || description != nil {
                    header
                }

                content()
                    .listRowSeparator(.hidden)
                    .padding(.init(vertical: 5, horizontal: 20))
                    .listRowInsets(.init(vertical: 10, horizontal: 20))
            }
        }
    }
}

extension InsetGroupedListHeader {

    init(
        _ title: String? = nil,
        description: String? = nil,
        onLearnMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content,
            title: title == nil ? nil : Text(title!),
            description: description == nil ? nil : Text(description!),
            onLearnMore: onLearnMore
        )
    }

    init(
        title: Text,
        description: Text? = nil,
        onLearnMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content,
            title: title,
            description: description,
            onLearnMore: onLearnMore
        )
    }
}

extension InsetGroupedListHeader where Content == EmptyView {

    init(
        _ title: String,
        description: String? = nil,
        onLearnMore: (() -> Void)? = nil
    ) {
        self.init(
            content: { EmptyView() },
            title: Text(title),
            description: description == nil ? nil : Text(description!),
            onLearnMore: onLearnMore
        )
    }

    init(
        title: Text,
        description: Text? = nil,
        onLearnMore: (() -> Void)? = nil
    ) {
        self.init(
            content: { EmptyView() },
            title: title,
            description: description,
            onLearnMore: onLearnMore
        )
    }
}
