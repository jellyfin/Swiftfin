# Player Differences

Swiftfin offers two player options: **Swiftfin** (VLCKit) and **Native** (AVPlayer). The Swiftfin team recommends using Swiftfin (VLCKit) for optimal compatibility and features, though Native (AVPlayer) is also available for certain cases that benefit from Apple's native capabilities. All video, audio, and subtitle formats listed are supported for direct playback but may be repackaged based on container support. If transcoding is enabled on your server, any unsupported formats will be converted automatically.

---

## Feature Support

| Feature                 | Swiftfin (VLCKit) | Native (AVPlayer) |
|-------------------------|-------------------|----------------|
| **Framerate Matching**  | ❌                | ✅             |
| **HDR to SDR Tonemapping** | ✅ [1]         | 🔶 [2] |
| **Player Controls**     | - Speed adjustment<br>- Aspect Fill<br>- Chapter Support<br>- Subtitle Support<br>- Audio Track Selection<br>- Customizable UI | - Speed adjustment<br>- Aspect Fill |
| **Picture-in-Picture**  | ❌                | ✅             |
| **TLS Support**         | 1.1, 1.2 [3]     | 1.1, 1.2, 1.3 |
| **[Airplay Audio Output](https://support.apple.com/en-us/102357)** | 🔶 [4] | ✅ |

**Notes**

[1] HDR to SDR Tonemapping on Swiftfin (VLCKit) may have colorspace accuracy variations depending on content and device configuration.

[2] In Native (AVPlayer), HDR to SDR Tonemapping requires Direct Playing compatible MP4 files and may require Dolby Vision Profiles 5 & 8 for full support.

[3] Swiftfin (VLCKit) does not support TLS 1.3.

[4] Swiftfin (VLCKit) has a [known bug that results in a significant audio delay](https://code.videolan.org/videolan/VLCKit/-/issues/544).

---

## Container Support

| Container                                                                                      | Swiftfin (VLCKit) | Native (AVPlayer) |
|------------------------------------------------------------------------------------------------|-------------------|-------------------|
| [AVI](https://en.wikipedia.org/wiki/Audio_Video_Interleave)                                    | ✅                | 🔶 [1]            |
| [FLV](https://en.wikipedia.org/wiki/Flash_Video)                                               | ✅                | ❌                |
| [M4V](https://en.wikipedia.org/wiki/M4V)                                                       | ✅                | ✅                |
| [MKV](https://en.wikipedia.org/wiki/Matroska)                                                  | ✅                | ❌                |
| [MOV](https://en.wikipedia.org/wiki/QuickTime_File_Format)                                     | ✅                | ✅                |
| [MP4](https://en.wikipedia.org/wiki/MP4_file_format)                                           | ✅                | ✅                |
| [MPEG-TS](https://en.wikipedia.org/wiki/MPEG_transport_stream)                                 | ✅                | 🔶 [1]            |
| [TS](https://en.wikipedia.org/wiki/MPEG_transport_stream)                                      | ✅                | 🔶 [1]            |
| [3G2](https://en.wikipedia.org/wiki/3GP_and_3G2)                                               | ✅                | ✅                |
| [3GP](https://en.wikipedia.org/wiki/3GP_and_3G2)                                               | ✅                | ✅                |
| [WebM](https://en.wikipedia.org/wiki/WebM)                                                     | ✅                | ❌                |

**Notes:**

- [1] Requires that files conform to very limited codecs and HDR profiles. [See device profiles](https://github.com/jellyfin/Swiftfin/blob/main/Shared/Objects/VideoPlayerType/VideoPlayerType%2BNative.swift) for a full, up-to-date list of requirements.

- Unsupported containers will require transcoding or remuxing to play.

---

## Audio Support

| Audio Codec                                                                                    | Swiftfin (VLCKit) | Native (AVPlayer) |
|------------------------------------------------------------------------------------------------|-------------------|-------------------|
| [AAC](https://en.wikipedia.org/wiki/Advanced_Audio_Coding)                                     | ✅                | ✅                |
| [AC3](https://en.wikipedia.org/wiki/Dolby_Digital)                                             | ✅                | ✅                |
| [ALAC](https://en.wikipedia.org/wiki/Apple_Lossless_Audio_Codec)                               | ✅                | ✅                |
| [AMR NB](https://en.wikipedia.org/wiki/Adaptive_Multi-Rate_audio_codec)                        | ✅                | ✅                |
| [AMR WB](https://en.wikipedia.org/wiki/Adaptive_Multi-Rate_Wideband)                           | ✅                | ❌                |
| [DTS](https://en.wikipedia.org/wiki/DTS_(company)#DTS_Digital_Surround)                        | ✅                | ❌                |
| [DTS-HD](https://en.wikipedia.org/wiki/DTS-HD_Master_Audio)                                    | ❌                | ❌                |
| [EAC3](https://en.wikipedia.org/wiki/Dolby_Digital_Plus)                                       | ✅                | ✅                |
| [FLAC](https://en.wikipedia.org/wiki/FLAC)                                                     | ✅                | ✅                |
| [MP1](https://en.wikipedia.org/wiki/MPEG-1_Audio_Layer_I)                                      | ✅                | ❌                |
| [MP2](https://en.wikipedia.org/wiki/MPEG-1_Audio_Layer_II)                                     | ✅                | ❌                |
| [MP3](https://en.wikipedia.org/wiki/MP3)                                                       | ✅                | ✅                |
| [MLP](https://en.wikipedia.org/wiki/Meridian_Lossless_Packing)                                 | ❌                | ❌                |
| [Nellymoser](https://en.wikipedia.org/wiki/Nellymoser_Asao_Codec)                              | ✅                | ❌                |
| [Opus](https://en.wikipedia.org/wiki/Opus_(audio_format))                                      | ✅                | ❌                |
| [PCM](https://en.wikipedia.org/wiki/Pulse-code_modulation)                                     | ✅                | 🔶 [1]            |
| [Speex](https://en.wikipedia.org/wiki/Speex)                                                   | ✅                | ❌                |
| [TrueHD](https://en.wikipedia.org/wiki/Dolby_TrueHD)                                           | ❌                | ❌                |
| [Vorbis](https://en.wikipedia.org/wiki/Vorbis)                                                 | ✅                | ❌                |
| [WavPack](https://en.wikipedia.org/wiki/WavPack)                                               | ✅                | ❌                |
| [WMA](https://en.wikipedia.org/wiki/Windows_Media_Audio)                                       | ✅                | ❌                |
| [WMA Lossless](https://en.wikipedia.org/wiki/Windows_Media_Audio#WMA_Lossless)                 | ✅                | ❌                |
| [WMA Pro](https://en.wikipedia.org/wiki/Windows_Media_Audio#WMA_Pro)                           | ✅                | ❌                |

**Notes:**

- [1] Limited support for channels and bitrates. Native (AVPlayer) expects this format in a .MOV or .AVI container.

- Audio track selection is not currently supported in Native (AVPlayer) due to issues with HLS file incompatibilities.
- Unsupported codecs will require transcoding to play.

---

## Video Support

| Video Codec                                                                                    | Swiftfin (VLCKit) | Native (AVPlayer) |
|------------------------------------------------------------------------------------------------|-------------------|-------------------|
| [AV1](https://en.wikipedia.org/wiki/AV1)                                                       | 🔶 [1]            | 🔶 [1]            |
| [Dirac](https://en.wikipedia.org/wiki/Dirac_(video_compression_format))                        | ✅                | ❌                |
| [DV](https://en.wikipedia.org/wiki/DV)                                                         | ✅                | ❌                |
| [FFV1](https://en.wikipedia.org/wiki/FFV1)                                                     | ✅                | ❌                |
| [FLV1](https://en.wikipedia.org/wiki/Sorenson_Spark)                                           | ✅                | ❌                |
| [H.261](https://en.wikipedia.org/wiki/H.261)                                                   | ✅                | ❌                |
| [H.263](https://en.wikipedia.org/wiki/H.263)                                                   | ✅                | ❌                |
| [H.264](https://en.wikipedia.org/wiki/Advanced_Video_Coding)                                   | ✅                | ✅                |
| [H.265/HEVC](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding)                       | ✅                | 🔶 [2]            |
| [H.266/VVC](https://en.wikipedia.org/wiki/Versatile_Video_Coding)                              | ❌ [3]            | ❌                |
| [MJPEG](https://en.wikipedia.org/wiki/Motion_JPEG)                                             | ✅                | ✅                |
| [MPEG-1](https://en.wikipedia.org/wiki/MPEG-1)                                                 | ✅                | ❌                |
| [MPEG-2](https://en.wikipedia.org/wiki/MPEG-2)                                                 | ✅                | ❌                |
| [MPEG-4 Part 2](https://en.wikipedia.org/wiki/MPEG-4_Part_2)                                   | ✅                | ✅                |
| [MS-MPEG4v1](https://en.wikipedia.org/wiki/Microsoft_MPEG-4_AVC)                               | ✅                | ❌                |
| [MS-MPEG4v2](https://en.wikipedia.org/wiki/Microsoft_MPEG-4_AVC)                               | ✅                | ❌                |
| [MS-MPEG4v3](https://en.wikipedia.org/wiki/Microsoft_MPEG-4_AVC)                               | ✅                | ❌                |
| [ProRes](https://en.wikipedia.org/wiki/Apple_ProRes)                                           | ✅                | ❌                |
| [Theora](https://en.wikipedia.org/wiki/Theora)                                                 | ✅                | ❌                |
| [VC-1](https://en.wikipedia.org/wiki/VC-1)                                                     | ✅                | ❌                |
| [VP8](https://en.wikipedia.org/wiki/VP8)                                                       | ✅                | ❌                |
| [VP9](https://en.wikipedia.org/wiki/VP9)                                                       | ✅                | ❌                |
| [WMV1](https://en.wikipedia.org/wiki/Windows_Media_Video)                                      | ✅                | ❌                |
| [WMV2](https://en.wikipedia.org/wiki/Windows_Media_Video)                                      | ✅                | ❌                |
| [WMV3](https://en.wikipedia.org/wiki/Windows_Media_Video)                                      | ✅                | ❌                |

**Notes:**

- [1] AV1 requires A17 Pro, M3, or newer for acceptable performance. Older devices that do not report AV1 capabilities have AV1 disabled by default.

- [2] HEVC requires A8X Pro, M1, or newer for acceptable performance. Older devices that do not report AV1 capabilities have AV1 disabled by default.

- [3] VVC has mix reports of support by Swiftfin (VLCKit). Apple does not provide an API to check VVC capabilities so VVC disabled by default.

- Unsupported codecs will require transcoding to play.

---

## Subtitle Support

| Subtitle Format                                                                                | Swiftfin (VLCKit) | Native (AVPlayer) |
|------------------------------------------------------------------------------------------------|-------------------|-------------------|
| [ASS](https://en.wikipedia.org/wiki/SubStation_Alpha#Advanced_SubStation_Alpha)                | ✅                | ❌                |
| [CC_DEC](https://en.wikipedia.org/wiki/Closed_captioning)                                      | ✅                | ✅                |
| [DVBSub](https://en.wikipedia.org/wiki/DVB_subtitles)                                          | ✅                | 🔶 [1]            |
| [DVDSub](https://en.wikipedia.org/wiki/VobSub)                                                 | ✅                | 🔶 [1]            |
| [JacoSub](https://en.wikipedia.org/wiki/JACOsub)                                               | ✅                | ❌                |
| [MOV_Text](https://en.wikipedia.org/wiki/MPEG-4_Part_17)                                       | ✅                | ❌                |
| [MPL2](https://en.wikipedia.org/wiki/MPL2)                                                     | ✅                | ❌                |
| [PGSSub](https://en.wikipedia.org/wiki/Presentation_Graphic_Stream)                            | ✅                | 🔶 [1]            |
| [PJS](https://en.wikipedia.org/wiki/Phoenix_Subtitle)                                          | ✅                | ❌                |
| [RealText](https://en.wikipedia.org/wiki/RealText)                                             | ✅                | ❌                |
| [SAMI](https://en.wikipedia.org/wiki/SAMI)                                                     | ✅                | ❌                |
| [SSA](https://en.wikipedia.org/wiki/SubStation_Alpha)                                          | ✅                | ❌                |
| [SubRip (SRT)](https://en.wikipedia.org/wiki/SubRip)                                           | ✅                | ❌                |
| [SubViewer](https://en.wikipedia.org/wiki/SubViewer)                                           | ✅                | ❌                |
| [SubViewer1](https://en.wikipedia.org/wiki/SubViewer)                                          | ✅                | ❌                |
| [Teletext](https://en.wikipedia.org/wiki/Teletext)                                             | ✅                | ❌                |
| [Text](https://en.wikipedia.org/wiki/Plain_text)                                               | ✅                | ❌                |
| [TTML](https://en.wikipedia.org/wiki/Timed_Text_Markup_Language)                               | ✅                | ✅                |
| [VPlayer](https://en.wikipedia.org/wiki/VPlayer)                                               | ✅                | ❌                |
| [VTT](https://en.wikipedia.org/wiki/WebVTT)                                                    | ✅                | ✅                |
| [XSub](https://en.wikipedia.org/wiki/XSUB)                                                     | ✅                | 🔶 [1]            |

**Notes:**

- [1] Subtitle format requires server-side encoding for Native (AVPlayer) playback.

- Subtitle track selection is not currently supported in Native (AVPlayer) due to issues with HLS file incompatibilities.

---

## HDR Support

| Format                                                                                         | Swiftfin (VLCKit) | Native (AVPlayer) |
|------------------------------------------------------------------------------------------------|-------------------|-------------------|
| [Dolby Vision Profile 5](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                  | ❌                | ✅                |
| [Dolby Vision Profile 7.6](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                | 🔶 [1] [2]        | 🔶 [1] [2]        |
| [Dolby Vision Profile 8.1](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                | 🔶 [1]            | ✅                |
| [Dolby Vision Profile 8.2](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                | 🔶 [1]            | ✅                |
| [Dolby Vision Profile 8.4](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                | 🔶 [1]            | ✅ [3]            |
| [Dolby Vision Profile 10](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)                 | 🔶 [1] [4]        | 🔶 [4]            |
| [HDR10](https://en.wikipedia.org/wiki/HDR10)                                                   | ✅                | ✅                |
| [HDR10+](https://en.wikipedia.org/wiki/HDR10%2B)                                               | 🔶 [1]            | 🔶 [5]            |
| [HLG](https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma)                                  | ✅                | ✅                |

**Notes:**

- [1] Uses fallback layers and ignores dynamic metadata.

- [2] Dolby Vision 7.6 can only be played from MP4. MKV files will need to be remuxed or transcoded to MP4 to play.

- [3] May cause playback issues on [Jellyfin Server 10.11.5 and earlier](https://github.com/jellyfin/jellyfin/pull/15835) when using MKV containers.

- [4] Requires an AV1 compatible device (Apple A16 Bionic or M3 and above) or a custom profile with AV1 enabled.

- [5] HDR10+ support is limited to certain devices, such as the Apple TV 4K (3rd Generation) and recent iPhones and iPads with compatible hardware. Unsupported devices will fallback to HDR10 rendering, ignoring dynamic metadata.

- Unsupported video ranges will require tone mapping to play.

--- 

### Track Selection

Swiftfin track selection is limited by compatibility with each player. In testing, as of Swiftfin 1.3, the following interactions have been tested.

✅ Working correctly </br>
🔶 Partially working with limitations </br>
❌ Not working

## Swiftfin Player

| File Configuration                                       | DirectPlay | Transcode | Notes |
|---------------------------------------------------------|------------|-----------|------------------------------------------------|
| Internal Audio                                          | ✅         | ✅        |                                                |
| Internal Audio + Internal Subtitles                    | ✅         | 🔶        | - Subtitles do not work if Non-External *(DVDSUB)* |
| Internal Audio + External Subtitles                    | ✅         | ✅        |                                                |
| Internal Audio + Internal Subtitles + External Subtitles | ✅         | 🔶        | - Subtitles do not work if Non-External *(DVDSUB)* |
| Multiple Internal Audio + Multiple Internal Subtitles  | ✅         | 🔶        | - Subtitles do not work if Non-External *(DVDSUB)* |
| Multiple Internal Audio + Multiple External Subtitles  | ✅         | ✅        |                                                |
| Multiple Internal Audio + Internal Subtitles + External Subtitles | ✅ | 🔶 | - Subtitles do not work if Non-External *(DVDSUB)* |
| External Audio + Internal Audio + External Subtitles   | ✅         | ✅        | - Cannot play external audio track if transcoding is required </br> - Subtitles do not work if Non-External *(DVDSUB)* |
| External Audio + Internal Audio + Internal Subtitles   | ✅         | ✅        | - Cannot play external audio track if transcoding is required </br> - Subtitles do not work if Non-External *(DVDSUB)* |
| External Audio + Internal Audio + Internal Subtitles + External Subtitles | ✅ | ✅ | - Cannot play external audio track if transcoding is required </br> - Subtitles do not work if Non-External *(DVDSUB)* |

## Native Player

| File Configuration                                      | DirectPlay | Transcode | Notes |
|--------------------------------------------------------|------------|-----------|------------------------------------------------|
| Internal Audio                                         | ✅         | ✅        |                                                |
| Internal Audio + Internal Subtitles                   | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| Internal Audio + External Subtitles                   | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| Internal Audio + Internal Subtitles + External Subtitles | 🔶      | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| Multiple Internal Audio + Multiple Internal Subtitles | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| Multiple Internal Audio + Multiple External Subtitles | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| Multiple Internal Audio + Internal Subtitles + External Subtitles | 🔶 | ❌ | - The default audio track will played </br> - subtitles cannot be selected. |
| External Audio + Internal Audio + External Subtitles  | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| External Audio + Internal Audio + Internal Subtitles  | 🔶         | ❌        | - The default audio track will played </br> - subtitles cannot be selected. |
| External Audio + Internal Audio + Internal Subtitles + External Subtitles | 🔶 | ❌ | - The default audio track will played </br> - subtitles cannot be selected. |

--- 

### Miscellaneous

| Feature | Swiftfin (VLCKit) | Native (AVPlayer) | Notes |
|-------------|-------------------|----------------|----------------|
| **External Display Support** | 🔶        | ✅        | Swiftfin Player can only be mirrored. As a result, the player will retain the source device dimensions. |
| **Energy Consumption** | 🔶        | ✅        | Swiftfin Player will use a software decoder if the media cannot be handled by iOS natively. This results in higher power consumption. |

---
