//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ContentUnavailableView {
    static var content: ContentUnavailableView {
        ContentUnavailableView(L10n.noContent.localizedCapitalized, systemImage: "questionmark.circle")
    }
}

// TODO: Remove for iOS 17
struct ContentUnavailableView: View {

    private let title: String
    private let systemImage: String
    private let isSearch: Bool

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
        self.isSearch = false
    }

    private init(search: Void) {
        self.title = L10n.noResults
        self.systemImage = "magnifyingglass"
        self.isSearch = true
    }

    static var search: ContentUnavailableView {
        ContentUnavailableView(search: ())
    }

    var body: some View {
        if #available(iOS 17, tvOS 17, *) {
            if isSearch {
                SwiftUI.ContentUnavailableView.search
            } else {
                SwiftUI.ContentUnavailableView {
                    Label(title, systemImage: systemImage)
                }
            }
        } else {
            _ContentUnavailableView(
                title: title,
                systemImage: systemImage
            )
        }
    }
}

// TODO: Remove for iOS 17
/// This is a fallback view for iOS 16 and below
private struct _ContentUnavailableView: View {

    let title: String
    let systemImage: String

    #if os(iOS)
    private let iconSize: CGFloat = 48
    #else
    private let iconSize: CGFloat = 96
    #endif

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 600, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .focusSection()
        .edgePadding()
    }
}
