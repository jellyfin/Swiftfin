//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

extension ProgressViewStyle where Self == PlaybackProgressViewStyle {

    static var playback: Self { .init(secondaryProgress: nil, cornerStyle: .round) }

    func secondaryProgress(_ progress: Double?) -> Self {
        copy(self, modifying: \.secondaryProgress, to: progress)
    }

    var square: Self {
        copy(self, modifying: \.cornerStyle, to: .square)
    }
}

struct PlaybackProgressViewStyle: ProgressViewStyle {

    enum CornerStyle {
        case round
        case square
    }

    @State
    private var contentSize: CGSize = .zero

    var secondaryProgress: Double?
    var cornerStyle: CornerStyle

    @ViewBuilder
    private func buildCapsule(for progress: Double) -> some View {
        Rectangle()
            .cornerRadius(
                cornerStyle == .round ? contentSize.height / 2 : 0,
                corners: [.topLeft, .bottomLeft]
            )
            .frame(width: contentSize.width * clamp(progress, min: 0, max: 1) + contentSize.height)
            .offset(x: -contentSize.height)
    }

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {

                    if let secondaryProgress,
                       secondaryProgress > 0
                    {
                        buildCapsule(for: secondaryProgress)
                            .foregroundStyle(.tertiary)
                    }

                    if let fractionCompleted = configuration.fractionCompleted {
                        buildCapsule(for: fractionCompleted)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .trackingSize($contentSize)
            .mask {
                Capsule()
            }
    }
}

// struct Test: View {
//
//    @State
//    private var p: Double = 0.1
//    @State
//    private var s: Double = 0.2
//
//    var body: some View {
//        VStack {
//            ProgressView(value: p)
//                .progressViewStyle(.playback.secondaryProgress(s).square)
//                .frame(height: 200)
//                .padding(.horizontal, 10)
//                .foregroundStyle(.primary, .secondary, .orange)
//
//            ProgressView(value: p)
//                .progressViewStyle(.playback.secondaryProgress(s).square)
//                .frame(height: 15)
//                .foregroundStyle(.primary, .secondary, .orange)
//                .padding(.horizontal, 10)
//
//            SwiftUI.Slider(value: $p, in: 0 ... 1)
//            SwiftUI.Slider(value: $s, in: 0 ... 1)
//
//            Button("Increment") {
//                withAnimation(.bouncy) {
//                    p += 0.1
//                }
//            }
//        }
//    }
// }
//
// #Preview {
//    Test()
// }
