# Player Differences

Swiftfin offers two player options: **Swiftfin** (VLCKit) and **Native** (AVKit). The Swiftfin team recommends using Swiftfin (VLCKit) for optimal compatibility and features, though Native (AVKit) is also available for certain cases that benefit from Apple's native capabilities. All video, audio, and subtitle formats listed are supported for direct playback but may be repackaged based on container support. If transcoding is enabled on your server, any unsupported formats will be converted automatically.

---

## Feature Support

| Feature                 | Swiftfin (VLCKit) | Native (AVKit) |
|-------------------------|-------------------|----------------|
| **Framerate Matching**  | ❌                | ✅             |
| **HDR to SDR Tonemapping** | ✅ [1]         | 🔶 [2] |
| **Player Controls**     | - Speed adjustment<br>- Aspect Fill<br>- Chapter Support<br>- Subtitle Support<br>- Audio Track Selection<br>- Customizable UI | - Speed adjustment<br>- Aspect Fill |
| **Picture-in-Picture**  | ❌                | ✅             |
| **TLS Support**         | 1.1, 1.2 [3]     | 1.1, 1.2, 1.3 |
| **[Airplay Audio Output](https://support.apple.com/en-us/102357)** | 🔶 [4] | ✅ |

**Notes**

[1] HDR to SDR Tonemapping on Swiftfin (VLCKit) may have colorspace accuracy variations depending on content and device configuration.

[2] In Native (AVKit), HDR to SDR Tonemapping requires Direct Playing compatible MP4 files and may require Dolby Vision Profiles 5 & 8 for full support.

[3] Swiftfin (VLCKit) does not support TLS 1.3.

[4] Swiftfin (VLCKit) has a [known bug that results in a significant audio delay](https://code.videolan.org/videolan/VLCKit/-/issues/544).

---

## Container Support

| Container | Swiftfin (VLCKit) | Native (AVKit) |
|-----------|-------------------|----------------|
| **AVI**   | ✅                | 🔶 [1]         |
| **FLV**   | ✅                | ❌             |
| **M4V**   | ✅                | ✅             |
| **MKV**   | ✅                | ❌             |
| **MOV**   | ✅                | ✅             |
| **MP4**   | ✅                | ✅             |
| **MPEG-TS** | ✅              | 🔶 [2]         |
| **TS**    | ✅                | 🔶 [3]         |
| **3G2**   | ✅                | ✅             |
| **3GP**   | ✅                | ✅             |
| **WebM**  | ✅                | ❌             |

**Notes**

[1] AVI has limited support in Native (AVKit).

[2] MPEG-TS has limited support in Native (AVKit).

[3] TS has limited support in Native (AVKit).

- Unsupported containers will require transcoding or remuxing to play.

---

## Audio Support

| Audio Codec   | Swiftfin (VLCKit) | Native (AVKit) |
|---------------|-------------------|----------------|
| **AAC**       | ✅                | ✅             |
| **AC3**       | ✅                | ✅             |
| **ALAC**      | ✅                | ✅             |
| **AMR NB**    | ✅                | ✅             |
| **AMR WB**    | ✅                | ❌             |
| **DTS**       | ✅                | ❌             |
| **DTS-HD**    | ❌                | ❌             |
| **EAC3**      | ✅                | ✅             |
| **FLAC**      | ✅                | ✅             |
| **MP1**       | ✅                | ❌             |
| **MP2**       | ✅                | ❌             |
| **MP3**       | ✅                | ✅             |
| **MLP**       | ❌                | ❌             |
| **Nellymoser**| ✅                | ❌             |
| **Opus**      | ✅                | ❌             |
| **PCM**       | ✅                | 🔶 [1]         |
| **Speex**     | ✅                | ❌             |
| **TrueHD**    | ❌                | ❌             |
| **Vorbis**    | ✅                | ❌             |
| **WavPack**   | ✅                | ❌             |
| **WMA**       | ✅                | ❌             |
| **WMA Lossless**| ✅              | ❌             |
| **WMA Pro**   | ✅                | ❌             |

**Notes**

[1] PCM has limited support in Native (AVKit).

- Audio track selection is not currently supported in Native (AVKit) due to issues with HLS file incompatibilities.

---

## Video Support

| Video Codec | Swiftfin (VLCKit) | Native (AVKit) |
|------------------------------------------------------------------------------------------------|-------------------|----------------|
| [H.261](https://en.wikipedia.org/wiki/H.261)                                                   | ✅                | ✅             |
| [MPEG-4 Part 2/SP](https://en.wikipedia.org/wiki/DivX)                                         | ✅                | 🔶 [1]         |
| [MPEG-4 Part 2/ASP](https://en.wikipedia.org/wiki/MPEG-4_Part_2#Advanced_Simple_Profile_(ASP)) | ✅                | 🔶 [1]         |
| [H.264 8Bit](https://caniuse.com/#feat=mpeg4)                                                  | ✅                | ✅             |
| [H.264 10Bit](https://caniuse.com/#feat=mpeg4)                                                 | ✅                | ✅             |
| [H.265 8Bit](https://caniuse.com/#feat=hevc)                                                   | ✅                | 🔶 [2]         |
| [H.265 10Bit](https://caniuse.com/#feat=hevc)                                                  | ✅                | 🔶 [2]         |
| [VP9](https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Video_codecs#VP9)             | ✅                | ❌             |
| [AV1](https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Video_codecs#AV1)             | ✅                | 🔶 [3]         |

**Notes**

[1] MPEG-4 Part 2 support may vary depending on encoding parameters and iOS version.

[2] HEVC decoding is supported on Apple devices with the A8X chip or newer and at least iOS 14. HEVC is only supported in MP4, M4V, and MOV containers.

[3] AV1 is disabled by default but can be enabled for Native (AVKit) using Custom Device Profiles. Enabling AV1 may result in a poor experience for SOCs prior to A17. AV1 is enabled by default for Swiftfin (VLCKit).

- Unsupported video formats will require transcoding or remuxing to play.

---

## Subtitle Support

| Subtitle Format | Swiftfin (VLCKit) | Native (AVKit) |
|----------------|-------------------|----------------|
| **ASS**        | ✅                | ❌             |
| **CC_DEC**     | ✅                | ✅             |
| **DVBSub**     | ✅                | 🔶 [1]         |
| **DVDSub**     | ✅                | 🔶 [1]         |
| **PGSSub**     | ✅                | 🔶 [1]         |
| **SRT**        | ✅                | ❌             |
| **SSA**        | ✅                | ❌             |
| **Teletext**   | ✅                | ❌             |
| **TTML**       | ✅                | ✅             |
| **VTT**        | ✅                | ✅             |
| **XSub**       | ✅                | 🔶 [1]         |

**Notes**

[1] Subtitle format require server-side encoding for Native (AVKit) playback.

- Subtitle track selection is not currently supported in Native (AVKit) due to issues with HLS file incompatibilities.

---

## HDR Support

| Format | Swiftfin (VLCKit) | Native (AVKit) |
|--------|-------------------|----------------|
| **Dolby Vision Profile 5** | ❌             | ✅             |
| **Dolby Vision Profile 8** | ❌             | 🔶 [1]         |
| **Dolby Vision Profile 10** | ❌            | 🔶 [2]         |
| **HDR10** | ❌                              | ✅             |
| **HDR10+** | ❌                             | 🔶 [3]         |
| **HLG** | ❌                                | ❌             |

**Notes**

[1] Dolby Vision Profile 8 support is limited to compatible devices only.

[2] Dolby Vision Profile 10 requires AV1 to be enabled.

[3] HDR10+ support is limited to certain devices, such as the Apple TV 4K (3rd Generation) and recent iPhones and iPads with compatible hardware.

- HLG (Hybrid Log-Gamma) support in Native (AVKit) is limited and not currently supported in Swiftin.
- Swiftfin (VLCKit) does not support HDR playback natively. HDR content may play back without the intended high dynamic range effect.

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

| Feature | Swiftfin (VLCKit) | Native (AVKit) | Notes |
|-------------|-------------------|----------------|----------------|
| **External Display Support** | 🔶        | ✅        | Swiftfin Player can only be mirrored. As a result, the player will retain the source device dimensions. |
| **Energy Consumption** | 🔶        | ✅        | Swiftfin Player will use a software decoder if the media cannot be handled by iOS natively. This results in higher power consumption. |

---
