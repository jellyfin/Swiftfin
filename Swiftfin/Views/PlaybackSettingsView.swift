//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

// TODO: organize
struct BasicStepper<Value: CustomStringConvertible & Strideable>: View {
    
    @Binding
    private var value: Value
    
    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private var formatter: (Value) -> String
    
    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                
                Spacer()
                
                formatter(value).text
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension BasicStepper {
    
    init(
        title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride
    ) {
        self.title = title
        self.range = range
        self.step = step
        self._value = value
        self.formatter = { $0.description }
    }
    
    func valueFormatter(_ formatter: @escaping (Value) -> String) -> Self {
        copy(modifying: \.formatter, with: formatter)
    }
}

struct PlaybackSettingsView: View {

    @EnvironmentObject
    private var router: PlaybackSettingsCoordinator.Router
    @EnvironmentObject
    private var splitContentViewProxy: SplitContentViewProxy
    @EnvironmentObject
    private var viewModel: VideoPlayerViewModel

    @Environment(\.audioOffset)
    @Binding
    private var audioOffset
    @Environment(\.subtitleOffset)
    @Binding
    private var subtitleOffset

    var body: some View {
        Form {
            Section {
                
                ChevronButton(title: L10n.videoPlayer)
                    .onSelect {
                        router.route(to: \.videoPlayerSettings)
                    }
                
//                ChevronButton(title: "Playback Information")
//                    .onSelect {
//                        router.route(to: \.playbackInformation)
//                    }
            } header: {
                EmptyView()
            }
            
            // TODO: second formatting
            BasicStepper(
                title: "Audio Offset",
                value: _audioOffset.wrappedValue,
                range: -30_000 ... 30_000,
                step: 100
            )
//            .valueFormatter { value in
//                "\()"
//            }
            
            BasicStepper(
                title: "Subtitle Offset",
                value: _subtitleOffset.wrappedValue,
                range: -30_000 ... 30_000,
                step: 100
            )

            Section("Audio") {
                ForEach(viewModel.audioStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }

            Section("Subtitle") {
                ForEach(viewModel.subtitleStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }
        }
        .navigationTitle("Playback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    splitContentViewProxy.hide()
                } label: {
                    Image(systemName: "xmark.circle.fill")
//                        .resizable()
//                        .frame(width: 44, height: 50)
                }
            }
        }
    }
}
