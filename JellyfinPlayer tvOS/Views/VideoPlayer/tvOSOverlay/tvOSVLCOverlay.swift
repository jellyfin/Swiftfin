//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

struct tvOSVLCOverlay: View {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @ViewBuilder
    private var mainButtonView: some View {
        switch viewModel.playerState {
        case .stopped, .paused:
            Image(systemName: "play.circle")
        case .playing:
            Image(systemName: "pause.circle")
        default:
            ProgressView()
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7), .black]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
                .frame(height: viewModel.subtitle == nil ? 180 : 210)
            
            VStack {
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    
                    VStack(alignment: .leading) {
                        if let subtitle = viewModel.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.lightGray)
                        }
                        
                        Text(viewModel.title)
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Spacer()
                    
                    if viewModel.showAdjacentItems {
                        SFSymbolButton(systemName: "chevron.left.circle", action: {
                            viewModel.playerOverlayDelegate?.didSelectPreviousItem()
                        })
                        .frame(maxWidth: 30, maxHeight: 30)
                        .disabled(viewModel.previousItemVideoPlayerViewModel == nil)
                        .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                        
                        SFSymbolButton(systemName: "chevron.right.circle", action: {
                            viewModel.playerOverlayDelegate?.didSelectNextItem()
                        })
                        .frame(maxWidth: 30, maxHeight: 30)
                        .disabled(viewModel.nextItemVideoPlayerViewModel == nil)
                        .foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
                    }
                    
                    if !viewModel.subtitleStreams.isEmpty {
                        if viewModel.subtitlesEnabled {
                            SFSymbolButton(systemName: "captions.bubble.fill") {
                                viewModel.playerOverlayDelegate?.didSelectCaptions()
                            }
                            .frame(maxWidth: 30, maxHeight: 30)
                        } else {
                            SFSymbolButton(systemName: "captions.bubble") {
                                viewModel.playerOverlayDelegate?.didSelectCaptions()
                            }
                            .frame(maxWidth: 30, maxHeight: 30)
                        }
                    }
                    
                    SFSymbolButton(systemName: "ellipsis.circle") {
                        viewModel.playerOverlayDelegate?.didSelectMenu()
                    }
                    .frame(maxWidth: 30, maxHeight: 30)
                    .contextMenu {
                        SFSymbolButton(systemName: "speedometer") {
                            print("here")
                        }
                    }
                }
                .offset(x: 0, y: 10)
                
                SliderView(viewModel: viewModel)
                    .frame(maxHeight: 40)
                
                HStack {
                    
                    HStack(spacing: 10) {
                        mainButtonView
                            .frame(maxWidth: 40, maxHeight: 40)
                        
                        Text(viewModel.leftLabelText)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.rightLabelText)
                }
                .offset(x: 0, y: -10)
            }
        }
        .foregroundColor(.white)
    }
}

struct tvOSVLCOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            
            tvOSVLCOverlay(viewModel: VideoPlayerViewModel(item: BaseItemDto(runTimeTicks: 720 * 10_000_000),
                                                                        title: "Glorious Purpose",
                                                                        subtitle: "Loki - S1E1",
                                                                        streamURL: URL(string: "www.apple.com")!,
                                                                        hlsURL: URL(string: "www.apple.com")!,
                                                                        response: PlaybackInfoResponse(),
                                                                        audioStreams: [MediaStream(displayTitle: "English", index: -1)],
                                                                        subtitleStreams: [MediaStream(displayTitle: "None", index: -1)],
                                                                        defaultAudioStreamIndex: -1,
                                                                        defaultSubtitleStreamIndex: -1,
                                                                        playerState: .error,
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
