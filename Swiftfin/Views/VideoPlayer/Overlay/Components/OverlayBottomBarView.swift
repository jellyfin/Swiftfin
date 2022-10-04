//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Sliders
import SwiftUI

extension ItemVideoPlayer.Overlay {

    struct BottomBarView: View {

        @Default(.videoPlayerJumpBackward)
        private var jumpBackwardLength
        @Default(.videoPlayerJumpBackward)
        private var jumpForwardLength

        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var currentSecondsHandler: CurrentSecondsHandler

        @State
        private var currentSeconds: Int = 0
        @State
        private var isScrubbing: Bool = false
        @State
        private var progress: CGFloat = 0

        init() {
            print("bottom bar init-ed")
        }

        var body: some View {
            HStack(spacing: 20) {

                
//                    HStack(spacing: 1) {
//
//                        Text(Double(currentSeconds).timeLabel)
//
//                        Text("/")
//
//                        Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel)
//                    }
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
                    
                CapsuleSlider(progress: $progress)
                    .onEditingChanged { isEditing in
                        isScrubbing = isEditing
                    }
                    .frame(height: 50)
            }
            .padding(.horizontal, 50)
            .onChange(of: currentSecondsHandler.currentSeconds) { newValue in
                guard !isScrubbing else { return }
                self.currentSeconds = newValue
                self.progress = CGFloat(newValue) / CGFloat(viewModel.item.runTimeSeconds)
            }
            .onChange(of: isScrubbing) { newValue in
                guard !newValue else { return }
                let scrubbedSeconds = Int32(CGFloat(viewModel.item.runTimeSeconds) * progress)
                viewModel.eventSubject.send(.setTime(.seconds(Int32(scrubbedSeconds))))
            }
            .onChange(of: progress) { _ in
                guard isScrubbing else { return }
                let scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * progress)
                self.currentSeconds = scrubbedSeconds
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}

//struct BottomBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            Color.red
//                .opacity(0.2)
//
//            VStack {
//                Spacer()
//
//                ItemVideoPlayer.Overlay.BottomBarView(viewModel: .init(
//                    playbackURL: URL(string: "https://apple.com")!,
//                    item: .placeHolder,
//                    audioStreams: [],
//                    subtitleStreams: []))
//                .padding(.horizontal, 50)
//                .padding(.bottom)
//            }
//        }
//        .ignoresSafeArea()
//        .preferredColorScheme(.dark)
//        .previewInterfaceOrientation(.landscapeRight)
//    }
//}
