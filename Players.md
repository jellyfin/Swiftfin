Here’s the **GitHub Markdown** for the "Player Differences" documentation, with each section formatted as requested.

---

# Player Differences

This document compares the differences between **Swiftfin (VLCKit)** and **Native (AVKit)** players, covering feature support, audio, video, and subtitle compatibility.

---

## Feature Support

| Feature                 | Swiftfin (VLCKit)                                                                                               | Native (AVKit)                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **Framerate Matching**  | ❌                                                                                                             | ✅                                                                           |
| **HDR Playback**        | ❌                                                                                                             | ✅ **                                                                        |
| **HDR to SDR Tonemapping** | ✅ *                                                                                                         | Limited (MP4 only) **                                                        |
| **Player Controls**     | ✅ Speed, subtitles, audio track selection, autoplay, customizable UI                                          | ✅ Speed, Aspect Fill                                                         |
| **Picture-in-Picture**  | ❌                                                                                                             | ✅                                                                           |
| **TLS Support**         | ✅ TLS 1.1, 1.2                                                                                               | ✅ TLS 1.1, 1.2, 1.3                                                         |

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
| **PCM**                 | ✅ Extensive PCM support                                                                                       | ✅ Limited support                                                           |
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

## Notes

- **\*** HDR to SDR Tonemapping on Swiftfin (VLCKit) may have colorspace accuracy variations depending on content and device configuration.
- **\*\*** HDR Playback in Native (AVKit) is limited to DirectPlaying compatible MP4 files and may require Dolby Vision Profiles 5 & 8 for full support.

--- 

This structured comparison provides insights into feature capabilities, codec compatibility, and player-specific strengths for Swiftfin (VLCKit) and Native (AVKit) within the Jellyfin ecosystem.
