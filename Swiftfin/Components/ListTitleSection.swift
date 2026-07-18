//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: image
// TODO: rename

struct ListTitleSection: View {

    private let description: Text?
    private let learnMoreAction: (() -> Void)?
    private let title: Text

    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 10) {

                title
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                if let description {
                    description
                        .multilineTextAlignment(.center)
                }

                if let learnMoreAction {
                    Button(
                        L10n.learnMore + .ellipsis,
                        action: learnMoreAction
                    )
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
    }
}

extension ListTitleSection {

    init(
        _ title: some WithText,
        description: (some WithText)? = nil
    ) {
        self.init(
            description: description?.textBody,
            learnMoreAction: nil,
            title: title.textBody
        )
    }

    init(
        _ title: some WithText,
        description: (some WithText)? = nil,
        learnMoreAction: @escaping () -> Void
    ) {
        self.init(
            description: description?.textBody,
            learnMoreAction: learnMoreAction,
            title: title.textBody
        )
    }
}

/// A view that mimics an inset grouped section, meant to be
/// used as a header for a `List` with `listStyle(.plain)`.
struct InsetGroupedListHeader<Content: View>: View {

    @Default(.accentColor)
    private var accentColor

    private let content: Content
    private let description: Text?
    private let learnMoreAction: (() -> Void)?
    private let title: Text?

    @ViewBuilder
    private var header: some View {
        Button {
            learnMoreAction?()
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

                if learnMoreAction != nil {
                    Text(L10n.learnMore + .ellipsis)
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

                content
                    .listRowSeparator(.hidden)
                    .padding(.init(vertical: 5, horizontal: 20))
                    .listRowInsets(.init(vertical: 10, horizontal: 20))
            }
        }
    }
}

extension InsetGroupedListHeader {

    init(
        _ title: some WithText,
        description: (some WithText)? = nil,
        learnMoreAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content(),
            description: description?.textBody,
            learnMoreAction: learnMoreAction,
            title: title.textBody
        )
    }
}

extension InsetGroupedListHeader where Content == EmptyView {

    init(
        _ title: some WithText,
        description: (some WithText)? = nil,
        learnMoreAction: (() -> Void)? = nil
    ) {
        self.init(
            content: EmptyView(),
            description: description?.textBody,
            learnMoreAction: learnMoreAction,
            title: title.textBody
        )
    }
}
