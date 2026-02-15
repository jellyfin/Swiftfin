//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension FocusedValues {

    @Entry
    var formLearnMore: AnyView? = nil
}

// MARK: - Form Overloads

func Form(
    systemImage: String,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    PlatformForm(content: content) {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form(
    image: ImageResource,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    PlatformForm(content: content) {
        Image(image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form(
    @ViewBuilder content: @escaping () -> some View,
    @ViewBuilder image: @escaping () -> some View
) -> some View {
    PlatformForm(content: content, image: image)
}

// MARK: - Platform Form

private struct PlatformForm<Image: View, Content: View>: PlatformView {

    @FocusedValue(\.formLearnMore)
    private var focusedLearnMore

    @FocusState
    private var isModalFocused: Bool

    @State
    private var learnMoreContent: AnyView?

    @State
    private var contentSize: CGSize = .zero
    @State
    private var layoutSize: CGSize = .zero

    private let content: Content
    private let image: Image

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder image: @escaping () -> Image
    ) {
        self.content = content()
        self.image = image()
    }

    var iOSView: some View {
        Form {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    var tvOSView: some View {
        HStack {
            descriptionView
                .frame(maxWidth: .infinity)

            Form {
                content
            }
            .padding(.top)
            .backport
            .scrollClipDisabled()
        }
        .onChange(of: focusedLearnMore != nil) {
            if let focusedLearnMore {
                learnMoreContent = focusedLearnMore
            } else if !isModalFocused {
                learnMoreContent = nil
            }
        }
        .onChange(of: isModalFocused) {
            if !isModalFocused && focusedLearnMore == nil {
                learnMoreContent = nil
            }
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        ZStack {
            image

            if let learnMoreContent {
                learnMoreModal(learnMoreContent)
            }
        }
        .focusSection()
        .animation(.linear(duration: 0.2), value: learnMoreContent == nil)
    }

    @ViewBuilder
    private func learnMoreModal(_ content: AnyView) -> some View {
        AlternateLayoutView {
            Color.clear
                .trackingSize($layoutSize)
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                        .labeledContentStyle(LearnMoreLabeledContentStyle())
                        .foregroundStyle(
                            isModalFocused ? Color.black : Color.white,
                            isModalFocused ? Color.black : Color.secondary
                        )
                }
                .edgePadding()
                .trackingSize($contentSize)
            }
            .scrollIndicators(.never)
            .focusSection()
            .focused($isModalFocused)
            .frame(maxHeight: contentSize.height >= layoutSize.height ? .infinity : contentSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Material.thick)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isModalFocused ? Color.white : .clear)
                    }
            }
            .padding()
            .scaleEffect(isModalFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isModalFocused)
        }
    }
}
