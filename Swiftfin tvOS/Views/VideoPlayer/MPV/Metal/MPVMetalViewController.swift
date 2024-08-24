//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Libmpv
import UIKit

// warning: metal API validation has been disabled to ignore crash when playing HDR videos.
// Edit Scheme -> Run -> Diagnostics -> Metal API Validation -> Turn it off
// https://github.com/KhronosGroup/MoltenVK/issues/2226
final class MPVMetalViewController: UIViewController {
    var metalLayer = MetalLayer()
    var mpv: OpaquePointer!
    var playDelegate: MPVPlayerDelegate?
    lazy var queue = DispatchQueue(label: "mpv", qos: .userInitiated)
    private var playPauseRecognizer: UITapGestureRecognizer!

    var playUrl: URL?
    var hdrAvailable: Bool {
        let maxEDRRange = view.window?.screen.potentialEDRHeadroom ?? 1.0
        let sigPeak = getDouble(MPVProperty.videoParamsSigPeak)
        // display screen support HDR and current playing HDR video
        return maxEDRRange > 1.0 && sigPeak > 1.0
    }

    var hdrEnabled = false {
        didSet {
            // FIXME: target-colorspace-hint does not support being changed at runtime.
            // this option should be set as early as possible otherwise can cause issues
            // not recommended to use this way.
            if hdrEnabled {
                checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "yes"))
            } else {
                checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "no"))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        metalLayer.frame = view.frame
        print(view.bounds)
        print(view.frame)
        metalLayer.contentsScale = UIScreen.main.nativeScale
        metalLayer.framebufferOnly = true
        metalLayer.backgroundColor = UIColor.black.cgColor

        view.layer.addSublayer(metalLayer)

        playPauseRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePause))
        playPauseRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPauseRecognizer)

        setupMpv()

        if let url = playUrl {
            loadFile(url)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        metalLayer.frame = view.frame
    }

    func setupMpv() {
        mpv = mpv_create()
        if mpv == nil {
            print("failed creating context\n")
            exit(1)
        }

        // https://mpv.io/manual/stable/#options
        #if DEBUG
        checkError(mpv_request_log_messages(mpv, "debug"))
        #else
        checkError(mpv_request_log_messages(mpv, "no"))
        #endif
        #if os(macOS)
        checkError(mpv_set_option_string(mpv, "input-media-keys", "yes"))
        #endif
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &metalLayer))
        checkError(mpv_set_option_string(mpv, "subs-match-os-language", "yes"))
        checkError(mpv_set_option_string(mpv, "subs-fallback", "yes"))
        checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
        checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
        // checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
        checkError(mpv_set_option_string(mpv, "video-rotate", "no"))

        checkError(mpv_set_option_string(mpv, "ytdl", "no"))
//        checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "yes")) // HDR passthrough
//        checkError(mpv_set_option_string(mpv, "tone-mapping-visualize", "yes"))  // only for debugging purposes
//        checkError(mpv_set_option_string(mpv, "profile", "fast"))   // can fix frame drop in poor device when play 4k

        checkError(mpv_initialize(mpv))

        mpv_observe_property(mpv, 0, MPVProperty.videoParamsSigPeak, MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, MPVProperty.pausedForCache, MPV_FORMAT_FLAG)
//        mpv_set_wakeup_callback(self.mpv, { ctx in
//
//            let client = unsafeBitCast(ctx, to: MPVMetalViewController.self)
//            client.readEvents()
//        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }

    func loadFile(
        _ url: URL
    ) {
        var args = [url.absoluteString]
        var options = [String]()

        args.append("replace")

        if !options.isEmpty {
            args.append(options.joined(separator: ","))
        }

        command("loadfile", args: args)
    }

    @objc
    func togglePause() {
        getFlag(MPVProperty.pause) ? play() : pause()
    }

    func end() {
        mpv_terminate_destroy(mpv)
        mpv = nil
    }

    func play() {
        setFlag(MPVProperty.pause, false)
    }

    func pause() {
        setFlag(MPVProperty.pause, true)
    }

    private func getDouble(_ name: String) -> Double {
        guard mpv != nil else { return 0.0 }
        var data = Double()
        mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
        return data
    }

    private func getString(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        let str: String? = cstr == nil ? nil : String(cString: cstr!)
        mpv_free(cstr)
        return str
    }

    private func getFlag(_ name: String) -> Bool {
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
        return data > 0
    }

    private func setFlag(_ name: String, _ flag: Bool) {
        guard mpv != nil else { return }
        var data: Int = flag ? 1 : 0
        mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
    }

    func command(
        _ command: String,
        args: [String?] = [],
        checkForErrors: Bool = true,
        returnValueCallback: ((Int32) -> Void)? = nil
    ) {
        guard mpv != nil else {
            return
        }
        var cargs = makeCArgs(command, args).map { $0.flatMap { UnsafePointer<CChar>(strdup($0)) } }
        defer {
            for ptr in cargs where ptr != nil {
                free(UnsafeMutablePointer(mutating: ptr!))
            }
        }
        // print("\(command) -- \(args)")
        let returnValue = mpv_command(mpv, &cargs)
        if checkForErrors {
            checkError(returnValue)
        }
        if let cb = returnValueCallback {
            cb(returnValue)
        }
    }

    private func makeCArgs(_ command: String, _ args: [String?]) -> [String?] {
        if !args.isEmpty, args.last == nil {
            fatalError("Command do not need a nil suffix")
        }

        var strArgs = args
        strArgs.insert(command, at: 0)
        strArgs.append(nil)

        return strArgs
    }

    func readEvents() {
        queue.async { [weak self] in
            guard let self else { return }

            while self.mpv != nil {
                let event = mpv_wait_event(self.mpv, 0)
                if event?.pointee.event_id == MPV_EVENT_NONE {
                    break
                }

                switch event!.pointee.event_id {
                case MPV_EVENT_PROPERTY_CHANGE:
                    let dataOpaquePtr = OpaquePointer(event!.pointee.data)
                    if let property = UnsafePointer<mpv_event_property>(dataOpaquePtr)?.pointee {
                        let propertyName = String(cString: property.name)
                        switch propertyName {
                        case MPVProperty.pausedForCache:
                            let buffering = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee ?? true
                            DispatchQueue.main.async {
                                self.playDelegate?.propertyChange(mpv: self.mpv, propertyName: propertyName, data: buffering)
                            }
                        default: break
                        }
                    }
                case MPV_EVENT_SHUTDOWN:
                    print("event: shutdown\n")
                    mpv_terminate_destroy(mpv)
                    mpv = nil
                case MPV_EVENT_LOG_MESSAGE:
                    let msg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event!.pointee.data))
                    print(
                        "[\(String(cString: (msg!.pointee.prefix)!))] \(String(cString: (msg!.pointee.level)!)): \(String(cString: (msg!.pointee.text)!))",
                        terminator: ""
                    )
                default:
                    let eventName = mpv_event_name(event!.pointee.event_id)
                    print("event: \(String(cString: eventName!))")
                }
            }
        }
    }

    private func checkError(_ status: CInt) {
        if status < 0 {
            print("MPV API error: \(String(cString: mpv_error_string(status)))\n")
        }
    }
}
