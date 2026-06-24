# Swift / SwiftUI reference index

> Canonical documentation sources for the **swift-xcode-expert** agent. These are authoritative,
> versioned, and maintained by Apple / the Swift project — prefer them over memory for anything
> version-specific (a language rule, an API signature, a concurrency diagnostic, an evolution detail).
> Fetch the relevant page with WebFetch before answering; don't guess from recollection.
>
> All links verified live (HTTP 200) on 2026-06-23. If one 404s, the docs were reorganized — search
> `swift.org` / `developer.apple.com` for the new location and update this file.

## The language

| Topic | URL |
|---|---|
| The Swift Programming Language (book, home) | https://docs.swift.org/swift-book/documentation/the-swift-programming-language/ |
| — Concurrency (async/await, actors, tasks) | https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/ |
| — Macros | https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/ |
| — Language Reference (formal grammar) | https://docs.swift.org/swift-book/documentation/the-swift-programming-language/aboutthelanguagereference/ |
| Swift.org — Concurrency hub (Sendable, isolation, data-race safety) | https://www.swift.org/documentation/concurrency/ |
| Swift 6 Migration Guide (strict concurrency, common errors + fixes) | https://www.swift.org/migration/documentation/migrationguide/ |
| API Design Guidelines (naming, conventions) | https://www.swift.org/documentation/api-design-guidelines/ |
| Swift Evolution proposals (the *why* behind a feature; org is **swiftlang**, not apple) | https://github.com/swiftlang/swift-evolution — accepted proposals in `/proposals` |

## SwiftUI / Apple frameworks

| Topic | URL |
|---|---|
| SwiftUI framework reference | https://developer.apple.com/documentation/swiftui |
| Focus (management, the tvOS focus engine) | https://developer.apple.com/documentation/swiftui/focus |
| `FocusState` property wrapper | https://developer.apple.com/documentation/swiftui/focusstate |
| `focused(_:)` view modifier | https://developer.apple.com/documentation/swiftui/view/focused(_:) |
| `focusSection()` (tvOS focus guidance) | https://developer.apple.com/documentation/swiftui/view/focussection() |
| Observation (`@Observable`, `@Bindable`) | https://developer.apple.com/documentation/Observation |
| Adding user-focusable elements to a tvOS app | https://developer.apple.com/documentation/uikit/focus-based_navigation/adding_user-focusable_elements_to_a_tvos_app |

### High-signal WWDC sessions (concepts, not API dumps)
- The SwiftUI cookbook for focus (WWDC23): https://developer.apple.com/videos/play/wwdc2023/10162/
- Direct and reflect focus in SwiftUI (WWDC21): https://developer.apple.com/videos/play/wwdc2021/10023/
- Build SwiftUI apps for tvOS (WWDC20): https://developer.apple.com/videos/play/wwdc2020/10042/

## How to use this index
1. Identify whether the question is **language** (Swift book / evolution / migration guide) or
   **framework** (Apple SwiftUI docs).
2. WebFetch the specific page and ask it the precise question (e.g. "does `Sendable` conformance
   require…"). Quote what it says; cite the URL.
3. For "why does Swift behave this way / when did this change," go to the Swift Evolution proposal.
4. For a strict-concurrency build error, the **Migration Guide** has the canonical pattern + fix.
