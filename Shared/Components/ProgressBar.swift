//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove and replace with below
struct ProgressBar: View {

    @State
    private var contentSize: CGSize = .zero

    let progress: CGFloat

    var body: some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                Capsule()
                    .mask(alignment: .leading) {
                        Rectangle()
                    }
                    .frame(width: contentSize.width * progress)
                    .foregroundStyle(.primary)
            }
            .trackingSize($contentSize)
    }
}

// TODO: fix capsule with low progress

extension ProgressViewStyle where Self == PlaybackProgressViewStyle {

    static var playback: Self { .init(secondaryProgress: nil) }

    static func playback(secondaryProgress: Double?) -> Self {
        .init(secondaryProgress: secondaryProgress)
    }
}

struct PlaybackProgressViewStyle: ProgressViewStyle {

    @State
    private var contentSize: CGSize = .zero

    let secondaryProgress: Double?

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {

                    if let secondaryProgress {
                        Capsule()
                            .mask(alignment: .leading) {
                                Rectangle()
                            }
                            .frame(width: contentSize.width * clamp(secondaryProgress, min: 0, max: 1))
                            .foregroundStyle(.tertiary)
                    }

                    Capsule()
                        .mask(alignment: .leading) {
                            Rectangle()
                        }
                        .frame(width: contentSize.width * (configuration.fractionCompleted ?? 0))
                        .foregroundStyle(.primary)
                }
            }
            .trackingSize($contentSize)
    }
}

// #Preview {
//    ProgressView(value: 0.3)
//        .progressViewStyle(.SwiftfinLinear(secondaryProgress: 0.3))
//        .frame(height: 8)
//        .padding(.horizontal, 10)
//        .foregroundStyle(.primary, .secondary, .orange)
// }
