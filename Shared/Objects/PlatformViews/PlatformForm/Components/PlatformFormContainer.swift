//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PlatformFormContainer<Content: View>: View {

    @FocusedValue(\.formLearnMore)
    private var focusedLearnMore

    let imageView: FormImage?
    let content: Content

    var body: some View {
        HStack {
            descriptionView
                .frame(maxWidth: .infinity)

            content
                .padding(.top)
            #if os(tvOS)
                .scrollClipDisabled()
            #endif
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        ZStack {
            if let imageView {
                imageView
            }

            if let focusedLearnMore {
                learnMoreModal(focusedLearnMore)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: focusedLearnMore == nil)
    }

    private func learnMoreModal(_ content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content
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
