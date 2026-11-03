//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import MediaAccessibilityKit
import MPVUI
import SwiftUI

struct TextSubtitleReporting: ViewModifier {

    // Class to prevent view evaluations
    @MainActor
    private final class CaptionReportState {

        var isPresented = false
        var lastCaptions: [String]?
    }

    @State
    private var report = CaptionReportState()

    let snapshot: TextSubtitleSnapshot?
    let isVisible: Bool
    var reportCaptions: (@MainActor ([String]) -> Void)? = reportToSystem

    static func reportToSystem(_ captions: [String]) {
        if captions.isEmpty {
            CaptionDisplayReporter.clear()
        } else {
            CaptionDisplayReporter.report(captions)
        }
    }

    private var captionTexts: [String] {
        // Secondary captions appear above primary captions. Preserve reading order.
        let (other, secondary) = (snapshot?.regions ?? [])
            .partitioned { $0.role == .secondary }

        return (secondary + other)
            .map(\.text)
            .compacted(using: \.nilIfBlank)
    }

    private func reportVisibleCaptions() {
        guard let reportCaptions else { return }

        let captions = report.isPresented && isVisible ? captionTexts : []
        guard captions != report.lastCaptions else { return }

        reportCaptions(captions)
        report.lastCaptions = captions
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                report.isPresented = true
                reportVisibleCaptions()
            }
            .onChange(of: captionTexts) {
                reportVisibleCaptions()
            }
            .onChange(of: isVisible) {
                reportVisibleCaptions()
            }
            .onDisappear {
                report.isPresented = false
                reportVisibleCaptions()
            }
    }
}
