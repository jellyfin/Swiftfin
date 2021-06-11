/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import MobileVLCKit
import JellyfinAPI
import MediaPlayer

struct Subtitle {
    var name: String
    var id: Int32
    var url: URL?
    var delivery: SubtitleDeliveryMethod
    var codec: String
}

struct AudioTrack {
    var name: String
    var id: Int32
}

class PlaybackItem: ObservableObject {
    @Published var videoType: PlayMethod = .directPlay
    @Published var videoUrl: URL = URL(string: "https://example.com")!
}

protocol PlayerViewControllerDelegate: AnyObject {
    func hideLoadingView(_ viewController: PlayerViewController)
    func showLoadingView(_ viewController: PlayerViewController)
    func exitPlayer(_ viewController: PlayerViewController)
}

class PlayerViewController: UIViewController, VLCMediaDelegate, VLCMediaPlayerDelegate {

    weak var delegate: PlayerViewControllerDelegate?

    var mediaPlayer = VLCMediaPlayer()
    var globalData = GlobalData()

    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var videoControlsView: UIView!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var jumpBackButton: UIButton!
    @IBOutlet weak var jumpForwardButton: UIButton!
    @IBOutlet weak var playerSettingsButton: UIButton!

    var shouldShowLoadingScreen: Bool = false
    var ssTargetValueOffset: Int = 0
    var ssStartValue: Int = 0
    var optionsVC: VideoPlayerSettingsView?

    var paused: Bool = true
    var lastTime: Float = 0.0
    var startTime: Int = 0
    var controlsAppearTime: Double = 0

    var selectedAudioTrack: Int32 = -1 {
        didSet {
            print(selectedAudioTrack)
        }
    }
    var selectedCaptionTrack: Int32 = -1 {
        didSet {
            print(selectedCaptionTrack)
        }
    }
    var playSessionId: String = ""
    var lastProgressReportTime: Double = 0

    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []

    var manifest: BaseItemDto = BaseItemDto()
    var playbackItem = PlaybackItem()

    @IBAction func seekSliderStart(_ sender: Any) {
        sendProgressReport(eventName: "pause")
        mediaPlayer.pause()
    }

    @IBAction func seekSliderValueChanged(_ sender: Any) {
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))/1000
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let scrubRemaining = videoDuration - secondsScrubbedTo
        let remainingTime = scrubRemaining
        let hours = floor(remainingTime / 3600)
        let minutes = (remainingTime.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = (remainingTime.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60)
        if hours != 0 {
            timeText.text = "\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        } else {
            timeText.text = "\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        }
    }

    @IBAction func seekSliderEnd(_ sender: Any) {
        print("ss end")
        let videoPosition = Double(mediaPlayer.time.intValue)
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))
        // Scrub is value from 0..1 - find position in video and add / or remove.
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let offset = secondsScrubbedTo - videoPosition
        mediaPlayer.play()
        if offset > 0 {
            mediaPlayer.jumpForward(Int32(offset)/1000)
        } else {
            mediaPlayer.jumpBackward(Int32(abs(offset))/1000)
        }
        sendProgressReport(eventName: "unpause")
    }

    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        mediaPlayer.stop()
        delegate?.exitPlayer(self)
    }

    @IBAction func controlViewTapped(_ sender: Any) {
        videoControlsView.isHidden = true
    }

    @IBAction func contentViewTapped(_ sender: Any) {
        videoControlsView.isHidden = false
        controlsAppearTime = CACurrentMediaTime()
    }

    @IBAction func jumpBackTapped(_ sender: Any) {
        if paused == false {
            mediaPlayer.jumpBackward(15)
        }
    }

    @IBAction func jumpForwardTapped(_ sender: Any) {
        if paused == false {
            mediaPlayer.jumpForward(30)
        }
    }

    @IBOutlet weak var mainActionButton: UIButton!
    @IBAction func mainActionButtonPressed(_ sender: Any) {
        print(mediaPlayer.state.rawValue)
        if paused {
            mediaPlayer.play()
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            paused = false
        } else {
            mediaPlayer.pause()
            mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            paused = true
        }
    }

    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        optionsVC = VideoPlayerSettingsView()
        optionsVC?.delegate = self

        optionsVC?.modalPresentationStyle = .popover
        optionsVC?.popoverPresentationController?.sourceView = playerSettingsButton

        // Present the view controller (in a popover).
        self.present(optionsVC!, animated: true) {
            print("popover visible, pause playback")
            self.mediaPlayer.pause()
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }

    func settingsPopoverDismissed() {
        optionsVC?.dismiss(animated: true, completion: nil)
        self.mediaPlayer.play()
        self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    func setupNowPlayingCC() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { _ in
            self.mediaPlayer.pause()
            self.sendProgressReport(eventName: "pause")
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            return .success
        }

        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            self.mediaPlayer.play()
            self.sendProgressReport(eventName: "unpause")
            self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            return .success
        }

        // Add handler for FF command
        commandCenter.seekForwardCommand.addTarget { _ in
            self.mediaPlayer.jumpForward(30)
            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            self.mediaPlayer.jumpBackward(15)
            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let targetSeconds = event.positionTime

                let videoPosition = Double(self.mediaPlayer.time.intValue)
                let offset = targetSeconds - videoPosition
                if offset > 0 {
                    self.mediaPlayer.jumpForward(Int32(offset)/1000)
                } else {
                    self.mediaPlayer.jumpBackward(Int32(abs(offset))/1000)
                }
                self.sendProgressReport(eventName: "unpause")

                return .success
            } else {
                return .commandFailed
            }
        }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = manifest.name ?? ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    override func remoteControlReceived(with event: UIEvent?) {
        dump(event)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // View has loaded.

        // Rotate to landscape only if necessary

        UIViewController.attemptRotationToDeviceOrientation()

        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)
        // mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")

        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView

        if manifest.type == "Movie" {
            titleLabel.text = manifest.name ?? ""
        } else {
            titleLabel.text = "S\(String(manifest.parentIndexNumber ?? 0)):E\(String(manifest.indexNumber ?? 0)) “\(manifest.name ?? "")”"
        }

        // Fetch max bitrate from UserDefaults depending on current connection mode
        let defaults = UserDefaults.standard
        let maxBitrate = globalData.isInNetwork ? defaults.integer(forKey: "InNetworkBandwidth") : defaults.integer(forKey: "OutOfNetworkBandwidth")

        // Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()

        let playbackInfo = PlaybackInfoDto(userId: globalData.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, deviceProfile: profile, autoOpenLiveStream: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            delegate?.showLoadingView(self)
            MediaInfoAPI.getPostedPlaybackInfo(itemId: manifest.id!, userId: globalData.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, autoOpenLiveStream: true, playbackInfoDto: playbackInfo)
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: self.globalData, completion: completion)
                }, receiveValue: { [self] response in
                    playSessionId = response.playSessionId ?? ""
                    let mediaSource = response.mediaSources!.first.self!
                    if mediaSource.transcodingUrl != nil {
                        // Item is being transcoded by request of server
                        let streamURL = URL(string: "\(globalData.server.baseURI!)\(mediaSource.transcodingUrl!)")
                        let item = PlaybackItem()
                        item.videoType = .transcode
                        item.videoUrl = streamURL!

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams! {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(globalData.server.baseURI!)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
                                }
                                let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl, delivery: stream.deliveryMethod!, codec: stream.codec ?? "webvtt")
                                subtitleTrackArray.append(subtitle)
                            }

                            if stream.type == .audio {
                                let subtitle = AudioTrack(name: stream.displayTitle!, id: Int32(stream.index!))
                                if stream.isDefault! == true {
                                    selectedAudioTrack = Int32(stream.index!)
                                }
                                audioTrackArray.append(subtitle)
                            }
                        }

                        if selectedAudioTrack == -1 {
                            if audioTrackArray.count > 0 {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        self.sendPlayReport()
                        playbackItem = item
                    } else {
                        // Item will be directly played by the client.
                        let streamURL: URL = URL(string: "\(globalData.server.baseURI!)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(globalData.user.device_uuid!)&api_key=\(globalData.authToken)&Tag=\(mediaSource.eTag!)")!

                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .directPlay

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams! {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(globalData.server.baseURI!)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
                                }
                                let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl, delivery: stream.deliveryMethod!, codec: stream.codec ?? "webvtt")
                                subtitleTrackArray.append(subtitle)
                            }

                            if stream.type == .audio {
                                let subtitle = AudioTrack(name: stream.displayTitle!, id: Int32(stream.index!))
                                if stream.isDefault! == true {
                                    selectedAudioTrack = Int32(stream.index!)
                                }
                                audioTrackArray.append(subtitle)
                            }
                        }

                        if selectedAudioTrack == -1 {
                            if audioTrackArray.count > 0 {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        self.sendPlayReport()
                        playbackItem = item
                    }

                    mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
                    mediaPlayer.play()
                    
                    //1 second = 10,000,000 ticks
                    
                    let rawStartTicks = manifest.userData?.playbackPositionTicks ?? 0
                    
                    if(rawStartTicks != 0) {
                        let startSeconds = rawStartTicks / 10_000_000
                        mediaPlayer.jumpForward(Int32(startSeconds))
                    }
                    
                    //Pause and load captions into memory.
                    mediaPlayer.pause()
                    subtitleTrackArray.forEach { sub in
                        if sub.id != -1 && sub.delivery == .external && sub.codec != "subrip" {
                            mediaPlayer.addPlaybackSlave(sub.url!, type: .subtitle, enforce: false)
                        }
                    }

                    // Wait for captions to load
                    delegate?.showLoadingView(self)
                    while mediaPlayer.numberOfSubtitlesTracks != subtitleTrackArray.count - 1 {}

                    // Select default track & resume playback
                    mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
                    mediaPlayer.pause()
                    mediaPlayer.play()
                })
                .store(in: &globalData.pendingAPIRequests)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    // MARK: VideoPlayerSettings Delegate
    func subtitleTrackChanged(newTrackID: Int32) {
        selectedCaptionTrack = newTrackID
        mediaPlayer.currentVideoSubTitleIndex = newTrackID
    }

    func audioTrackChanged(newTrackID: Int32) {
        selectedAudioTrack = newTrackID
        mediaPlayer.currentAudioTrackIndex = newTrackID
    }

    // MARK: VLCMediaPlayer Delegates
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
            let currentState: VLCMediaPlayerState = mediaPlayer.state
            switch currentState {
            case .stopped :
                break
            case .ended :
                break
            case .playing :
                print("Video is playing")
                self.setupNowPlayingCC()
                sendProgressReport(eventName: "unpause")
                delegate?.hideLoadingView(self)
                paused = false

            case .paused :
                print("Video is paused)")
                paused = true

            case .opening :
                print("Video is opening)")

            case .buffering :
                print("Video is buffering)")
                delegate?.showLoadingView(self)
                mediaPlayer.pause()
                usleep(10000)
                mediaPlayer.play()

            case .error :
                print("Video has error)")
                sendStopReport()
            case .esAdded:
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            @unknown default:
                break
            }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        let time = mediaPlayer.position
        if time != lastTime {
            paused = false
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            seekSlider.setValue(mediaPlayer.position, animated: true)
            delegate?.hideLoadingView(self)

            let remainingTime = abs(mediaPlayer.remainingTime.intValue)/1000
            let hours = remainingTime / 3600
            let minutes = (remainingTime % 3600) / 60
            let seconds = (remainingTime % 3600) % 60
            var timeTextStr = ""
            if hours != 0 {
                timeTextStr = "\(Int(hours)):\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))"
            } else {
                timeTextStr = "\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))"
            }
            timeText.text = timeTextStr

            if CACurrentMediaTime() - controlsAppearTime > 5 {
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    self.videoControlsView.alpha = 0.0
                }, completion: { (_: Bool) in
                    self.videoControlsView.isHidden = true
                    self.videoControlsView.alpha = 1
                })
                controlsAppearTime = 10000000000000000000000
            }
        } else {
            paused = true
        }
        lastTime = time

        if CACurrentMediaTime() - lastProgressReportTime > 5 {
            sendProgressReport(eventName: "timeupdate")
            lastProgressReportTime = CACurrentMediaTime()
        }
    }

    // MARK: Jellyfin Playstate updates
    func sendProgressReport(eventName: String) {
        if (eventName == "timeupdate" && mediaPlayer.state == .playing) || eventName != "timeupdate" {
            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: (mediaPlayer.state == .paused), isMuted: false, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")

            PlaystateAPI.reportPlaybackProgress(playbackProgressInfo: progressInfo)
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: self.globalData, completion: completion)
                }, receiveValue: { _ in
                    print("Playback progress report sent!")
                })
                .store(in: &globalData.pendingAPIRequests)
        }
    }

    func sendStopReport() {
        let stopInfo = PlaybackStopInfo(item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), liveStreamId: nil, playSessionId: playSessionId, failed: nil, nextMediaType: nil, playlistItemId: "playlistItem0", nowPlayingQueue: [])

        PlaystateAPI.reportPlaybackStopped(playbackStopInfo: stopInfo)
            .sink(receiveCompletion: { completion in
                HandleAPIRequestCompletion(globalData: self.globalData, completion: completion)
            }, receiveValue: { _ in
                print("Playback stop report sent!")
            })
            .store(in: &globalData.pendingAPIRequests)
    }

    func sendPlayReport() {
        startTime = Int(Date().timeIntervalSince1970) * 10000000

        let startInfo = PlaybackStartInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: false, isMuted: false, positionTicks: manifest.userData?.playbackPositionTicks, playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")

        PlaystateAPI.reportPlaybackStart(playbackStartInfo: startInfo)
            .sink(receiveCompletion: { completion in
                HandleAPIRequestCompletion(globalData: self.globalData, completion: completion)
            }, receiveValue: { _ in
                print("Playback start report sent!")
            })
            .store(in: &globalData.pendingAPIRequests)
    }
}

struct VLCPlayerWithControls: UIViewControllerRepresentable {
    var item: BaseItemDto
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var globalData: GlobalData

    var loadBinding: Binding<Bool>
    var pBinding: Binding<Bool>

    class Coordinator: NSObject, PlayerViewControllerDelegate {
        let loadBinding: Binding<Bool>
        let pBinding: Binding<Bool>

        init(loadBinding: Binding<Bool>, pBinding: Binding<Bool>) {
            self.loadBinding = loadBinding
            self.pBinding = pBinding
        }

        func hideLoadingView(_ viewController: PlayerViewController) {
            self.loadBinding.wrappedValue = false
        }

        func showLoadingView(_ viewController: PlayerViewController) {
            self.loadBinding.wrappedValue = true
        }

        func exitPlayer(_ viewController: PlayerViewController) {
            self.pBinding.wrappedValue = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadBinding: self.loadBinding, pBinding: self.pBinding)
    }

    typealias UIViewControllerType = PlayerViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) -> VLCPlayerWithControls.UIViewControllerType {
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let customViewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! PlayerViewController
        customViewController.manifest = item
        customViewController.delegate = context.coordinator
        customViewController.globalData = globalData
        return customViewController
    }

    func updateUIViewController(_ uiViewController: VLCPlayerWithControls.UIViewControllerType, context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) {
    }
}
