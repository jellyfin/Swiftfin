# Top Shelf extension — setup (owner, in Xcode)

> **Status:** the *code* and the app-side plumbing are in; what remains can only be done in Xcode
> with the owner's Apple Developer account (new target + App Group capability + signing). None of
> this can be done headlessly, which is why it's a guided checklist rather than a committed target.
>
> **What's already done (committed, build-green):**
> - `Shared/Objects/Bruno/BrunoTopShelfCredentials.swift` — the cross-process bridge (App Group
>   `UserDefaults`). Dependency-free so it can compile into both the app and the extension.
> - `UserSession.start()` already calls `BrunoTopShelfCredentials.save(...)` on every sign-in.
>   This is a **no-op until the App Group exists**, so it's harmless today.
> - `BrunoTopShelf/ContentProvider.swift` + `Info.plist` + `BrunoTopShelf.entitlements` — the
>   ready-to-add extension. These files live OUTSIDE every synchronized source group, so they are
>   **not compiled** until you add them to a target (below).

---

## 1. Create the extension target
1. Xcode ▸ **File ▸ New ▸ Target…** ▸ tvOS ▸ **TV Top Shelf Extension**. Name it **BrunoTopShelf**,
   embed in **Swiftfin tvOS**. Let Xcode create it (it'll add a stub `ContentProvider` + Info.plist).
2. **Delete Xcode's generated `ContentProvider.swift` and `Info.plist`** for the new target, then
   **add the prepared ones** from the `BrunoTopShelf/` folder (drag in, target = BrunoTopShelf):
   - `BrunoTopShelf/ContentProvider.swift`
   - `BrunoTopShelf/Info.plist` (set Build Settings ▸ *Info.plist File* to this path)
   - `BrunoTopShelf/BrunoTopShelf.entitlements` (set Build Settings ▸ *Code Signing Entitlements*).
3. **Add the shared bridge to the extension target too:** select
   `Shared/Objects/Bruno/BrunoTopShelfCredentials.swift` ▸ File Inspector ▸ Target Membership ▸
   tick **BrunoTopShelf** (in addition to the app targets).

## 2. App Group (this is the auth bridge)
1. Select the **Swiftfin tvOS** target ▸ Signing & Capabilities ▸ **+ Capability ▸ App Groups** ▸
   add **`group.com.diplomacymusic.bruno`**.
2. Do the same on the **BrunoTopShelf** target — the *same* group id.
3. This id must match `BrunoTopShelfCredentials.appGroupID`. If you change it, change it there too.

> Security note: the prototype stores the access token in the App Group `UserDefaults` for
> simplicity. For a hardening pass, move the token to a **shared keychain access group** (the app
> already declares a keychain group for device sign-in — add the extension to the same group and
> swap the token read/write in `BrunoTopShelfCredentials` to the keychain). Server URL + user id
> can stay in the App Group defaults.

## 3. Signing
- **Automatically manage signing** on the BrunoTopShelf target, same team as the app
  (`XcodeConfig/DevelopmentTeam.xcconfig`). Let Xcode make the provisioning profile. The bundle id
  will be `com.diplomacymusic.bruno.BrunoTopShelf` (app id + `.BrunoTopShelf`).

## 4. Build & verify
- Build the **Swiftfin tvOS** scheme to the Apple TV. Sign in once (so `UserSession.start()` writes
  the credentials). Background the app; the Bruno banner on the tvOS home should now show
  **Continue Watching** + **Recently Added** poster rows. With no session it falls back to the
  static `BRUNO.` top-shelf image.

## 5. Deep links (so tapping a Top Shelf poster opens the item)
The provider emits the app's **existing** deep-link format,
`swiftfin://<serverID>/<userID>/item/<itemID>` (built by `BrunoTopShelfCredentials.itemDeepLink`),
which `Shared/Services/DeepLinkHandler.swift` already parses and routes to `.item(item:)`. The
`swiftfin` URL scheme is already registered (`Swiftfin tvOS/Resources/Info.plist`). So **no new
scheme or parser is needed.** The only thing to confirm: the tvOS app delivers incoming URLs to
`deepLinkHandler` (an `onOpenURL`/`openURLContexts` → `deepLinkHandler.handle(url:)` hop). If that
hop already exists for the app's own deep links, Top Shelf taps work for free; if not, add it once.

## 6. Static fallback image
Keep the existing `BRUNO.` top-shelf image in the asset catalog as the default — tvOS uses it
whenever the extension returns `nil` (no session / no content / fetch failure).
