## Library Support

The Jellyfin Team is hard at work making Swiftfin the best Jellyfin client possible. As a volunteer-driven project, we unfortunately don't always have the resources to focus on every element that we would like to. Please know that these other library types are not forgotten, and we recognize the importance of additional media support. As we progress, we will update this page to reflect any new developments.

For details on current library support and what is required for future expansion, see the table below.

| Library Type          | Supported | Notes |
|-----------------------|-----------|------------------------------------------------------------------------------------------------------------|
| Shows                | ✅         |
| Collections          | 🟡         | Only video media in Collections are viewable. |
| Movies               | ✅         | |
| Playlists            | ❌         | Not supported. Under review in [PR #1428](https://github.com/jellyfin/Swiftfin/pull/1428). |
| Mixed      		   | ✅         | This library type is [officially deprecated](https://jellyfin.org/docs/general/server/media/mixed-movies-and-shows) by the Jellyfin server and [may be removed in the future](https://github.com/jellyfin/jellyfin-meta/discussions/46). |
| Music                | ❌         | Not supported. Music would need to come after Playlist support as this is a common requirement. Music requires an Artist > Album > Song structure, different from other media. Additionally needs a lightweight, *(potentially native)* iOS player and a dedicated playback manager. |
| Music Videos         | ✅         | |
| Home Videos          | ✅         | |
| Photos               | ❌         | Not supported. Viewing photos requires dedicated logic and potentially a photo view package. Current photo viewing packages are most geared towards posters. |
| Books                | ❌         | Not supported. Requires a book viewer. Lower priority since book reading is not planned for tvOS so this feature would only be usable for mobile clients. |
