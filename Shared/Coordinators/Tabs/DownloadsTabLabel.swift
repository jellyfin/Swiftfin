//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

/// Animated downloads tab label for TabView
/// Displays an animated pulse effect when downloads are active (.ready or .downloading)
/// Uses basic SwiftUI scaleEffect animation that is compatible with TabView constraints
struct DownloadsTabLabel: View {

    @StateObject
    private var downloadManager = Container.shared.downloadManager()

    @State
    private var pulseScale: CGFloat = 1.0

    private var hasActiveDownloads: Bool {
        downloadManager.downloads.contains { task in
            switch task.state {
            case .ready, .downloading:
                return true
            default:
                return false
            }
        }
    }

    private var downloadIcon: String {
        hasActiveDownloads ? "arrow.down.circle.fill" : "arrow.down.circle"
    }

    var body: some View {
        Label(L10n.downloads, systemImage: downloadIcon)
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.monochrome)
            .scaleEffect(hasActiveDownloads ? pulseScale : 1.0)
            .onAppear {
                if hasActiveDownloads {
                    startPulseAnimation()
                }
            }
            .onChange(of: hasActiveDownloads) { newValue in
                if newValue {
                    startPulseAnimation()
                } else {
                    stopPulseAnimation()
                }
            }
    }

    // MARK: - Private Methods

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
        }
    }

    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
        }
    }
}
