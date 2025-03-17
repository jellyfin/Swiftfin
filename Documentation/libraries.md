## Library Support

The Jellyfin Team is hard at work making Swiftfin the best Jellyfin client possible. While we strive to support all library types, our primary focus is on delivering the best possible video playback experience for Shows and Movies. 

As a volunteer-driven project, we unfortunately don't always have the resources to focus on every element that we would like to. So, our current priority is to refine and optimize the existing Shows and Movies libraries. Once we believe these core features are in the best possible state, we can begin evaluating support for other library types. However, at this time, there are no immediate plans for expanding playback beyond video content.

Please know that these other library types are not forgotten, and we recognize the importance of additional media support. As we progress, we will update this page to reflect any new developments.

For details on current library support and what is required for future expansion, see the table below.

| Library Type          | Playback | Management | Notes |
|-----------------------|-----------|------------|------------------------------------------------------------------------------------------------------------|
| Shows                | ✅         | ✅         | |
| Collections          | 🟡         | ✅         | Only Shows & Movies in Collections are viewable. |
| Movies               | ✅         | ✅         | |
| Playlists            | 🟡         | ❌         | Not currently supported, but under review in [PR #1428](https://github.com/jellyfin/Swiftfin/pull/1428) for potential release in 1.4. |
| Mixed Libraries      | ❌         | ❌         | Not supported due to their folder-like structure, requiring a different implementation approach. Also in review as a [Meta Jellyfin discussion topic.](https://github.com/jellyfin/jellyfin-meta/discussions/46) |
| Music               | ❌         | ❌         | Not yet supported. Music would need to come after Playlist support as this is a common requirement. Music requires an Artist > Album > Song structure, different from other media. Additionally needs a lightweight, *(potentially native)* iOS player and a dedicated playback manager. |
| Music Videos        | ❌         | ❌         | Not supported yet but will likely be implemented alongside music due to structural similarities. |
| Home Videos & Photos | ❌         | ❌         | Not supported. Viewing photos requires dedicated logic and potentially a photo view package. Current photo viewing packages are most geared towards posters. |
| Books               | ❌         | ❌         | Not supported. Requires a book viewer. Lower priority since book reading is not planned for tvOS so this feature would only be usable for mobile clients. |

