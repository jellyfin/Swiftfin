//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging
import SwiftUI

struct SkipSegmentButton: View {

    @ObservedObject
    private var observer: MediaSegmentObserver

    /// Whether the playback overlay is currently presented, which
    /// presents the button beyond its standalone presentation window.
    private let isPresentingOverlay: Bool

    init(
        observer: MediaSegmentObserver,
        isPresentingOverlay: Bool = true
    ) {
        self.observer = observer
        self.isPresentingOverlay = isPresentingOverlay
    }

    private var isPresented: Bool {
        observer.currentSegment != nil && (observer.isStandalonePresentation || isPresentingOverlay)
    }

    var body: some View {
        ZStack {
            if isPresented, let type = observer.currentSegment?.type {
                Button {
                    observer.skipCurrentSegment()
                } label: {
                    Label(type.skipActionTitle, systemImage: "forward.end.fill")
                }
                .buttonStyle(SkipSegmentButtonStyle())
                .transition(.opacity)
                .onAppear {
                    Logger.swiftfin().debug("[MediaSegments] skip button appeared")
                }
                .onDisappear {
                    Logger.swiftfin().debug("[MediaSegments] skip button disappeared")
                }
            }
        }
        .animation(.easeOut(duration: 0.4), value: isPresented)
    }
}

/// A plain white capsule that indicates focus by scale
/// instead of a platter, unlike built-in button styles.
private struct SkipSegmentButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration)
    }

    private struct StyleBody: View {

        @Environment(\.isFocused)
        private var isFocused

        let configuration: ButtonStyle.Configuration

        var body: some View {
            configuration.label
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(10)
                .padding(.horizontal, 5)
                .background(.white, in: Capsule())
            #if os(tvOS)
                .scaleEffect(isFocused ? 1.15 : 1)
                .shadow(radius: isFocused ? 5 : 0)
                .animation(.easeOut(duration: 0.15), value: isFocused)
            #endif
        }
    }
}
