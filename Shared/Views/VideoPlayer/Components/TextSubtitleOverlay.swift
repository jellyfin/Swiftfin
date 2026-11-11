//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import MediaAccessibilityKit
import MPVUI
import SwiftUI

// TODO: Look at adjusting size based on available size (PiP, portrait)

struct TextSubtitleOverlay: View {

    @Environment(\.scenePhase)
    private var scenePhase

    let snapshot: TextSubtitleSnapshot
    let videoLayout: VideoPlayer.VideoLayout
    var reportCaptions: (@MainActor ([String]) -> Void)? = TextSubtitleReporting.reportToSystem

    @ContentBuilder
    var body: some View {
        TextSubtitleOverlayContent(snapshot: snapshot, videoLayout: videoLayout)
            .modifier(
                TextSubtitleReporting(
                    snapshot: snapshot,
                    isVisible: scenePhase == .active,
                    reportCaptions: reportCaptions
                )
            )
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(snapshot.text)
            .accessibilityHidden(snapshot.isEmpty)
    }
}

private struct TextSubtitleOverlayContent: View {

    @AdaptiveLayout
    private var viewLayout

    @State
    private var captionStyle = Self.currentSystemStyle

    let snapshot: TextSubtitleSnapshot
    let videoLayout: VideoPlayer.VideoLayout

    private var basePointSize: CGFloat {
        viewLayout.value(standard: 21, large: 36)
    }

    private static var currentSystemStyle: CaptionStyle {
        if #available(iOS 26, tvOS 26, *), let profile = CaptionProfile.active {
            return profile.style
        }

        return .current
    }

    private func refreshCaptionStyle() {
        captionStyle = Self.currentSystemStyle
    }

    @ContentBuilder
    var body: some View {
        let pointSize = basePointSize * captionStyle.text.sizeScale.resolved(contentValue: nil)

        MPVTextSubtitleOverlay(
            snapshot: snapshot,
            videoFrame: videoLayout.videoFrame(in:),
            placementPolicy: .primaryAuthored,
            automaticPlacement: .container,
            spacing: pointSize * 0.25
        ) { region in
            CaptionText(
                region.text,
                baseSize: basePointSize,
                style: captionStyle
            )
            .lineSpacing(pointSize * 0.12)
        }
        .task {
            for await _ in CaptionPreferences.updates {
                refreshCaptionStyle()
            }
        }
        .onNotification(.applicationDidBecomeActive, perform: refreshCaptionStyle)
    }
}
