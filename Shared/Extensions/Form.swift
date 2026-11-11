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

@ContentBuilder
func Form(
    systemImage: String,
    @ContentBuilder content: @escaping () -> some View
) -> some View {
    PlatformForm(content: content) {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

@ContentBuilder
func Form(
    image: ImageResource,
    @ContentBuilder content: @escaping () -> some View
) -> some View {
    PlatformForm(content: content) {
        Image(image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

@ContentBuilder
func Form(
    @ContentBuilder content: @escaping () -> some View,
    @ContentBuilder image: @escaping () -> some View
) -> some View {
    PlatformForm(content: content, image: image)
}

private struct PrimaryToggleStyle: ToggleStyle {

    @ContentBuilder
    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
                .foregroundStyle(Color.primary)
        }
    }
}

// MARK: - Platform Form

private struct PlatformForm<Image: View, Content: View>: PresentationView {

    @FocusedValue(\.formLearnMore)
    private var focusedLearnMore

    private let content: Content
    private let image: Image

    init(
        @ContentBuilder content: @escaping () -> Content,
        @ContentBuilder image: @escaping () -> Image
    ) {
        self.content = content()
        self.image = image()
    }

    @ContentBuilder
    var standardView: some View {
        Form {
            content
        }
        .toolbarTitleDisplayMode(.inline)
    }

    @ContentBuilder
    var largeView: some View {
        HStack {
            descriptionView
                .frame(maxWidth: .infinity)

            Form {
                content
            }
            .scrollClipDisabled()
            .toggleStyle(PrimaryToggleStyle())
            .mask(extendedBy: .init(vertical: 20, horizontal: 100)) {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)

                    Color.white

                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
            }
        }
    }

    @ContentBuilder
    private var descriptionView: some View {
        ZStack {
            image

            if let focusedLearnMore {
                learnMoreModal(focusedLearnMore)
            }
        }
        .animation(.linear(duration: 0.2), value: focusedLearnMore == nil)
    }

    @ContentBuilder
    private func learnMoreModal(_ content: AnyView) -> some View {
        Marquee(axis: .vertical, resetType: .bounce, speed: 30, fade: 20) {
            VStack(alignment: .leading, spacing: 16) {
                content
                    .labeledContentStyle(LearnMoreLabeledContentStyle())
                    .foregroundStyle(Color.primary, Color.secondary)
            }
            .edgePadding()
        }
        .background {
            ContainerRelativeShape()
                .fill(Material.thick)
        }
        .overlay(
            ContainerRelativeShape()
                .stroke(
                    .white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .containerShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
