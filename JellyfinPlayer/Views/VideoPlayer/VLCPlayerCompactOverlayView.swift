//
//  VLCPlayerCompactOverlayView.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 12/26/21.
//

import Combine
import MobileVLCKit
import SwiftUI
import JellyfinAPI

struct VLCPlayerCompactOverlayView: View {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
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
            
            VStack(alignment: .EpisodeSeriesAlignmentGuide) {
                
                // MARK: Top Bar
                HStack(alignment: .top) {
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectClose()
                            } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 28, weight: .regular, design: .default))
                            }
                            
                            Text(viewModel.title)
                                .font(.system(size: 28, weight: .regular, design: .default))
                                .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                                    context[.leading]
                                }
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
                        
                        Button {
                            viewModel.screenFilled = !viewModel.screenFilled
                        } label: {
                            if viewModel.screenFilled {
                                Image(systemName: "rectangle.arrowtriangle.2.inward")
                                    .rotationEffect(Angle(degrees: 90))
                            } else {
                                Image(systemName: "rectangle.arrowtriangle.2.outward")
                                    .rotationEffect(Angle(degrees: 90))
                            }
                        }
                        
                        Button {
                            viewModel.playerOverlayDelegate?.didSelectCaptions()
                        } label: {
                            if viewModel.captionsEnabled {
                                Image(systemName: "captions.bubble.fill")
                            } else {
                                Image(systemName: "captions.bubble")
                            }
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

                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .font(.system(size: 24))
                
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
            
            Spacer()
            
            // MARK: Bottom Bar
            HStack {
                
                HStack(spacing: 20) {
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectBackward()
                    } label: {
                        Image(systemName: "gobackward.10")
                    }
                    
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectMain()
                    } label: {
                        mainButtonView
                    }
                    
                    Button {
                        viewModel.playerOverlayDelegate?.didSelectForward()
                    } label: {
                        Image(systemName: "goforward.10")
                    }
                }
                .font(.system(size: 24, weight: .semibold, design: .default))
                .padding(.trailing, 20)
                
                Text(viewModel.leftLabelText)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                
                Slider(value: $viewModel.sliderPercentage) { editing in
                    viewModel.sliderIsScrubbing = editing
                }
                    .foregroundColor(.purple)
                    .tint(.purple)
                
//                ValueSlider(value: $viewModel.sliderPercentage)
//                    .valueSliderStyle(
//                        HorizontalValueSliderStyle(thumb: Circle().foregroundColor(.purple),
//                                                   thumbSize: CGSize(width: 32, height: 32),
//                                                   thumbInteractiveSize: CGSize(width: 50, height: 50),
//                                                   options: [.interactiveTrack])
//                    )
                
                Text(viewModel.rightLabelText)
                    .font(.system(size: 18, weight: .semibold, design: .default))
            }
            .frame(height: 50)
        }
        .padding(.top)
        .padding(.horizontal)
        .ignoresSafeArea(edges: .top)
        .tint(Color.white)
        .foregroundColor(Color.white)
    }
    
    var body: some View {
        mainBody
            .background {
                Color(uiColor: .black.withAlphaComponent(0.001))
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.playerOverlayDelegate?.didGenerallyTap()
                    }
            }
    }
}

struct VLCPlayerCompactOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            
            VLCPlayerCompactOverlayView(viewModel: VideoPlayerViewModel(item: BaseItemDto(runTimeTicks: 123 * 10_000_000),
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
                                                                        sliderPercentage: 0.5,
                                                                        selectedAudioStreamIndex: -1,
                                                                        selectedSubtitleStreamIndex: -1))
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
