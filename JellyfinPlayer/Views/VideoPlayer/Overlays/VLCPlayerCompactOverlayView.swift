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
            
            VStack(alignment: .EpisodeSeriesAlignmentGuide) {
                
                // MARK: Top Bar
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
                        
//                        Button {
//                            viewModel.screenFilled = !viewModel.screenFilled
//                        } label: {
//                            if viewModel.screenFilled {
//                                Image(systemName: "rectangle.arrowtriangle.2.inward")
//                                    .rotationEffect(Angle(degrees: 90))
//                            } else {
//                                Image(systemName: "rectangle.arrowtriangle.2.outward")
//                                    .rotationEffect(Angle(degrees: 90))
//                            }
//                        }
                        
                        Button {
                            viewModel.playerOverlayDelegate?.didSelectCaptions()
                        } label: {
                            if viewModel.subtitlesEnabled {
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
            
            Spacer()
            
            // MARK: Bottom Bar
            ZStack {
                
//                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
//                    .cornerRadius(25)
//                    .mask {
//                        Rectangle()
//                    }
                
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
                                .padding(.horizontal, 5)
                                .frame(minWidth: 30, maxWidth: 30)
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
                                                       thumbSize: CGSize.Circle(radius: viewModel.sliderIsScrubbing ? 25 : 20),
                                                       thumbInteractiveSize: CGSize.Circle(radius: 40),
                                                           options: .defaultOptions)
                        )
                    
                    Text(viewModel.rightLabelText)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .frame(minWidth: 70, maxWidth: 70)
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: 800, maxHeight: 50)
        }
        .padding(.top)
//        .padding(.horizontal)
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

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct VLCPlayerCompactOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
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
                                                                        selectedSubtitleStreamIndex: -1))
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}

extension CGSize {
    
    static func Circle(radius: CGFloat) -> CGSize {
        return CGSize(width: radius, height: radius)
    }
}
