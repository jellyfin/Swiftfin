//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension FocusedValues {

    @Entry
    var formLearnMore: AnyView? = nil
}

// MARK: - Form Overloads

func Form<Content: View>(
    systemImage: String,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    PlatformForm(content: content) {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form<Content: View>(
    image: ImageResource,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    PlatformForm(content: content) {
        Image(image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form<Image: View, Content: View>(
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder image: @escaping () -> Image
) -> some View {
    PlatformForm(content: content, image: image)
}

// MARK: - Platform Form

private struct PlatformForm<Image: View, Content: View>: View {

    #if os(tvOS)
    @FocusedValue(\.formLearnMore)
    private var focusedLearnMore
    #endif

    @ViewBuilder
    let content: Content
    @ViewBuilder
    let image: Image

    var body: some View {
        #if os(tvOS)
        HStack {
            descriptionView
                .frame(maxWidth: .infinity)

            SwiftUI.Form {
                content
            }
            .padding(.top)
            .scrollClipDisabled()
        }
        #else
        SwiftUI.Form {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    #if os(tvOS)
    @ViewBuilder
    private var descriptionView: some View {
        ZStack {
            if Image.self != EmptyView.self {
                image
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
    #endif
}
