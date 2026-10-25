# Player Differences

Swiftfin offers two player engines: **MPV** and **AVPlayer**. MPV is the default and is recommended for the broadest compatibility.

- Formats listed below are supported for direct playback but may be repackaged based on container.
- Some popular/modern formats are tracked below but an engine's device profile may define more formats. If your media cannot play and isn't listed below, either check the device profile or transcode.
- If transcoding is enabled on your server, any unsupported formats will be converted automatically.
- Your device's hardware and your **Playback Quality** settings also affect what is directly played.

---

## Feature Support

| Feature                   | MPV   | AVPlayer |
| ------------------------- | ----- | -------- |
| Audio Track Selection     | ✅     | ✅        |
| Subtitle Track Selection  | ✅     | ✅        |
| Secondary Subtitle        | ✅     | ❌        |
| Audio & Subtitle Offset   | ✅     | ❌        |
| External Audio Tracks     | ❌     | ❌        |
| Speed Adjustment          | ✅     | ✅        |
| Aspect Fill               | ✅     | ✅        |
| Chapters & Trickplay      | ✅     | ✅        |
| Framerate Matching (tvOS) | ❌     | ✅        |
| HDR to SDR Tone Mapping   | ✅ [1] | ✅ [1]    |
| Picture-in-Picture (iOS)  | ✅     | ✅        |
| AirPlay Video             | ❌ [2] | ✅        |
| Energy Consumption        | 🔶 [3] | ✅        |

**Notes:**

- [1] Tone mapping is performed by your Jellyfin server when a source can't be presented on your device, or when forced with **Force HDR to Transcode** or **Force Dolby Vision to Transcode**.
- [2] MPV can be used with system screen mirroring, but does not hand video off to AirPlay receivers.
- [3] MPV uses software decoding for formats your device can't decode in hardware (for example VC-1 or VP9), which uses more power.

---

## Container Support

| Container                                                      | MPV | AVPlayer |
| -------------------------------------------------------------- | --- | -------- |
| [MKV](https://en.wikipedia.org/wiki/Matroska)                  | ✅   | ❌        |
| [MOV](https://en.wikipedia.org/wiki/QuickTime_File_Format)     | ✅   | ✅        |
| [MP4](https://en.wikipedia.org/wiki/MP4_file_format)           | ✅   | ✅        |
| [MPEG-TS](https://en.wikipedia.org/wiki/MPEG_transport_stream) | ✅   | ❌        |
| [WebM](https://en.wikipedia.org/wiki/WebM)                     | ✅   | ❌        |

**Notes:**

- Unsupported containers will require transcoding or remuxing to play.

---

## Audio Support

| Audio Codec                                                             | MPV | AVPlayer |
| ----------------------------------------------------------------------- | --- | -------- |
| [AAC](https://en.wikipedia.org/wiki/Advanced_Audio_Coding)              | ✅   | ✅        |
| [AC3](https://en.wikipedia.org/wiki/Dolby_Digital)                      | ✅   | ✅        |
| [ALAC](https://en.wikipedia.org/wiki/Apple_Lossless_Audio_Codec)        | ✅   | ✅        |
| [DTS](https://en.wikipedia.org/wiki/DTS_(company)#DTS_Digital_Surround) | ✅   | ❌        |
| [DTS-HD](https://en.wikipedia.org/wiki/DTS-HD_Master_Audio)             | ✅   | ❌        |
| [EAC3](https://en.wikipedia.org/wiki/Dolby_Digital_Plus)                | ✅   | ✅        |
| [FLAC](https://en.wikipedia.org/wiki/FLAC)                              | ✅   | ✅        |
| [MP3](https://en.wikipedia.org/wiki/MP3)                                | ✅   | 🔶 [1]    |
| [Opus](https://en.wikipedia.org/wiki/Opus_(audio_format))               | ✅   | ❌        |
| [PCM](https://en.wikipedia.org/wiki/Pulse-code_modulation)              | ✅   | 🔶 [1]    |
| [TrueHD](https://en.wikipedia.org/wiki/Dolby_TrueHD)                    | ✅   | ❌        |

**Notes:**

- [1] AVPlayer has limited support for these formats. MP3 and PCM are supported in MOV files (PCM is also supported in AVI, WAV, AIFF, and CAF), and MP3 is supported as a standalone audio file.
- Unsupported codecs will require transcoding to play.

---

## Video Support

| Video Codec                                                              | MPV   | AVPlayer |
| ------------------------------------------------------------------------ | ----- | -------- |
| [AV1](https://en.wikipedia.org/wiki/AV1)                                 | 🔶 [1] | 🔶 [1]    |
| [H.264/AVC](https://en.wikipedia.org/wiki/Advanced_Video_Coding)         | ✅ [2] | ✅        |
| [H.265/HEVC](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding) | ✅     | ✅ [3]    |
| [MPEG-2](https://en.wikipedia.org/wiki/MPEG-2)                           | ✅     | ❌        |
| [VP9](https://en.wikipedia.org/wiki/VP9)                                 | ✅     | 🔶 [4]    |

**Notes:**

- [1] AV1 requires A17 Pro, M3, or newer for acceptable performance. Older devices that do not report AV1 capabilities have AV1 disabled by default.
- [2] MPV only direct plays SDR H.264 (Baseline, Main, High, and High 10). Anamorphic video is transcoded.
- [3] HEVC requires A8X Pro, M1, or newer for acceptable performance. Older devices that do not report HEVC capabilities have HEVC disabled by default. All devices supported by Swiftfin should have HEVC available.
- [4] Apple devices do not currently report hardware VP9 decoding, so AVPlayer will normally transcode VP9.
- Unsupported codecs will require transcoding to play.

---

## Subtitle Support

| Subtitle Format                                                                 | MPV   | AVPlayer |
| ------------------------------------------------------------------------------- | ----- | -------- |
| [ASS](https://en.wikipedia.org/wiki/SubStation_Alpha#Advanced_SubStation_Alpha) | ✅     | 🔶 [3]    |
| [CC_DEC](https://en.wikipedia.org/wiki/Closed_captioning)                       | ✅     | ✅        |
| [DVBSub](https://en.wikipedia.org/wiki/DVB_subtitles)                           | ✅ [1] | 🔶 [2]    |
| [DVDSub](https://en.wikipedia.org/wiki/VobSub)                                  | ✅ [1] | 🔶 [2]    |
| [MOV_Text](https://en.wikipedia.org/wiki/MPEG-4_Part_17)                        | ✅     | 🔶 [3]    |
| [PGSSub](https://en.wikipedia.org/wiki/Presentation_Graphic_Stream)             | ✅ [1] | 🔶 [2]    |
| [SubRip (SRT)](https://en.wikipedia.org/wiki/SubRip)                            | ✅     | 🔶 [3]    |
| [TTML](https://en.wikipedia.org/wiki/Timed_Text_Markup_Language)                | 🔶 [4] | ✅        |
| [VTT](https://en.wikipedia.org/wiki/WebVTT)                                     | ✅     | ✅        |

**Notes:**

- [1] Bitmap subtitle formats can be played if embedded in the container (MKV) but require server-side burn-in when the source is an external file.
- [2] Bitmap subtitle formats require server-side burn-in for playback.
- [3] Text subtitles are converted by the server and delivered as WebVTT inside the HLS stream. This requires the server to remux or transcode the video, and styling (such as ASS effects) is not preserved.
- [4] Text subtitles that MPV cannot load directly are converted to SubRip by the server.
- You can force subtitle burn-in from the video player settings (**Force Subtitle Burn-In**).

---

## HDR and DV Support

| Format                                                                          | MPV   | AVPlayer |
| ------------------------------------------------------------------------------- | ----- | -------- |
| [Dolby Vision Profile 5](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles)   | ✅ [1] | ✅        |
| [Dolby Vision Profile 7.6](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles) | ❌ [2] | 🔶 [3]    |
| [Dolby Vision Profile 8.1](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles) | ✅ [1] | ✅        |
| [Dolby Vision Profile 8.4](https://en.wikipedia.org/wiki/Dolby_Vision#Profiles) | ✅ [1] | ✅        |
| [HDR10](https://en.wikipedia.org/wiki/HDR10)                                    | ✅     | ✅        |
| [HDR10+](https://en.wikipedia.org/wiki/HDR10%2B)                                | 🔶 [4] | 🔶 [4]    |
| [HLG](https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma)                   | ✅     | ✅        |

**Notes:**

- [1] MPV presents Dolby Vision natively on supported hardware for HEVC Profile 5 and Profile 8 content. Subtitles are limited in this mode: text subtitles are shown by Swiftfin's own overlay, while image-based or styled (ASS) subtitles require server-side burn-in.
- [2] MPV does not advertise these profiles as directly playable, so the server will tone map them.
- [3] AVPlayer plays the base layer only and ignores the enhancement layer.
- [4] HDR10+ plays as HDR10 and dynamic metadata is ignored.
- Actual HDR output depends on your display. Unsupported video ranges will require tone mapping.
- If HDR or Dolby Vision looks wrong, try **Force HDR to Transcode** or **Force Dolby Vision to Transcode**.

---

## Captions & Accessibility

Both players follow your system caption and audible-media preferences (system *Settings > Accessibility*):

- **Captions** can be set to *Always On*, *Forced Only*, or *Automatic*. Swiftfin prefers captions in your system's preferred languages, favoring SDH captions when available.
- **Audio Descriptions** are selected automatically when a track is clearly labeled as described audio.
- **Caption style** (font, size, and color) comes from your system caption styles.
- **Show on Skip Back** follows the system setting. When captions are off, skipping or scrubbing back briefly turns captions on so you can catch missed dialogue, then turns them off again. This works with text subtitles in MPV and with captions AVPlayer can switch locally. It is unavailable if your OS version doesn't provide the setting.

---

For playback problems, include the selected engine, your device, and the media information from Jellyfin Web. See [Common Issues](common_issues.md) for troubleshooting.
