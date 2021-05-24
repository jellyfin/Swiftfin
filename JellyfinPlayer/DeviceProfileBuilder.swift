//
//  DeviceProfileBuilder.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/23/21.
//

import Foundation
import SwiftyJSON

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
    case A99
}

struct _AVDirectProfile: Codable {
    var Container: String;
    var `Type`: String;
    var AudioCodec: String = "";
    var VideoCodec: String = "";
}

struct _AVTranscodingProfile: Codable {
    var Container: String;
    var `Type`: String;
    var AudioCodec: String = "";
    var VideoCodec: String = "";
    var Context: String = "";
    var `Protocol`: String = "hls";
    var MaxAudioChannels: String = "6";
    var MinSegments: String = "2";
    var BreakOnNonKeyFrames: Bool = true;
}

struct _AVCodecCondition: Codable {
    var Condition: String;
    var Property: String;
    var Value: String;
    var IsRequired: Bool;
}

struct _AVCodecProfile: Codable {
    var `Type`: String;
    var Codec: String = "";
    var Conditions: [_AVCodecCondition] = [];
}

struct _AVSubtitleProfile: Codable {
    var Format: String;
    var Method: String;
}

struct _AVResponseProfile: Codable {
    var `Type`: String;
    var Container: String;
    var MimeType: String;
}

struct DeviceProfile: Codable {
    var MaxStreamingBitrate: Int;
    var MaxStaticBitrate: Int;
    var MusicStreamingTranscodingBitrate: Int;
    var DirectPlayProfiles: [_AVDirectProfile] = [];
    var TranscodingProfiles: [_AVTranscodingProfile] = [];
    var ContainerProfiles: [_AVDirectProfile] = [];
    var CodecProfiles: [_AVCodecProfile] = [];
    var SubtitleProfiles: [_AVSubtitleProfile] = [];
    var ResponseProfiles: [_AVResponseProfile] = [];
}

struct DeviceProfileRoot: Codable {
    var DeviceProfile: DeviceProfile;
}

class DeviceProfileBuilder {
    public func buildProfile() -> DeviceProfileRoot {
        let MaxStreamingBitrate = 120000000;
        let MaxStaticBitrate = 100000000
        let MusicStreamingTranscodingBitrate = 384000;
        
        //Build direct play profiles
            var DirectPlayProfiles: [_AVDirectProfile] = [];
            DirectPlayProfiles = [_AVDirectProfile(Container: "mov,mp4,mkv", Type: "Video", AudioCodec: "aac,mp3,wav", VideoCodec: "h264")]
            
            //Device supports Dolby Digital (AC3, EAC3)
            if(supportsFeature(minimumSupported: .A8X)) {
                if(supportsFeature(minimumSupported: .A10)) {
                    DirectPlayProfiles = [_AVDirectProfile(Container: "mov,mp4,mkv", Type: "Video", AudioCodec: "aac,mp3,wav,ac3,eac3,flac", VideoCodec: "hevc,h264,hev1")] //HEVC/H.264 with Dolby Digital
                } else {
                    DirectPlayProfiles = [_AVDirectProfile(Container: "mov,mp4,mkv", Type: "Video", AudioCodec: "ac3,eac3,aac,mp3,wav", VideoCodec: "h264")] //H.264 with Dolby Digital
                }
            }
            
            //Device supports Dolby Vision?
            if(supportsFeature(minimumSupported: .A10X)) {
                DirectPlayProfiles = [_AVDirectProfile(Container: "mov,mp4,mkv", Type: "Video", AudioCodec: "aac,mp3,wav,ac3,eac3,flac", VideoCodec: "dvhe,dvh1,dva1,dvav,h264,hevc,hev1")] //H.264/HEVC with Dolby Digital - No Atmos - Vision
            }
            
            //Device supports Dolby Atmos?
            if(supportsFeature(minimumSupported: .A12)) {
                DirectPlayProfiles = [_AVDirectProfile(Container: "mov,mp4,mkv", Type: "Video", AudioCodec: "aac,mp3,wav,ac3,eac3,flac,truehd,dts,dca", VideoCodec: "h264,hevc,dvhe,dvh1,dva1,dvav,h264,hevc,hev1")] //H.264/HEVC with Dolby Digital & Atmos - Vision
            }
        
        //Build transcoding profiles
            var TranscodingProfiles: [_AVTranscodingProfile] = [];
            TranscodingProfiles = [_AVTranscodingProfile(Container: "ts", Type: "Video", AudioCodec: "aac,mp3,wav", VideoCodec: "h264", Context: "Streaming", Protocol: "hls", MaxAudioChannels: "6", MinSegments: "2", BreakOnNonKeyFrames: true)]
            
            //Device supports Dolby Digital (AC3, EAC3)
            if(supportsFeature(minimumSupported: .A8X)) {
                if(supportsFeature(minimumSupported: .A10)) {
                    TranscodingProfiles = [_AVTranscodingProfile(Container: "mp4", Type: "Video", AudioCodec: "aac,mp3,wav,eac3,ac3,flac", VideoCodec: "h264,hevc,hev1", Context: "Streaming", Protocol: "hls", MaxAudioChannels: "6", MinSegments: "2", BreakOnNonKeyFrames: true)]
                } else {
                    TranscodingProfiles = [_AVTranscodingProfile(Container: "ts", Type: "Video", AudioCodec: "ac3,eac3,wav,eac3,ac3,flac", VideoCodec: "h264", Context: "Streaming", Protocol: "hls", MaxAudioChannels: "6", MinSegments: "2", BreakOnNonKeyFrames: true)]
                }
            }
            
            //Device supports Dolby Vision?
            if(supportsFeature(minimumSupported: .A10X)) {
                TranscodingProfiles = [_AVTranscodingProfile(Container: "mp4", Type: "Video", AudioCodec: "aac,mp3,wav,ac3,eac3,flac", VideoCodec: "dva1,dvav,dvhe,dvh1,hevc,h264,hev1", Context: "Streaming", Protocol: "hls", MaxAudioChannels: "6", MinSegments: "2", BreakOnNonKeyFrames: true)]
            }
            
            //Device supports Dolby Atmos?
            if(supportsFeature(minimumSupported: .A12)) {
                TranscodingProfiles = [_AVTranscodingProfile(Container: "mp4", Type: "Video", AudioCodec: "aac,mp3,wav,ac3,eac3,flac,dts,truehd,dca", VideoCodec: "dva1,dvav,dvhe,dvh1,hevc,h264,hev1", Context: "Streaming", Protocol: "hls", MaxAudioChannels: "9", MinSegments: "2", BreakOnNonKeyFrames: true)]
            }
        
        var CodecProfiles: [_AVCodecProfile] = []
        
        let h264CodecConditions: [_AVCodecCondition] = [
            _AVCodecCondition(Condition: "NotEquals", Property: "IsAnamorphic", Value: "true", IsRequired: false),
            _AVCodecCondition(Condition: "EqualsAny", Property: "VideoProfile", Value: "high|main|baseline|constrained baseline", IsRequired: false),
            _AVCodecCondition(Condition: "LessThanEqual", Property: "VideoLevel", Value: "60", IsRequired: false),
            _AVCodecCondition(Condition: "NotEquals", Property: "IsInterlaced", Value: "true", IsRequired: false)]
        let hevcCodecConditions: [_AVCodecCondition] = [
            _AVCodecCondition(Condition: "NotEquals", Property: "IsAnamorphic", Value: "true", IsRequired: false),
            _AVCodecCondition(Condition: "EqualsAny", Property: "VideoProfile", Value: "main|main 10", IsRequired: false),
            _AVCodecCondition(Condition: "LessThanEqual", Property: "VideoLevel", Value: "160", IsRequired: false),
            _AVCodecCondition(Condition: "NotEquals", Property: "IsInterlaced", Value: "true", IsRequired: false)]
        
        CodecProfiles.append(_AVCodecProfile(Type: "Video", Codec: "h264", Conditions: h264CodecConditions))
        
        if(supportsFeature(minimumSupported: .A10)) {
            CodecProfiles.append(_AVCodecProfile(Type: "Video", Codec: "hevc", Conditions: hevcCodecConditions))
        }
        
        var SubtitleProfiles: [_AVSubtitleProfile] = []
        SubtitleProfiles.append(_AVSubtitleProfile(Format: "vtt", Method: "External"))
        SubtitleProfiles.append(_AVSubtitleProfile(Format: "ass", Method: "External"))
        SubtitleProfiles.append(_AVSubtitleProfile(Format: "ssa", Method: "External"))
        SubtitleProfiles.append(_AVSubtitleProfile(Format: "pgssub", Method: "Embed"))
        SubtitleProfiles.append(_AVSubtitleProfile(Format: "sub", Method: "Embed"))
        
        let ResponseProfiles: [_AVResponseProfile] = [_AVResponseProfile(Type: "Video", Container: "m4v", MimeType: "video/mp4")]
        
        let DP = DeviceProfile(MaxStreamingBitrate: MaxStreamingBitrate, MaxStaticBitrate: MaxStaticBitrate, MusicStreamingTranscodingBitrate: MusicStreamingTranscodingBitrate, DirectPlayProfiles: DirectPlayProfiles, TranscodingProfiles: TranscodingProfiles, CodecProfiles: CodecProfiles, SubtitleProfiles: SubtitleProfiles, ResponseProfiles: ResponseProfiles)
        
        return DeviceProfileRoot(DeviceProfile: DP)
    }
    
    private func supportsFeature(minimumSupported: CPUModel) -> Bool {
        let intValues: [CPUModel: Int] = [.A4: 1, .A5: 2, .A5X: 3, .A6: 4, .A6X: 5, .A7: 6, .A7X: 7, .A8: 8, .A8X: 9, .A9: 10, .A9X: 11, .A10: 12, .A10X: 13, .A11: 14, .A12: 15, .A12X: 16, .A12Z: 16, .A13: 17, .A14: 18, .A99: 99]
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
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif

        switch identifier {
        case "iPod5,1":                                              return .A5
        case "iPod7,1":                                              return .A8
        case "iPod9,1":                                              return .A10
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":                  return .A4
        case "iPhone4,1":                                            return .A5
        case "iPhone5,1", "iPhone5,2":                               return .A6
        case "iPhone5,3", "iPhone5,4":                               return .A6
        case "iPhone6,1", "iPhone6,2":                               return .A7
        case "iPhone7,2":                                            return .A8
        case "iPhone7,1":                                            return .A8
        case "iPhone8,1":                                            return .A9
        case "iPhone8,2", "iPhone8,4":                               return .A9
        case "iPhone9,1", "iPhone9,3":                               return .A10
        case "iPhone9,2", "iPhone9,4":                               return .A10
        case "iPhone10,1", "iPhone10,4":                             return .A11
        case "iPhone10,2", "iPhone10,5":                             return .A11
        case "iPhone10,3", "iPhone10,6":                             return .A11
        case "iPhone11,2", "iPhone11,6", "iPhone11,8":               return .A12
        case "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8": return .A13
        case "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4": return .A14
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":             return .A5
        case "iPad3,1", "iPad3,2", "iPad3,3":                        return .A5X
        case "iPad3,4", "iPad3,5", "iPad3,6":                        return .A6X
        case "iPad4,1", "iPad4,2", "iPad4,3":                        return .A7
        case "iPad5,3", "iPad5,4":                                   return .A8X
        case "iPad6,11", "iPad6,12":                                 return .A9
        case "iPad2,5", "iPad2,6", "iPad2,7":                        return .A5
        case "iPad4,4", "iPad4,5", "iPad4,6":                        return .A7
        case "iPad4,7", "iPad4,8", "iPad4,9":                        return .A7
        case "iPad5,1", "iPad5,2":                                   return .A8
        case "iPad11,1", "iPad11,2":                                 return .A12
        case "iPad6,3", "iPad6,4":                                   return .A9X
        case "iPad6,7", "iPad6,8":                                   return .A9X
        case "iPad7,1", "iPad7,2":                                   return .A10X
        case "iPad7,3", "iPad7,4":                                   return .A10X
        case "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12":           return .A10
        case "iPad8,1", "iPad8,2" ,"iPad8,3", "iPad8,4":             return .A12X
        case "iPad8,5", "iPad8,6" ,"iPad8,7", "iPad8,8":             return .A12X
        case "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12":          return .A12Z
        case "iPad11,3", "iPad11,4" ,"iPad11,6", "iPad11,7":         return .A12
        case "iPad13,1", "iPad13,2":                                 return .A14
        case "AppleTV5,3":                                           return .A8
        case "AppleTV6,2":                                           return .A10X
        case "AudioAccessory1,1":                                    return .A8
        default:                                                     return .A99
        }
    }
}
