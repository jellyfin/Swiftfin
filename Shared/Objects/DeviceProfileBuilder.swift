//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

// lol can someone buy me a coffee this took forever :|

import Foundation
import JellyfinAPI

enum CPUModel {
	case A4
	case A5
	case A5X
	case A6
	case A6X
	case A7
	case A7X
	case A8
	case A8X
	case A9
	case A9X
	case A10
	case A10X
	case A11
	case A12
	case A12X
	case A12Z
	case A13
	case A14
	case M1
	case A99
}

class DeviceProfileBuilder {
	public var bitrate: Int = 0

	public func setMaxBitrate(bitrate: Int) {
		self.bitrate = bitrate
	}

	public func buildProfile() -> DeviceProfile {
		let maxStreamingBitrate = bitrate
		let maxStaticBitrate = bitrate
		let musicStreamingTranscodingBitrate = bitrate

		// Build direct play profiles
		var directPlayProfiles: [DirectPlayProfile] = []
		directPlayProfiles =
			[DirectPlayProfile(container: "mov,mp4,mkv,webm", audioCodec: "aac,mp3,wav", videoCodec: "h264,mpeg4,vp9", type: .video)]

		// Device supports Dolby Digital (AC3, EAC3)
		if supportsFeature(minimumSupported: .A8X) {
			if supportsFeature(minimumSupported: .A9) {
				directPlayProfiles = [DirectPlayProfile(container: "mov,mp4,mkv,webm", audioCodec: "aac,mp3,wav,ac3,eac3,flac,opus",
				                                        videoCodec: "hevc,h264,hev1,mpeg4,vp9",
				                                        type: .video)] // HEVC/H.264 with Dolby Digital
			} else {
				directPlayProfiles = [DirectPlayProfile(container: "mov,mp4,mkv,webm", audioCodec: "ac3,eac3,aac,mp3,wav,opus",
				                                        videoCodec: "h264,mpeg4,vp9", type: .video)] // H.264 with Dolby Digital
			}
		}

		// Device supports Dolby Vision?
		if supportsFeature(minimumSupported: .A10X) {
			directPlayProfiles = [DirectPlayProfile(container: "mov,mp4,mkv,webm", audioCodec: "aac,mp3,wav,ac3,eac3,flac,opus",
			                                        videoCodec: "dvhe,dvh1,h264,hevc,hev1,mpeg4,vp9",
			                                        type: .video)] // H.264/HEVC with Dolby Digital - No Atmos - Vision
		}

		// Device supports Dolby Atmos?
		if supportsFeature(minimumSupported: .A12) {
			directPlayProfiles = [DirectPlayProfile(container: "mov,mp4,mkv,webm",
			                                        audioCodec: "aac,mp3,wav,ac3,eac3,flac,truehd,dts,dca,opus",
			                                        videoCodec: "h264,hevc,dvhe,dvh1,h264,hevc,hev1,mpeg4,vp9",
			                                        type: .video)] // H.264/HEVC with Dolby Digital & Atmos - Vision
		}

		// Build transcoding profiles
		var transcodingProfiles: [TranscodingProfile] = []
		transcodingProfiles = [TranscodingProfile(container: "ts", type: .video, videoCodec: "h264,mpeg4", audioCodec: "aac,mp3,wav")]

		// Device supports Dolby Digital (AC3, EAC3)
		if supportsFeature(minimumSupported: .A8X) {
			if supportsFeature(minimumSupported: .A9) {
				transcodingProfiles = [TranscodingProfile(container: "ts", type: .video, videoCodec: "h264,hevc,mpeg4",
				                                          audioCodec: "aac,mp3,wav,eac3,ac3,flac,opus", _protocol: "hls",
				                                          context: .streaming, maxAudioChannels: "6", minSegments: 2,
				                                          breakOnNonKeyFrames: true)]
			} else {
				transcodingProfiles = [TranscodingProfile(container: "ts", type: .video, videoCodec: "h264,mpeg4",
				                                          audioCodec: "aac,mp3,wav,eac3,ac3,opus", _protocol: "hls",
				                                          context: .streaming, maxAudioChannels: "6", minSegments: 2,
				                                          breakOnNonKeyFrames: true)]
			}
		}

		// Device supports FLAC?
		if supportsFeature(minimumSupported: .A10X) {
			transcodingProfiles = [TranscodingProfile(container: "ts", type: .video, videoCodec: "hevc,h264,mpeg4",
			                                          audioCodec: "aac,mp3,wav,ac3,eac3,flac,opus", _protocol: "hls",
			                                          context: .streaming, maxAudioChannels: "6", minSegments: 2,
			                                          breakOnNonKeyFrames: true)]
		}

		var codecProfiles: [CodecProfile] = []

		let h264CodecConditions: [ProfileCondition] = [
			ProfileCondition(condition: .notEquals, property: .isAnamorphic, value: "true", isRequired: false),
			ProfileCondition(condition: .equalsAny, property: .videoProfile, value: "high|main|baseline|constrained baseline",
			                 isRequired: false),
			ProfileCondition(condition: .lessThanEqual, property: .videoLevel, value: "80", isRequired: false),
			ProfileCondition(condition: .notEquals, property: .isInterlaced, value: "true", isRequired: false),
		]
		let hevcCodecConditions: [ProfileCondition] = [
			ProfileCondition(condition: .notEquals, property: .isAnamorphic, value: "true", isRequired: false),
			ProfileCondition(condition: .equalsAny, property: .videoProfile, value: "high|main|main 10", isRequired: false),
			ProfileCondition(condition: .lessThanEqual, property: .videoLevel, value: "175", isRequired: false),
			ProfileCondition(condition: .notEquals, property: .isInterlaced, value: "true", isRequired: false),
		]

		codecProfiles.append(CodecProfile(type: .video, applyConditions: h264CodecConditions, codec: "h264"))

		if supportsFeature(minimumSupported: .A9) {
			codecProfiles.append(CodecProfile(type: .video, applyConditions: hevcCodecConditions, codec: "hevc"))
		}

		var subtitleProfiles: [SubtitleProfile] = []

		subtitleProfiles.append(SubtitleProfile(format: "ass", method: .embed))
		subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .embed))
		subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .embed))
		subtitleProfiles.append(SubtitleProfile(format: "sub", method: .embed))
		subtitleProfiles.append(SubtitleProfile(format: "pgssub", method: .embed))

		// These need to be filtered. Most subrips are embedded. I hate subtitles.
		subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "sub", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "vtt", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
		subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))

		let responseProfiles: [ResponseProfile] = [ResponseProfile(container: "m4v", type: .video, mimeType: "video/mp4")]

		let profile = DeviceProfile(maxStreamingBitrate: maxStreamingBitrate, maxStaticBitrate: maxStaticBitrate,
		                            musicStreamingTranscodingBitrate: musicStreamingTranscodingBitrate,
		                            directPlayProfiles: directPlayProfiles, transcodingProfiles: transcodingProfiles, containerProfiles: [],
		                            codecProfiles: codecProfiles, responseProfiles: responseProfiles, subtitleProfiles: subtitleProfiles)

		return profile
	}

	private func supportsFeature(minimumSupported: CPUModel) -> Bool {
		let intValues: [CPUModel: Int] = [
			.A4: 1,
			.A5: 2,
			.A5X: 3,
			.A6: 4,
			.A6X: 5,
			.A7: 6,
			.A7X: 7,
			.A8: 8,
			.A8X: 9,
			.A9: 10,
			.A9X: 11,
			.A10: 12,
			.A10X: 13,
			.A11: 14,
			.A12: 15,
			.A12X: 16,
			.A12Z: 16,
			.A13: 17,
			.A14: 18,
			.M1: 19,
			.A99: 99,
		]
		return intValues[CPUinfo()] ?? 0 >= intValues[minimumSupported] ?? 0
	}

	/**********************************************
	 *  CPUInfo():
	 *     Returns a hardcoded value of the current
	 * devices CPU name.
	 ***********************************************/
	private func CPUinfo() -> CPUModel {

		#if targetEnvironment(simulator)
			let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
		#else

			var systemInfo = utsname()
			uname(&systemInfo)
			let machineMirror = Mirror(reflecting: systemInfo.machine)
			let identifier = machineMirror.children.reduce("") { identifier, element in
				guard let value = element.value as? Int8, value != 0 else { return identifier }
				return identifier + String(UnicodeScalar(UInt8(value)))
			}
		#endif

		switch identifier {
		case "iPod5,1": return .A5
		case "iPod7,1": return .A8
		case "iPod9,1": return .A10
		case "iPhone3,1", "iPhone3,2", "iPhone3,3": return .A4
		case "iPhone4,1": return .A5
		case "iPhone5,1", "iPhone5,2": return .A6
		case "iPhone5,3", "iPhone5,4": return .A6
		case "iPhone6,1", "iPhone6,2": return .A7
		case "iPhone7,2": return .A8
		case "iPhone7,1": return .A8
		case "iPhone8,1": return .A9
		case "iPhone8,2", "iPhone8,4": return .A9
		case "iPhone9,1", "iPhone9,3": return .A10
		case "iPhone9,2", "iPhone9,4": return .A10
		case "iPhone10,1", "iPhone10,4": return .A11
		case "iPhone10,2", "iPhone10,5": return .A11
		case "iPhone10,3", "iPhone10,6": return .A11
		case "iPhone11,2", "iPhone11,6", "iPhone11,8": return .A12
		case "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8": return .A13
		case "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4": return .A14
		case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return .A5
		case "iPad3,1", "iPad3,2", "iPad3,3": return .A5X
		case "iPad3,4", "iPad3,5", "iPad3,6": return .A6X
		case "iPad4,1", "iPad4,2", "iPad4,3": return .A7
		case "iPad5,3", "iPad5,4": return .A8X
		case "iPad6,11", "iPad6,12": return .A9
		case "iPad2,5", "iPad2,6", "iPad2,7": return .A5
		case "iPad4,4", "iPad4,5", "iPad4,6": return .A7
		case "iPad4,7", "iPad4,8", "iPad4,9": return .A7
		case "iPad5,1", "iPad5,2": return .A8
		case "iPad11,1", "iPad11,2": return .A12
		case "iPad6,3", "iPad6,4": return .A9X
		case "iPad6,7", "iPad6,8": return .A9X
		case "iPad7,1", "iPad7,2": return .A10X
		case "iPad7,3", "iPad7,4": return .A10X
		case "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12": return .A10
		case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return .A12X
		case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return .A12X
		case "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12": return .A12Z
		case "iPad11,3", "iPad11,4", "iPad11,6", "iPad11,7": return .A12
		case "iPad13,1", "iPad13,2": return .A14
		case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return .M1
		case "AppleTV5,3": return .A8
		case "AppleTV6,2": return .A10X
		case "AppleTV11,1": return .A12
		case "AudioAccessory1,1": return .A8
		default: return .A99
		}
	}
}
