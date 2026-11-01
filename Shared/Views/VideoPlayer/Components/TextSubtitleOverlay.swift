//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import MediaAccessibilityKit
import MPVUI
import SwiftUI

struct TextSubtitleOverlay: View {

    @Environment(\.scenePhase)
    private var scenePhase

    let snapshot: TextSubtitleSnapshot
    let videoLayout: VideoPlayer.VideoLayout
    var reportCaptions: (@MainActor ([String]) -> Void)? = TextSubtitleReporting.reportToSystem

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
    
    @Default(.VideoPlayer.Subtitle.captionProfileID)
    private var profileID

    @Environment(\.scenePhase)
    private var scenePhase
    
    @AdaptiveLayout
    private var viewLayout

    @State
    private var captionStyle = CaptionStyle.current
    @State
    private var profiles = CaptionProfile.availableForCurrentPlatform
    
    let snapshot: TextSubtitleSnapshot
    let videoLayout: VideoPlayer.VideoLayout

    private var basePointSize: CGFloat {
        viewLayout.value(standard: 21, large: 36)
    }

    private var selectedCaptionStyle: CaptionStyle {
        profiles.first(property: \.id, equalTo: profileID)?.style ?? captionStyle
    }

    var body: some View {
        let style = selectedCaptionStyle
        let pointSize = basePointSize * style.text.sizeScale.resolved(contentValue: nil)

        MPVTextSubtitleOverlay(
            snapshot: snapshot,
            videoFrame: videoLayout.videoFrame(in:),
            placementPolicy: .primaryAuthored,
            automaticPlacement: .container,
            spacing: pointSize * 0.25
        ) { region in
            CaptionText(region.text, baseSize: basePointSize, style: style)
                .lineSpacing(pointSize * 0.12)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            for await _ in CaptionPreferences.updates {
                captionStyle = .current
                profiles = CaptionProfile.availableForCurrentPlatform
            }
        }
    }
}
