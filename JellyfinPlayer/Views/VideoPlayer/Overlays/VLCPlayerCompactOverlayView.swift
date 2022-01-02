//
//  VLCPlayerCompactOverlayView.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 12/26/21.
//

import Combine
import Defaults
import JellyfinAPI
import MobileVLCKit
import Sliders
import SwiftUI

struct VLCPlayerCompactOverlayView: View, VideoPlayerOverlay {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Default(.videoPlayerJumpForward) var jumpForwardLength
    @Default(.videoPlayerJumpBackward) var jumpBackwardLength
    
    @ViewBuilder
    private var mainButtonView: some View {
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
    
    @ViewBuilder
    private var mainBody: some View {
        VStack {
            
            // MARK: Top Bar
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
                    .frame(height: 80)
                
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
                            
                            if viewModel.shouldShowGoogleCast {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectGoogleCast()
                                } label: {
                                    Image(systemName: "rectangle.badge.plus")
                                }
                            }
                            
                            if viewModel.shouldShowAirplay {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectAirplay()
                                } label: {
                                    Image(systemName: "airplayvideo")
                                }
                            }
                            
                            if viewModel.showAdjacentItems {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectPreviousItem()
                                } label: {
                                    Image(systemName: "chevron.left.circle")
                                }
                                .disabled(viewModel.previousItemVideoPlayerViewModel == nil)
                                .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                                
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectNextItem()
                                } label: {
                                    Image(systemName: "chevron.right.circle")
                                }
                                .disabled(viewModel.nextItemVideoPlayerViewModel == nil)
                                .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                            }
                            
                            if viewModel.shouldShowAutoPlayNextItem {
                                Button {
                                    viewModel.autoPlayNextItem.toggle()
                                } label: {
                                    if viewModel.autoPlayNextItem {
                                        Image(systemName: "play.circle.fill")
                                    } else {
                                        Image(systemName: "play.circle")
                                    }
                                }
                            }
                            
                            if !viewModel.subtitleStreams.isEmpty {
                                Button {
                                    viewModel.playerOverlayDelegate?.didSelectCaptions()
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
                                
                                Menu {
                                    ForEach(VideoPlayerJumpLength.allCases, id: \.self) { forwardLength in
                                        Button {
                                            jumpForwardLength = forwardLength
                                        } label: {
                                            if forwardLength == jumpForwardLength {
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
                                            jumpBackwardLength = backwardLength
                                        } label: {
                                            if backwardLength == jumpBackwardLength {
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
            
            Spacer()
            
            // MARK: Bottom Bar
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
                    .frame(height: 70)
                
                HStack {
                    
                    HStack {
                        Button {
                            viewModel.playerOverlayDelegate?.didSelectBackward()
                        } label: {
                            Image(systemName: jumpBackwardLength.backwardImageLabel)
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
                            Image(systemName: jumpForwardLength.forwardImageLabel)
                                .padding(.horizontal, 5)
                        }
                    }
                    .font(.system(size: 24, weight: .semibold, design: .default))
//                    .padding(.trailing, 10)
                    
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
        mainBody
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.playerOverlayDelegate?.didGenerallyTap()
            }
    }
}

struct VLCPlayerCompactOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            
            VLCPlayerCompactOverlayView(viewModel: VideoPlayerViewModel(item: BaseItemDto(runTimeTicks: 720 * 10_000_000),
                                                                        title: "Glorious Purpose",
                                                                        subtitle: "Loki - S1E1",
                                                                        streamURL: URL(string: "www.apple.com")!,
                                                                        hlsURL: URL(string: "www.apple.com")!,
                                                                        response: PlaybackInfoResponse(),
                                                                        audioStreams: [MediaStream(displayTitle: "English", index: -1)],
                                                                        subtitleStreams: [MediaStream(displayTitle: "None", index: -1)],
                                                                        defaultAudioStreamIndex: -1,
                                                                        defaultSubtitleStreamIndex: -1,
                                                                        playerState: .playing,
                                                                        shouldShowGoogleCast: false,
                                                                        shouldShowAirplay: false,
                                                                        subtitlesEnabled: true,
                                                                        sliderPercentage: 0.432,
                                                                        selectedAudioStreamIndex: -1,
                                                                        selectedSubtitleStreamIndex: -1,
                                                                        showAdjacentItems: true,
                                                                        shouldShowAutoPlayNextItem: true,
                                                                        autoPlayNextItem: true))
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
