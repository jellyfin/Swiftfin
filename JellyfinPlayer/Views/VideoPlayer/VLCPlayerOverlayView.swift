/*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Combine
import Defaults
import JellyfinAPI
import MobileVLCKit
import Sliders
import SwiftUI

struct VLCPlayerOverlayView: View {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @ViewBuilder
    private var mainButtonView: some View {
        if viewModel.overlayType == .normal {
            switch viewModel.playerState {
            case .stopped, .paused:
                Image(systemName: "play.fill")
                    .font(.system(size: 56, weight: .semibold, design: .default))
            case .playing:
                Image(systemName: "pause")
                    .font(.system(size: 56, weight: .semibold, design: .default))
            default:
                ProgressView()
                    .scaleEffect(2)
            }
        } else if viewModel.overlayType == .compact {
            switch viewModel.playerState {
            case .stopped, .paused:
                Image(systemName: "play.fill")
                    .font(.system(size: 28, weight: .heavy, design: .default))
            case .playing:
                Image(systemName: "pause")
                    .font(.system(size: 28, weight: .heavy, design: .default))
            default:
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private var mainBody: some View {
        VStack {
            
            // MARK: Top Bar
            ZStack {
                
                if viewModel.overlayType == .compact {
                    LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .ignoresSafeArea()
                        .frame(height: 80)
                }
                
                VStack(alignment: .EpisodeSeriesAlignmentGuide) {
                    
                    HStack(alignment: .center) {
                        
                        HStack {
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectClose()
                            } label: {
                                Image(systemName: "chevron.backward")
                                    .padding()
                                        .padding(.trailing, -10)
                            }
                            
                            Text(viewModel.title)
                                .font(.system(size: 28, weight: .regular, design: .default))
                                .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                                    context[.leading]
                                }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            
                            if viewModel.shouldShowPlayPreviousItem {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectPlayPreviousItem()
                                } label: {
                                    Image(systemName: "chevron.left.circle")
                                }
                                .disabled(viewModel.previousItemVideoPlayerViewModel == nil)
                                .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                            }
                            
                            if viewModel.shouldShowPlayNextItem {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectPlayNextItem()
                                } label: {
                                    Image(systemName: "chevron.right.circle")
                                }
                                .disabled(viewModel.nextItemVideoPlayerViewModel == nil)
                                .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                            }
                            
                            if viewModel.shouldShowAutoPlay {
                                Button {
                                    viewModel.autoplayEnabled.toggle()
                                } label: {
                                    if viewModel.autoplayEnabled {
                                        Image(systemName: "play.circle.fill")
                                    } else {
                                        Image(systemName: "stop.circle")
                                    }
                                }
                            }
                            
                            if !viewModel.subtitleStreams.isEmpty {
                                Button {
                                    viewModel.subtitlesEnabled.toggle()
                                } label: {
                                    if viewModel.subtitlesEnabled {
                                        Image(systemName: "captions.bubble.fill")
                                    } else {
                                        Image(systemName: "captions.bubble")
                                    }
                                }
                                .disabled(viewModel.selectedSubtitleStreamIndex == -1)
                                .foregroundColor(viewModel.selectedSubtitleStreamIndex == -1 ? .gray : .white)
                            }
                            
                            // MARK: Settings Menu
                            Menu {

                                Menu {
                                    ForEach(viewModel.audioStreams, id: \.self) { audioStream in
                                        Button {
                                            viewModel.selectedAudioStreamIndex = audioStream.index ?? -1
                                        } label: {
                                            if audioStream.index == viewModel.selectedAudioStreamIndex {
                                                Label.init(audioStream.displayTitle ?? "No Title", systemImage: "checkmark")
                                            } else {
                                                Text(audioStream.displayTitle ?? "No Title")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "speaker.wave.3")
                                        Text("Audio")
                                    }
                                }

                                Menu {
                                    ForEach(viewModel.subtitleStreams, id: \.self) { subtitleStream in
                                        Button {
                                            viewModel.selectedSubtitleStreamIndex = subtitleStream.index ?? -1
                                        } label: {
                                            if subtitleStream.index == viewModel.selectedSubtitleStreamIndex {
                                                Label.init(subtitleStream.displayTitle ?? "No Title", systemImage: "checkmark")
                                            } else {
                                                Text(subtitleStream.displayTitle ?? "No Title")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "captions.bubble")
                                        Text("Subtitles")
                                    }
                                }

                                Menu {
                                    ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                                        Button {
                                            viewModel.playbackSpeed = speed
                                        } label: {
                                            if speed == viewModel.playbackSpeed {
                                                Label(speed.displayTitle, systemImage: "checkmark")
                                            } else {
                                                Text(speed.displayTitle)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "speedometer")
                                        Text("Playback Speed")
                                    }
                                }
                                
                                if viewModel.shouldShowJumpButtonsInOverlayMenu {
                                    Menu {
                                        ForEach(VideoPlayerJumpLength.allCases, id: \.self) { forwardLength in
                                            Button {
                                                viewModel.jumpForwardLength = forwardLength
                                            } label: {
                                                if forwardLength == viewModel.jumpForwardLength {
                                                    Label(forwardLength.shortLabel, systemImage: "checkmark")
                                                } else {
                                                    Text(forwardLength.shortLabel)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "goforward")
                                            Text("Jump Forward Length")
                                        }
                                    }
                                    
                                    Menu {
                                        ForEach(VideoPlayerJumpLength.allCases, id: \.self) { backwardLength in
                                            Button {
                                                viewModel.jumpBackwardLength = backwardLength
                                            } label: {
                                                if backwardLength == viewModel.jumpBackwardLength {
                                                    Label(backwardLength.shortLabel, systemImage: "checkmark")
                                                } else {
                                                    Text(backwardLength.shortLabel)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "gobackward")
                                            Text("Jump Backward Length")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                    .font(.system(size: 24))
                    .frame(height: 50)
                    
                    if let seriesTitle = viewModel.subtitle {
                        Text(seriesTitle)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                                context[.leading]
                            }
                            .offset(y: -10)
                    }
                }
            }
            
            // MARK: Center
            
            Spacer()
            
            if viewModel.overlayType == .normal {
                HStack(spacing: 80) {
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectBackward()
                    } label: {
                        Image(systemName: viewModel.jumpBackwardLength.backwardImageLabel)
                    }
                    
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectMain()
                    } label: {
                        mainButtonView
                    }
                    .frame(width: 200)
                    
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectForward()
                    } label: {
                        Image(systemName: viewModel.jumpForwardLength.forwardImageLabel)
                    }
                }
                .font(.system(size: 48))
            }
            
            Spacer()
            
            // MARK: Bottom Bar
            ZStack {
                
                if viewModel.overlayType == .compact {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .ignoresSafeArea()
                        .frame(height: 70)
                }
                
                HStack {
                    
                    if viewModel.overlayType == .compact {
                        HStack {
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectBackward()
                            } label: {
                                Image(systemName: viewModel.jumpBackwardLength.backwardImageLabel)
                                    .padding(.horizontal, 5)
                            }
                            
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectMain()
                            } label: {
                                mainButtonView
                                    .frame(minWidth: 30, maxWidth: 30)
                                    .padding(.horizontal, 10)
                            }
                            
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectForward()
                            } label: {
                                Image(systemName: viewModel.jumpForwardLength.forwardImageLabel)
                                    .padding(.horizontal, 5)
                            }
                        }
                        .font(.system(size: 24, weight: .semibold, design: .default))
                    }
                    
                    Text(viewModel.leftLabelText)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .frame(minWidth: 70, maxWidth: 70)
                    
                    ValueSlider(value: $viewModel.sliderPercentage, onEditingChanged: { editing in
                        viewModel.sliderIsScrubbing = editing
                    })
                        .valueSliderStyle(
                            HorizontalValueSliderStyle(track:
                                                        HorizontalValueTrack(view:
                                                            Capsule().foregroundColor(.purple))
                                                        .background(Capsule().foregroundColor(Color.gray.opacity(0.25)))
                                                        .frame(height: 4),
                                                        thumb: Circle().foregroundColor(.purple)
                                                        .onLongPressGesture(perform: {
                                                            print("got it here")
                                                        }),
                                                       thumbSize: CGSize.Circle(radius: viewModel.sliderIsScrubbing ? 20 : 15),
                                                       thumbInteractiveSize: CGSize.Circle(radius: 40),
                                                           options: .defaultOptions)
                        )
                        .frame(maxHeight: 50)
                    
                    Text(viewModel.rightLabelText)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .frame(minWidth: 70, maxWidth: 70)
                }
                .padding(.horizontal)
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 800 : nil)
            }
            .frame(maxHeight: 50)
        }
        .ignoresSafeArea(edges: .top)
        .tint(Color.white)
        .foregroundColor(Color.white)
    }
    
    var body: some View {
        if viewModel.overlayType == .normal {
            mainBody
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.playerOverlayDelegate?.didGenerallyTap()
                }
                .background {
                    Color(uiColor: .black.withAlphaComponent(0.5))
                        .ignoresSafeArea()
                }
        } else {
            mainBody
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.playerOverlayDelegate?.didGenerallyTap()
                }
        }
    }
}

struct VLCPlayerCompactOverlayView_Previews: PreviewProvider {
    
    static let videoPlayerViewModel = VideoPlayerViewModel(item: BaseItemDto(),
                                                    title: "Glorious Purpose",
                                                    subtitle: "Loki - S1E1",
                                                    streamURL: URL(string: "www.apple.com")!,
                                                    hlsURL: URL(string: "www.apple.com")!,
                                                    response: PlaybackInfoResponse(),
                                                    audioStreams: [MediaStream(displayTitle: "English", index: -1)],
                                                    subtitleStreams: [MediaStream(displayTitle: "None", index: -1)],
                                                    selectedAudioStreamIndex: -1,
                                                    selectedSubtitleStreamIndex: -1,
                                                    subtitlesEnabled: true,
                                                    autoplayEnabled: false,
                                                    overlayType: .compact,
                                                    shouldShowPlayPreviousItem: true,
                                                    shouldShowPlayNextItem: true,
                                                    shouldShowAutoPlay: true)
    
    static var previews: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            
            VLCPlayerOverlayView(viewModel: videoPlayerViewModel)
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}

// MARK: TitleSubtitleAlignment
extension HorizontalAlignment {
    
    private struct TitleSubtitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    static let EpisodeSeriesAlignmentGuide = HorizontalAlignment(TitleSubtitleAlignment.self)
}
