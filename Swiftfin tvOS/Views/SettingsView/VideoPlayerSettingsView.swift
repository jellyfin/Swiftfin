//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct VideoPlayerSettingsView: View {

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Default(.VideoPlayer.enableMediaSegments)
    private var enableMediaSegments

    @Default(.VideoPlayer.skipMediaSegments)
    private var skipMediaSegments
    @Default(.VideoPlayer.askMediaSegments)
    private var askMediaSegments

    @Router
    private var router

    @State
    private var isPresentingResumeOffsetStepper: Bool = false

    // TODO: Update with correct settings once the tvOS PlayerUI is complete
    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "tv")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    ChevronButton(
                        L10n.offset,
                        subtitle: resumeOffset.secondLabel
                    ) {
                        isPresentingResumeOffsetStepper = true
                    }
                } header: {
                    Text(L10n.resume)
                } footer: {
                    Text(L10n.resumeOffsetDescription)
                }

                Section {

                    ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName) {
                        router.route(to: .fontPicker(selection: $subtitleFontName))
                    }
                } header: {
                    Text(L10n.subtitles)
                } footer: {
                    Text(L10n.subtitlesDisclaimer)
                }

                Section(L10n.mediaSegments) {
                    Toggle(L10n.enableMediaSegments, isOn: $enableMediaSegments)
                }

                if enableMediaSegments {
                    Section {
                        ForEach(MediaSegmentType.allCases.sorted(by: { $0.displayTitle < $1.displayTitle }), id: \.self) { segment in
                            ListRowMenu(segment.displayTitle, selection: mediaSegmentBinding(segment))
                        }
                    }
                }
            }
            .navigationTitle(L10n.videoPlayer)
            .blurredFullScreenCover(isPresented: $isPresentingResumeOffsetStepper) {
                StepperView(
                    title: L10n.resumeOffsetTitle,
                    description: L10n.resumeOffsetDescription,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondLabel
                }
                .onCloseSelected {
                    isPresentingResumeOffsetStepper = false
                }
            }
    }

    private func mediaSegmentBinding(_ segment: MediaSegmentType) -> Binding<MediaSegmentBehavior> {
        Binding(
            get: {
                if askMediaSegments.contains(segment) {
                    return .ask
                } else if skipMediaSegments.contains(segment) {
                    return .skip
                } else {
                    return .off
                }
            },
            set: { newValue in
                switch newValue {
                case .off:
                    askMediaSegments.removeAll { $0 == segment }
                    skipMediaSegments.removeAll { $0 == segment }
                case .ask:
                    askMediaSegments.append(segment)
                    skipMediaSegments.removeAll { $0 == segment }
                case .skip:
                    askMediaSegments.removeAll { $0 == segment }
                    skipMediaSegments.append(segment)
                }
            }
        )
    }
}
