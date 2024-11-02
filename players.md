# Player Differences

Swiftfin offers two player options: the default Swiftfin player and Native (AVKit). While the Swiftfin team recommends using the Swiftfin player for the best compatibility and feature set, the Native player is also available for specific use cases that may benefit from Apple's native features.

---

## Feature Support

| Feature                 | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **Framerate Matching**  | ❌                                                                                                             | ✅                                                                           |
| **HDR Playback**        | ❌                                                                                                             | ✅ **                                                                        |
| **HDR to SDR Tonemapping** | ✅ *                                                                                                         | 🟡 Limited (MP4 only) **                                                    |
| **Player Controls**     | Speed, Aspect Fill, Subtitle & Audio Track Selection, Customizable UI                                          | Speed, Aspect Fill, No Customizations Available                               |
| **Picture-in-Picture**  | ❌                                                                                                             | ✅                                                                           |
| **TLS Support**         | 1.1, 1.2                                                                                                        | 1.1, 1.2, **1.3**                                                         |

## Notes

- **\*** HDR to SDR Tonemapping on Swiftfin (VLCKit) may have colorspace accuracy variations depending on content and device configuration.
- **\*\*** HDR Playback in Native (AVKit) is limited to DirectPlaying compatible MP4 files and may require Dolby Vision Profiles 5 & 8 for full support.

---

## Audio Support

| Audio Codec             | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **AAC**                 | ✅                                                                                                             | ✅                                                                           |
| **AC3**                 | ✅                                                                                                             | ✅                                                                           |
| **ALAC**                | ✅                                                                                                             | ✅                                                                           |
| **AMR (NB & WB)**       | ✅                                                                                                             | ✅ (NB only)                                                                 |
| **DTS**                 | ✅                                                                                                             | ❌                                                                           |
| **EAC3**                | ✅                                                                                                             | ✅                                                                           |
| **FLAC**                | ✅                                                                                                             | ✅                                                                           |
| **MP1, MP2, MP3**       | ✅                                                                                                             | ✅ (MP3 only)                                                                |
| **Opus**                | ✅                                                                                                             | ❌                                                                           |
| **PCM**                 | ✅                                                                                                             | ✅ Limited support                                                           |
| **Speex**               | ✅                                                                                                             | ❌                                                                           |
| **Vorbis**              | ✅                                                                                                             | ❌                                                                           |
| **WavPack**             | ✅                                                                                                             | ❌                                                                           |
| **WMA (Lossless, Pro)** | ✅                                                                                                             | ❌                                                                           |

---

## Video Support

| Video Codec             | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **AV1**                 | ✅                                                                                                             | ❌                                                                           |
| **H.263**               | ✅                                                                                                             | ❌                                                                           |
| **H.264**               | ✅                                                                                                             | ✅                                                                           |
| **H.265 (HEVC)**        | ✅                                                                                                             | ✅                                                                           |
| **MJPEG**               | ✅                                                                                                             | ❌                                                                           |
| **MPEG1/2/4**           | ✅                                                                                                             | ✅ (MPEG4 only)                                                              |
| **VC1**                 | ✅                                                                                                             | ❌                                                                           |
| **VP9**                 | ✅                                                                                                             | ❌                                                                           |

---

## Subtitle Support

| Subtitle Format         | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **ASS**                 | ✅                                                                                                             | ❌                                                                           |
| **CC_DEC**              | ✅                                                                                                             | ✅                                                                           |
| **DVBSub**              | ✅                                                                                                             | ❌                                                                           |
| **DVDSub**              | ✅                                                                                                             | ❌                                                                           |
| **PGSSub**              | ✅                                                                                                             | ❌                                                                           |
| **SRT**                 | ✅                                                                                                             | ❌                                                                           |
| **SSA**                 | ✅                                                                                                             | ❌                                                                           |
| **Teletext**            | ✅                                                                                                             | ❌                                                                           |
| **TTML**                | ✅                                                                                                             | ✅                                                                           |
| **VTT**                 | ✅                                                                                                             | ✅                                                                           |
| **XSub**                | ✅                                                                                                             | ❌                                                                           |

--- 
