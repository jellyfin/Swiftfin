//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol PlatformForm: PlatformView {

    associatedtype content: View
    associatedtype context: View

    var imageView: FormImage? { get }

    @LabeledContentBuilder
    var contextView: context? { get }

    @ViewBuilder
    @MainActor
    var contentView: content { get }
}

extension PlatformForm {

    var imageView: FormImage? { nil }

    @MainActor
    var iOSView: some View {
        contentView
            .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    var tvOSView: some View {
        HStack {
            descriptionView
                .frame(maxWidth: .infinity)

            contentView
                .padding(.top)
            #if os(tvOS)
                .scrollClipDisabled()
            #endif
        }
    }

    private var descriptionView: some View {
        ZStack {
            if let imageView {
                imageView
            } else {
                EmptyView()
            }
            if contextView != nil {
                learnMoreModal
            }
        }
    }

    private var learnMoreModal: some View {
        VStack(alignment: .leading, spacing: 16) {
            contextView
                .labeledContentStyle(LearnMoreLabeledContentStyle())
                .foregroundStyle(Color.primary, Color.secondary)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.thick)
        }
        .padding()
    }
}

extension PlatformForm where context == EmptyView {
    var contextView: EmptyView? { nil }
}
