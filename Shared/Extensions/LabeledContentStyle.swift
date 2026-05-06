//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension LabeledContentStyle where Self == LearnMoreLabeledContentStyle {

    static var learnMore: LearnMoreLabeledContentStyle {
        LearnMoreLabeledContentStyle()
    }
}

struct LearnMoreLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

extension LabeledContentStyle where Self == ItemAttributeLabeledContentStyle {

    static var itemAttribute: ItemAttributeLabeledContentStyle {
        ItemAttributeLabeledContentStyle()
    }
}

struct ItemAttributeLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

extension LabeledContentStyle where Self == DeviceProfileLabeledContentStyle {

    static var deviceProfile: DeviceProfileLabeledContentStyle {
        DeviceProfileLabeledContentStyle()
    }
}

struct DeviceProfileLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            configuration.content
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .font(.subheadline)
    }
}

extension LabeledContentStyle where Self == PlaybackInfoLabeledContentStyle {

    static var playbackInfo: PlaybackInfoLabeledContentStyle {
        PlaybackInfoLabeledContentStyle()
    }
}

struct PlaybackInfoLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            configuration.label
                .foregroundStyle(.secondary)

            // swiftlint:disable:next hard_coded_display_string
            Text(":")
                .foregroundStyle(.secondary)
                .padding(.trailing, 4)

            Spacer()

            configuration.content
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}

extension LabeledContentStyle where Self == FocusableLabeledContentStyle {

    static var focusable: FocusableLabeledContentStyle {
        FocusableLabeledContentStyle()
    }
}

struct FocusableLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        Button {} label: {
            LabeledContent {
                configuration.content
            } label: {
                configuration.label
            }
        }
        #else
        LabeledContent {
            configuration.content
        } label: {
            configuration.label
        }
        #endif
    }
}
