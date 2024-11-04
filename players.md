# Player Differences

Swiftfin offers two player options: the default Swiftfin player and Native (AVKit). The Swiftfin team recommends using the Swiftfin player for optimal compatibility and features, though the Native player is also available for certain cases that benefit from Apple's native capabilities. All video, audio, and subtitle formats listed are supported for direct playback but might be repackaged based on container support. If transcoding is enabled on your server, any unsupported formats will be converted automatically.

---

## Feature Support

| Feature                 | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **Framerate Matching**  | ❌                                                                                                             | ✅                                                                           |
| **HDR to SDR Tonemapping** | ✅ *                                                                                                         | 🟡 Limited (MP4 only) **                                                    |
| **Player Controls**     | - Speed adjustment<br>- Aspect Fill<br>- Chapter Support<br>- Subtitle Support<br>- Audio Track Selection<br>- Customizable UI                  | - Speed adjustment<br>- Aspect Fill                                          |
| **Picture-in-Picture**  | ❌                                                                                                             | ✅                                                                           |
| **TLS Support**         | 1.1, 1.2 ***                                                                                                   | 1.1, 1.2, **1.3**                                                            |
| **[Home Theater Audio](https://support.apple.com/en-us/102357)**  | 🟡 ****                                          | ✅                                                            |

## Notes

**\*** HDR to SDR Tonemapping on Swiftfin (VLCKit) may have colorspace accuracy variations depending on content and device configuration.

**\*\*** In Native (AVKit), HDR playback works regardless of DirectPlay or MP4 container format. However, HDR to SDR Tonemapping requires DirectPlaying compatible MP4 files and may require Dolby Vision Profiles 5 & 8 for full support.

**\*\*\*** Swiftfin (VLCKit) does not support TLS 1.3.

**\*\*\*\*** Swiftfin (VLCKit) has a [known bug that results in a significant audio delay](https://code.videolan.org/videolan/VLCKit/-/issues/544).

---

## Container Support

| Container             | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **AVI**                 | ✅                                                                                                             | 🟡 Limited support                                                                           |
| **FLV**               | ✅                                                                                                             | ❌                                                                           |
| **M4V**               | ✅                                                                                                             | ✅                                                                           |
| **MKV**               | ✅                                                                                                             | ❌                                                                           |
| **MOV**               | ✅                                                                                                             | ✅                                                                           |
| **MP4**               | ✅                                                                                                             | ✅                                                                           |
| **MPEG-TS**               | ✅                                                                                                             | 🟡 Limited support                                                                           |
| **TS**               | ✅                                                                                                             | 🟡 Limited support                                                                           |
| **3G2**        | ✅                                                                                                             | ✅                                                                           |
| **3GP**               | ✅                                                                                                             | ✅                                                                           |
| **WebM**           | ✅                                                                                                             | ❌                                                              |

## Notes

**Unsupported containers will require transcoding or remuxing to play.** 

--- 

## Audio Support

| Audio Codec             | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **AAC**                 | ✅                                                                                                             | ✅                                                                           |
| **AC3**                 | ✅                                                                                                             | ✅                                                                           |
| **ALAC**                | ✅                                                                                                             | ✅                                                                           |
| **AMR NB**       | ✅                                                                                                             | ✅                                                                 |
| **AMR WB**       | ✅                                                                                                             | ❌                                                                 |
| **DTS**                 | ✅                                                                                                             | ❌                                                                           |
| **DTS-HD**                 | ❌                                                                                                             | ❌                                                                           |
| **EAC3**                | ✅                                                                                                             | ✅                                                                           |
| **FLAC**                | ✅                                                                                                             | ✅                                                                           |
| **MP1**       | ✅                                                                                                             | ❌                                                                |
| **MP2**       | ✅                                                                                                             | ❌                                                                |
| **MP3**       | ✅                                                                                                             | ✅                                                                |
| **MLP**       | ❌                                                                                                             | ❌                                                                |
| **Nellymoser**       | ✅                                                                                                             | ❌                                                                |
| **Opus**                | ✅                                                                                                             | ❌                                                                           |
| **PCM**                 | ✅                                                                                                             | 🟡 Limited support                                                           |
| **Speex**               | ✅                                                                                                             | ❌                                                                           |
| **TrueHD**               | ❌                                                                                                             | ❌                                                                           |
| **Vorbis**              | ✅                                                                                                             | ❌                                                                           |
| **WavPack**             | ✅                                                                                                             | ❌                                                                           |
| **WMA** | ✅                                                                                                             | ❌                                                                           |
| **WMA Lossless** | ✅                                                                                                             | ❌                                                                           |
| **WMA Pro** | ✅                                                                                                             | ❌                                                                           |

---

## Video Support

| Video Codec             | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **AV1**                 | ✅                                                                                                             | ❌                                                                           |
| **DV**               | ❌                                                                                                             | ❌                                                                           |
| **Dirac**               | ✅                                                                                                             | ❌                                                                           |
| **FFV1**               | ✅                                                                                                             | ❌                                                                           |
| **FLV1**               | ✅                                                                                                             | ❌                                                                           |
| **H.261**               | ✅                                                                                                             | ❌                                                                           |
| **H.263**               | ✅                                                                                                             | ❌                                                                           |
| **H.264**               | ✅                                                                                                             | ✅                                                                           |
| **H.265 (HEVC)**        | ✅                                                                                                             | ✅                                                                           |
| **MJPEG**               | ✅                                                                                                             | ✅                                                                           |
| **MPEG1**           | ✅                                                                                                             | ❌                                                              |
| **MPEG2**           | ✅                                                                                                             | ❌                                                              |
| **MPEG4**           | ✅                                                                                                             | ✅                                                              |
| **MS MPEG-4 v1**           | ❌                                                                                                             | ❌                                                              |
| **MS MPEG-4 v2**           | ❌                                                                                                             | ❌                                                              |
| **MS MPEG-4 v3**           | ❌                                                                                                             | ❌                                                              |
| **ProRes**           | ✅                                                                                                             | ✅                                                              |
| **Theora**           | ✅                                                                                                             | ❌                                                              |
| **VC1**                 | ✅                                                                                                             | ❌                                                                           |
| **VP9**                 | ✅                                                                                                             | ❌                                                                           |
| **WMV1**           | ✅                                                                                                             | ❌                                                              |
| **WMV2**           | ✅                                                                                                             | ❌                                                              |
| **WMV3**           | ✅                                                                                                             | ❌                                                              |

---

## Subtitle Support

| Subtitle Format         | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **ASS**                 | ✅                                                                                                             | ❌                                                                           |
| **CC_DEC**              | ✅                                                                                                             | 🟡                                                                           |
| **DVBSub**              | ✅                                                                                                             | ❌                                                                           |
| **DVDSub**              | ✅                                                                                                             | ❌                                                                           |
| **PGSSub**              | ✅                                                                                                             | ❌                                                                           |
| **SRT**                 | ✅                                                                                                             | ❌                                                                           |
| **SSA**                 | ✅                                                                                                             | ❌                                                                           |
| **Teletext**            | ✅                                                                                                             | ❌                                                                           |
| **TTML**                | ✅                                                                                                             | 🟡                                                                           |
| **VTT**                 | ✅                                                                                                             | 🟡                                                                           |
| **XSub**                | ✅                                                                                                             | ❌                                                                           |

## Notes

**Subtitles are not currently supported in the Native Player.** 

---

## HDR Support

| Subtitle Format         | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **Dolby Vision Profile 5**              | ❌                                                                                                             | ✅                                                                           |
| **Dolby Vision Profile 8**              | ❌                                                                                                             | 🟡 Compatible devices only                                                                         |
| **Dolby Vision Profile 10**              | ❌                                                                                                             | 🟡 Requires AV1                                                                           |
| **HDR10**                 | ❌                                                                                                             | ✅                                                                           |
| **HDR10+**              | ❌                                                                                                             | 🟡 Limited support                                                                           |
| **HLG**                 | ❌                                                                                                             | ❌                                                                           |

## Notes

- HDR10+ support in Native (AVKit) is limited to certain devices, such as the Apple TV 4K (3rd Generation) and recent iPhones and iPads with compatible hardware.
- HLG (Hybrid Log-Gamma) support in Native (AVKit) is limited and may vary by device and OS version.
- Dolby Vision Profile 10 (used in AV1) is currently not supported by Native (AVKit).
- Swiftfin (VLCKit) does not support HDR playback natively. HDR content may play back without the intended high dynamic range effect.

--- 
