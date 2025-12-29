# ContentGroup Feature Plan

## Gaps to Complete
- Custom content group editing is stubbed: `CustomContentGroupSettingsView` has commented-out group list UI, hard-coded library IDs, and “Add” uses random poster settings instead of user-selected values (`Shared/Objects/LibraryParent/ContentGroup.swift`).
- Custom content groups aren’t wired into navigation/tabs: `ContentGroupShimView` isn’t used, and the custom tab setup is commented out (`Shared/Views/ContentGroupView.swift`, `Shared/Coordinators/Tabs/MainTabView.swift`).
- About section is empty: `AboutItemGroup` renders only a header while all cards are `EmptyView` with commented-out ItemView components (`Shared/Views/ItemContentGroupView/AboutItemGroup.swift`).
- Background refresh path is incomplete: `ContentGroupViewModel.Action.backgroundRefresh` exists, but its handler is commented out while views call `viewModel.background.refresh()` (`Shared/ViewModels/ContentGroupViewModel/ContentGroupViewModel.swift`, `Shared/Views/ContentGroupView.swift`).
- Search “no results” logic is stubbed: `hasNoResults` always returns false, so the UI can’t show empty states accurately (`Shared/ViewModels/SearchViewModel.swift`).
- Item menu content is placeholder: `MenuContentGroup(id: "test")` and permission gate are commented; menu content is likely incomplete (`Shared/Views/ItemContentGroupView/ItemViewHeader.swift`).
- Minor placeholder IDs/diagnostics: `LiveTVChannelsPillGroup` uses "asdf" and several ContentGroup views log state changes unconditionally (`Shared/ViewModels/ContentGroupViewModel/LiveTVGroupProvider.swift`, `Shared/Views/ContentGroupView.swift`, `Shared/Views/ItemContentGroupView/ItemContentGroupView.swift`).

## Plan
- Define the intended custom ContentGroup UX (create/edit/delete groups, choose group types, poster style) and wire entry points into tabs/settings; finish `CustomContentGroupSettingsView` and use `ContentGroupShimView` where needed (`Shared/Objects/LibraryParent/ContentGroup.swift`, `Shared/Coordinators/Tabs/MainTabView.swift`, `Shared/Views/ContentGroupView.swift`).
- Implement About section cards by integrating the existing `ItemView.AboutView.*` components and remove `EmptyView` placeholders (`Shared/Views/ItemContentGroupView/AboutItemGroup.swift`).
- Restore background refresh behavior (implement `_backgroundRefresh` or change the refresh API usage) and ensure refresh doesn’t break group state (`Shared/ViewModels/ContentGroupViewModel/ContentGroupViewModel.swift`, `Shared/Views/ContentGroupView.swift`).
- Fix search empty-state logic by inspecting underlying library view models and update `hasNoResults` accordingly (`Shared/ViewModels/SearchViewModel.swift`).
- Replace placeholder menu groups and restore permission gating so item menus are consistent and real (`Shared/Views/ItemContentGroupView/ItemViewHeader.swift`, `Swiftfin/Extensions/View/Modifiers/NavigationBarMenuButton.swift`).
- Clean up placeholder IDs and debug prints after feature behavior is verified (`Shared/ViewModels/ContentGroupViewModel/LiveTVGroupProvider.swift`, `Shared/Views/ContentGroupView.swift`, `Shared/Views/ItemContentGroupView/ItemContentGroupView.swift`).
