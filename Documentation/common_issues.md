# Common Issues

This document contains common Swiftfin issues, troubleshooting steps, and resolutions for items that come up frequently.

If your issue isn't here, please check our [existing issues](https://github.com/jellyfin/Swiftfin/issues) before opening a new one. For issues or questions about playback, see the [Players Documentation](players.md). For library support, see [Libraries Documentation](libraries.md).

---

## Before You Report

These four steps resolve many common issues or help narrow down unique issues from known ones:

| Step | Why |
|------|-----|
| **1. Update Swiftfin** | We are only able to support the current release which may already have a code fix for the issue you are experiencing. If you see a closed issue for your problem, but it's still not resolved on the latest release, please try using our [TestFlight](https://testflight.apple.com/join/SqNPfdxq) before reporting a new issue. |
| **2. Switch the player** <br>*Settings > Video Player > Video Player Type* | Each player is based on a different playback engine. Confirming which player(s) has an issue helps narrow the troubleshooting steps. |
| **3. Connect by direct `IP:port`** | If this works and your domain doesn't, the problem is your reverse proxy or network. |
| **4. Check the logs** <br>*Login Issues: Settings (Gear Icon) > Advanced > Logs* <br>*Other Issues: Settings > Logs* | These logs show network traffic and logs for Swiftfin. Identifying the failing decodes or packets that exist can help resolve network/proxy issues. |

---

## Playback

### Nothing Plays, but Browsing Works

Your library, posters, and metadata all load. Pressing play gives a black screen or a spinner. This issue is commonly caused by one of the following:

**Your reverse proxy is TLS 1.3 only.** VLCKit only supports TLS **1.1 and 1.2**, so media playback fails while everything else works. NGINX has included 1.3 by default since 1.23.4, so this can appear after a update. Enable 1.2 alongside 1.3 (having both is fine), VLCKit will fall back to using the supported version. This is a VLC limitation and is documented in the [Players Documentation](players.md).

**You entered `http` for an `https` server.** You can sign in and browse everything, but nothing plays. Swiftfin attempts to resolve this at login, but HSTS can often mask the issue. HSTS and redirects hide this, since some requests follow the redirect but media requests do not. Re-add the server with the correct scheme.

If neither applies, please test on a direct `IP:port` connection before reporting.

### HDR or Dolby Vision Looks Wrong

Purple casts, washed out color, or no tone mapping at all. Both players handle HDR differently and neither is perfect:

- **Swiftfin (VLCKit)** tone maps, but colorspace accuracy varies with content and device.
- **Native (AVPlayer)** needs Direct Play compatible MP4, and often Dolby Vision Profile 5 or 8.

Start by performing the tone mapping from Jellyfin Server and see if this resolves your issue. These settings can be enabled from:

*Settings > Video Player > Playback Quality > HDR > Force Dolby Vision to Transcode*
*Settings > Video Player > Playback Quality > HDR > Force HDR to Transcode*

Please see the notes in the [Players Documentation](players.md) before reporting, and include your file's media info from Jellyfin Web.

### Audio Out of Sync over AirPlay Speakers or HomePods

A [known VLCKit bug](https://code.videolan.org/videolan/VLCKit/-/issues/544) and tracked on Swiftfin [here](https://github.com/jellyfin/Swiftfin/issues/937). This item cannot be resolved by Swiftfin and requires either a patch from VLC or a change to another provider. As a workaround, please use the Native player for this output. 

---

## Connection

### No Local Servers Found

Automatic discovery uses UDP broadcast on port `7359`, which Apple restricts on physical devices. **Please enter your server address manually.** Also confirm **Local Network** permission is enabled in iOS Settings > Swiftfin — iOS sometimes never prompts for it, and it defaults off.

### "The Internet Connection Appears to Be Offline"

Swiftfin can't reach the server but a browser on the same device can. Two causes:

- **Local Network permission is off.** Enable it in iOS Settings > Swiftfin.
- **Stale iOS network cache**, usually after changing networks or during server maintenance. Restarting the device is the only reliable fix we've found.

### "The Data Couldn't Be Read Because It Isn't in the Correct Format"

A generic decoding error — it means Jellyfin sent us something we couldn't parse. It's a symptom, not a cause. The usual culprits:

- A **`baseurl`** set on your server that isn't included in the address you entered, so we receive HTML instead of JSON.
- **Server plugins** that change API responses away from what the SDK expects.
- A **server version mismatch** — see [Server Compatibility](#server-compatibility).

*Settings > Advanced > Logs* will show which request failed. That tells you which of these applies.

### Reverse Proxies

Most connection problems that reach us are proxy configuration rather than Swiftfin. Please start from a configuration Jellyfin has tested:

[Caddy](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/caddy) *(recommended by Jellyfin)* · [Nginx](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/nginx) · [Apache](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/apache) · [Traefik](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/traefik) · [HAProxy](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/haproxy)

Beyond a working Jellyfin proxy, Swiftfin needs **TLS 1.2 available**, a certificate from a **trusted CA** *(self signed certificates are rejected)*, and no filtering middleware in the request path — ModSecurity has been confirmed to block us with a `403` while leaving browsers alone.

**We're not able to troubleshoot custom or heavily modified proxy setups.** This isn't a brush off. A proxy has far more failure modes than the client does, and we can't reproduce what we can't see. If your configuration differs from the documented ones, please reproduce the problem on a documented config or a direct `IP:port` connection before reporting. If it only happens on your setup, the [Jellyfin forum or chat rooms](https://jellyfin.org/contact/) have much broader proxy experience than we do.

When you do investigate, please read your **proxy's** logs. Jellyfin never sees a request the proxy rejected first.

---

## Library and Media

### No Media After Signing In

Swiftfin filters by library **collection type**, not by the items inside. A library with a blank or unsupported type disappears entirely — even if it's full of movies. Please set the correct type in Jellyfin.

See [libraries.md](libraries.md) for what we currently support.

### Live TV Missing or Won't Play

Live TV appears only when a **tuner is configured on your server** and the experimental toggle is enabled. Please restart Swiftfin after changing either.

If Live TV works on your LAN but not remotely, that's a known gap — non-transcoded live streams fall back to a direct path that isn't reachable off network. ([#1948](https://github.com/jellyfin/Swiftfin/issues/1948))

### Extras and Special Features Missing

A folder named **`shorts`** breaks extras entirely. The SDK can't decode that extra type, and one such folder suppresses *all* special features for the item — including ones in correctly named folders. Rename it to `extras`.

### tvOS Shows the Wrong Items Under "Movies"

On tvOS, the top level **Movies** and **Shows** sections group by *media type* across your whole server, not by your library named "Movies". Use **Media** to browse by library. This is working as intended, though we recognize it's confusing.

---

## Server Compatibility

Swiftfin is built against a specific Jellyfin SDK generation. A mismatch gives you confusing partial failures — some views work, others return errors — rather than anything clear.

| Swiftfin | Targets Jellyfin |
|----------|------------------|
| 1.5 | 10.11 |
| 1.4 | 10.11 |
| 1.3 | 10.10 |
| 1.0.1 *(tvOS)* | pre-10.9 — **superseded** |

**We only guarantee support for the current stable Jellyfin release.** Running server pre-releases will surface API changes we haven't adopted yet.

> **On tvOS 1.0.1:** that build shipped in March 2023 and was the App Store tvOS version for over two years. It predates our current device profiles, SDK, and player, and it remains our single largest source of reports — failed transcodes, choppy scrolling, missing extras, crashes. **tvOS 1.5 supersedes it.** If you're on 1.0.1, please update before reporting anything.

---

## Known Limitations

These come up constantly and aren't things we can fix on our end.

| Limitation | Notes |
|------------|-------|
| No TLS 1.3 on the Swiftfin player | ❌ VLCKit limitation. Keep TLS 1.2 enabled. |
| No subtitles on Native | ❌ Tracked in [#1892](https://github.com/jellyfin/Swiftfin/issues/1892). |
| No Picture in Picture on Swiftfin player | ❌ VLCKit limitation. Use Native. |
| AirPlay speaker audio delay | ❌ [VLCKit bug](https://code.videolan.org/videolan/VLCKit/-/issues/544). ([#937](https://github.com/jellyfin/Swiftfin/issues/937)) |
| No bitstream audio passthrough | ❌ Apple doesn't expose the API. ([#1563](https://github.com/jellyfin/Swiftfin/issues/1563)) |
| Server discovery on physical devices | 🟡 Apple entitlement restrictions. Enter the address manually. |
| Self signed certificates | ❌ Please use a trusted CA. |
| Offline downloads | 🟡 Long requested, in progress. ([#57](https://github.com/jellyfin/Swiftfin/issues/57)) |
| macOS client | ❌ Out of scope. ([#215](https://github.com/jellyfin/Swiftfin/issues/215)) |
| Chromecast | ❌ We target AirPlay. ([#271](https://github.com/jellyfin/Swiftfin/issues/271)) |

---

## Still Having Trouble?

For **configuration help** — proxies, certificates, transcoding, networking — please start at the [Jellyfin forum or chat rooms](https://jellyfin.org/contact/). Most of these are server side, and there are far more volunteers there than here.

If it **also happens in Jellyfin Web** or another client, it isn't a Swiftfin issue.

If you've found a reproducible bug in Swiftfin, please open an issue and include:

- Swiftfin version and where you installed it from
- Device and OS version
- Jellyfin server version
- Whether it happens on **both players**
- Whether it happens on a **direct `IP:port`** connection
- Logs from *Settings > Advanced > Logs* — please redact your domain, IPs, and API keys
- For playback, the file's media info and whether the server reports Direct Play, Remux, or Transcode
